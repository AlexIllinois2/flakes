{
  inputs = {
    # 钉在与系统 NixOS 相同的 nixpkgs 修订上（26.05, glibc 2.42），
    # 避免 devshell(unstable/glibc 2.44) 与系统(26.05/2.42) 混代导致
    # 编译产物无法在本机运行、linuxdeploy 打包 AppImage 时捡错库
    nixpkgs.url = "github:NixOS/nixpkgs/94c3211b0ee8ba969a3f12eb4aff8ba0f72971dd";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, flake-utils, rust-overlay }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ rust-overlay.overlays.default ];
          config = { allowUnfree = true; android_sdk.accept_license = true; };
        };

        rustDesktop = pkgs.rust-bin.stable.latest.default.override {
          extensions = [ "rust-src" "rustfmt" "clippy" "rust-analyzer" ];
        };
        rustAndroid = rustDesktop.override {
          targets = [
            "aarch64-linux-android"
            "armv7-linux-androideabi"
            "i686-linux-android"
            "x86_64-linux-android"
          ];
        };

        androidSdk = (pkgs.androidenv.composeAndroidPackages {
          cmdLineToolsVersion = "8.0";
          platformToolsVersion = "37.0.0";
          buildToolsVersions = [ "35.0.0" ];
          platformVersions = [ "35" ];
          includeNDK = true;
          ndkVersions = [ "29.0.14206865" ];
          abiVersions = [ "arm64-v8a" "armeabi-v7a" "x86_64" ];
        }).androidsdk;

        desktopLibs = with pkgs; [
          gtk3 webkitgtk_4_1 libsoup_3 cairo gdk-pixbuf glib
          dbus openssl_3_5 librsvg xz
        ];

        # linuxdeploy-plugin-gtk 会向拷入 AppDir 的 GTK 模块目录写缓存
        # (immodules.cache 等); nix store 输出一律只读(目录 555), cp -a 原样
        # 保留权限导致写入失败。因此不能放 store 里, 而是在 shellHook 中
        # 于运行时在用户缓存目录生成一份可写的合并库树(见 libClosureSetup)
        gtkLibPkgPaths = pkgs.lib.concatMapStringsSep " " (p: "${pkgs.lib.getLib p}") [
          pkgs.gtk3 pkgs.gdk-pixbuf pkgs.glib pkgs.gobject-introspection
        ];

        # 插件通过 pkgconf 查询路径, NixOS 下需要重定向一批变量到上面的
        # 可写树(LD_GTK_LIBRARY_PATH 由 shellHook 运行时导出), 其余透传
        pkgconfGtkFix = pkgs.writeShellScriptBin "pkgconf" ''
          case "$1 $2" in
            "--variable=schemasdir gio-2.0")
              # 指向运行时可写树中的 schemas 副本: 若直接用 glib.dev 的
              # 只读目录, cp -a 会把 555/444 权限带进 AppDir, 导致 bundler
              # 下次构建 remove_dir_all 清理失败
              echo "$LD_GTK_LIBRARY_PATH/../schemas"; exit 0 ;;
            "--variable=libdir gtk+-3.0")
              echo "$LD_GTK_LIBRARY_PATH"; exit 0 ;;
            "--variable=gdk_pixbuf_binarydir gdk-pixbuf-2.0")
              echo "$LD_GTK_LIBRARY_PATH/gdk-pixbuf-2.0/2.10.0"; exit 0 ;;
            "--variable=gdk_pixbuf_cache_file gdk-pixbuf-2.0")
              echo "$LD_GTK_LIBRARY_PATH/gdk-pixbuf-2.0/2.10.0/loaders.cache"; exit 0 ;;
            "--variable=gdk_pixbuf_moduledir gdk-pixbuf-2.0")
              echo "$LD_GTK_LIBRARY_PATH/gdk-pixbuf-2.0/2.10.0/loaders"; exit 0 ;;
            "--variable=giomoduledir gio-2.0")
              echo "$LD_GTK_LIBRARY_PATH/gio/modules"; exit 0 ;;
            "--variable=typelibdir gobject-introspection-1.0")
              echo "$LD_GTK_LIBRARY_PATH/girepository-1.0"; exit 0 ;;
            # "Copying more libraries" 步骤(libdir gobject/gio/gdk-pixbuf/
            # librsvg/pango) 在 linuxdeploy 插件模式下解析依赖会触发 abort,
            # 且主阶段早已部署过二进制的完整依赖闭包, 该步骤纯属冗余;
            # 指向空目录使其无库可部署, 直接跳过
            "--variable=libdir gobject-2.0" | "--variable=libdir gio-2.0" \
              | "--variable=libdir gdk-pixbuf-2.0" | "--variable=libdir librsvg-2.0" \
              | "--variable=libdir pango" | "--variable=libdir pangocairo" \
              | "--variable=libdir pangoft2")
              echo "$LD_GTK_LIBRARY_PATH/.empty-libs"; exit 0 ;;
          esac
          exec "${pkgs.pkg-config}/bin/pkg-config" "$@"
        '';

        common = with pkgs; [
          nodejs
          pnpm
          rustDesktop
          rust-analyzer
          pkg-config
          gobject-introspection
          pkgconfGtkFix
          gtk3.dev
          gdk-pixbuf.dev
          cargo-tauri
          bacon
        ];

        # desktopLibs 各包 lib 输出的空格分隔路径，供闭包展开使用
        libPkgPaths = pkgs.lib.concatMapStringsSep " " (p: "${pkgs.lib.getLib p}") desktopLibs;

        # linuxdeploy 打 AppImage 时只按 LD_LIBRARY_PATH 逐级解析传递依赖
        # （不会用 rpath），所以必须把 desktopLibs 的完整 nix 闭包注入。
        # 结果按输入内容哈希缓存，重复进 shell 零开销。
        libClosureSetup = ''
          _lib_closure() {
            local key cache dirs
            key=$(printf '%s' "$1" | sha256sum | cut -c1-12)
            cache="''${XDG_CACHE_HOME:-$HOME/.cache}/nix-shell-libpath-$key"
            if [ -s "$cache" ]; then
              cat "$cache"
            else
              dirs=$(nix-store -qR $1 2>/dev/null | while read -r p; do
                [ -d "$p/lib" ] && printf '%s\n' "$p/lib"
              done | paste -sd:)
              printf '%s' "$dirs" > "$cache"
              printf '%s' "$dirs"
            fi
          }
          export LD_LIBRARY_PATH="$(_lib_closure "${libPkgPaths}")"
          # 运行时构建可写 GTK 库树, 供 linuxdeploy-plugin-gtk 拷贝并写缓存
          # (nix store 输出只读, 不能作为带写入的拷贝源)
          _gtkw_key=$(printf '%s' "${gtkLibPkgPaths}" | sha256sum | cut -c1-12)
          _gtkw="''${XDG_CACHE_HOME:-$HOME/.cache}/tauri-gtk-libs-writable-$_gtkw_key"
          if [ ! -d "$_gtkw/lib/gtk-3.0" ] || [ ! -d "$_gtkw/schemas" ]; then
            rm -rf "$_gtkw"
            mkdir -p "$_gtkw/lib"
            for p in ${gtkLibPkgPaths}; do
              [ -d "$p/lib" ] && cp -a "$p/lib/." "$_gtkw/lib/"
              chmod -R u+w "$_gtkw"
            done
            # gio modules 可能不存在, 但插件需要向其中写 giomodule.cache
            mkdir -p "$_gtkw/lib/gio/modules" "$_gtkw/lib/.empty-libs"
            # schemas 同理需要可写副本(源头是只读的 glib.dev)
            cp -a "${pkgs.glib.dev}/share/glib-2.0/schemas" "$_gtkw/schemas"
            chmod -R u+w "$_gtkw"
          fi
          export LD_GTK_LIBRARY_PATH="$_gtkw/lib"
          unset _gtkw _gtkw_key
          unset -f _lib_closure
        '';
      in {
        devShells.default = pkgs.mkShell {
          packages = common ++ desktopLibs;
          shellHook = libClosureSetup;
          XDG_DATA_DIRS =
            "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas:${pkgs.gtk3}/share/gsettings-schemas:$XDG_DATA_DIRS";
        };

        devShells.android = pkgs.mkShell {
          packages = common ++ desktopLibs ++ [
            rustAndroid
            pkgs.cargo-ndk
            pkgs.jdk21
            pkgs.gradle
            androidSdk
          ];
          ANDROID_HOME = "${androidSdk}/libexec/android-sdk";
          ANDROID_SDK_ROOT = "${androidSdk}/libexec/android-sdk";
          ANDROID_NDK_HOME = "${androidSdk}/libexec/android-sdk/ndk/29.0.14206865";
          NDK_HOME = "${androidSdk}/libexec/android-sdk/ndk/29.0.14206865";
          JAVA_HOME = pkgs.jdk21;
          GRADLE_OPTS =
            "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/libexec/android-sdk/build-tools/35.0.0/aapt2";
          shellHook = libClosureSetup;
        };
      });
}
