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

        # 插件会向拷入 AppDir 的 GTK 模块目录写缓存(immodules.cache 等),
        # 但 nix store 源树只读且 cp -a 保留权限, 会导致写入失败;
        # 生成一份可写的合并库树, 作为这些拷贝的源
        gtkWritableLibs = pkgs.runCommand "gtk-libs-writable" { } ''
          mkdir -p $out/lib
          for p in ${pkgs.gtk3} ${pkgs.gdk-pixbuf} ${pkgs.glib} ${pkgs.gobject-introspection}; do
            if [ -d "$p/lib" ]; then
              cp -a "$p/lib/." "$out/lib/"
            fi
          done
          chmod -R u+w $out
        '';

        # linuxdeploy-plugin-gtk 通过 pkgconf 查询各路径; NixOS 下有两处不一致:
        # 1. gio-2.0.pc 的 schemasdir 指向不含 schemas 的 out 输出(实际在 .dev)
        # 2. 各 libdir 指向只读 nix store, 拷贝后无法写缓存
        # 包装 pkgconf 把这些变量重定向到上面的可写库树, 其余透传
        pkgconfGtkFix = pkgs.writeShellScriptBin "pkgconf" ''
          case "$1 $2" in
            "--variable=schemasdir gio-2.0")
              echo "${pkgs.glib.dev}/share/glib-2.0/schemas"; exit 0 ;;
            "--variable=libdir gtk+-3.0" | "--variable=libdir gdk-pixbuf-2.0" \
              | "--variable=libdir gobject-2.0" | "--variable=libdir gio-2.0" \
              | "--variable=libdir pango" | "--variable=libdir pangocairo" \
              | "--variable=libdir pangoft2")
              echo "${gtkWritableLibs}/lib"; exit 0 ;;
            "--variable=giomoduledir gio-2.0")
              echo "${gtkWritableLibs}/lib/gio/modules"; exit 0 ;;
            "--variable=typelibdir gobject-introspection-1.0")
              echo "${gtkWritableLibs}/lib/girepository-1.0"; exit 0 ;;
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
          # linuxdeploy-plugin-gtk (tauri bundler 恒定启用 --plugin gtk) 在 NixOS 上
          # 探测不到 /usr/lib,会以空值调 realpath 直接失败;显式指定 gtk 库目录
          export LD_GTK_LIBRARY_PATH="${gtkWritableLibs}/lib"
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
