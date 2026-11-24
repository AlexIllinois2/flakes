{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
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

        androidSdk = pkgs.androidenv.composeAndroidPackages {
          cmdLineToolsVersion = "8.0";
          platformToolsVersion = "35.0.2";
          buildToolsVersions = [ "35.0.0" ];
          platformVersions = [ "35" ];
          includeNDK = true;
          ndkVersions = [ "29.0.14206865" ];
          abiVersions = [ "arm64-v8a" "armeabi-v7a" "x86_64" ];
        }).androidsdk;

        desktopLibs = with pkgs; [
          gtk3 webkitgtk_4_1 libsoup_3 cairo gdk-pixbuf glib
          dbus openssl_3 librsvg
        ];

        common = with pkgs; [
          nodejs
          nodePackages.pnpm
          rustDesktop
          rust-analyzer
          pkg-config
          cargo-tauri
          bacon
        ];
      in {
        devShells.default = pkgs.mkShell {
          packages = common ++ desktopLibs;
          LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath desktopLibs;
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
          LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath desktopLibs;
        };
      });
}