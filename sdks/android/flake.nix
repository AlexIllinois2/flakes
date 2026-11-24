{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          android_sdk.accept_license = true;
        };
      };
      androidComposition = pkgs.androidenv.composeAndroidPackages {
        platformVersions = [ "34" "35" ];
        buildToolsVersions = [ "34.0.0" "35.0.0" ];
        cmdLineToolsVersion = "latest";
        platformToolsVersion = "latest";
        includeNDK = true;
        ndkVersions = [ "29.0.14206865" ];   # 第一个会软链到 ndk-bundle
        includeEmulator = true;
        includeSystemImages = true;
        abiVersions = [ "arm64-v8a" "x86_64" ];
        systemImageTypes = [ "google_apis" ];
        cmakeVersions = [ "3.22.1" ];
      };
      androidSdk = androidComposition.androidsdk;
    in {
      devShells.${system}.default = pkgs.mkShell {
        packages = [
          pkgs.jdk17
          pkgs.flutter
          pkgs.cargo-ndk
          androidSdk
          androidComposition.platform-tools
          pkgs.pkg-config
          pkgs.clang
        ];
        env = {
          ANDROID_HOME = "${androidSdk}/libexec/android-sdk";
          ANDROID_SDK_ROOT = "${androidSdk}/libexec/android-sdk";
          ANDROID_NDK_HOME = "${androidSdk}/libexec/android-sdk/ndk-bundle";
          ANDROID_NDK_ROOT = "${androidSdk}/libexec/android-sdk/ndk-bundle";
          JAVA_HOME = "${pkgs.jdk17}/lib/openjdk";
        };
        shellHook = ''
          export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
          # 绕过 Gradle 从 maven 拉 aapt2 在 NixOS 上的链接问题
          export GRADLE_OPTS="-Dorg.gradle.project.android.aapt2FromMavenOverride=$ANDROID_HOME/build-tools/35.0.0/aapt2 $GRADLE_OPTS"
        '';
      };
    };
}
