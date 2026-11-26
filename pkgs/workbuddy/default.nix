{ lib
, stdenvNoCC
, fetchurl
, makeWrapper
, makeDesktopItem
, xdg-utils
, glib
, gtk3
, gdk-pixbuf
, at-spi2-core
, cairo
, pango
, nss
, nspr
, cups
, dbus
, expat
, fontconfig
, freetype
, libdrm
, libgbm
, mesa
, libglvnd
, vulkan-loader
, alsa-lib
, libpulseaudio
, zlib
, krb5
, systemd
, libxkbcommon
, libxkbfile
, libxcb
, libX11
, libXcomposite
, libXdamage
, libXext
, libXfixes
, libXrandr
, libXScrnSaver
, libXtst
, libgcrypt
, libsecret
, stdenv
}:

let
  pname = "workbuddy";
  version = "5.11.3.43806934-ecace0f7";

  # 大文件优先用 ~/Downloads 下的同名文件（需 --impure 才能读取本地路径），
  # 没有时再从 GitHub Releases 下载；两者 content hash 相同，store 路径一致。
  fileName = "workbuddy_${version}-3_amd64.tar.gz";
  srcHash = "JkfMtVOV4jQxJRHwfBNZPyLulmih6g1u8h+yPe3mJvc=";

  runtimeLibs = [
    glib
    gtk3
    gdk-pixbuf
    at-spi2-core
    cairo
    pango
    nss
    nspr
    cups
    dbus
    expat
    fontconfig
    freetype
    libdrm
    libgbm
    mesa
    libglvnd
    vulkan-loader
    alsa-lib
    libpulseaudio
    zlib
    krb5
    systemd
    libxkbcommon
    libxkbfile
    libxcb
    libX11
    libXcomposite
    libXdamage
    libXext
    libXfixes
    libXrandr
    libXScrnSaver
    libXtst
    libgcrypt
    libsecret
    stdenv.cc.cc.lib
  ];

  desktopItem = makeDesktopItem {
    name = pname;
    desktopName = "WorkBuddy";
    genericName = "AI Agent";
    comment = "Tencent WorkBuddy AI Agent";
    exec = "workbuddy %U";
    icon = pname;
    terminal = false;
    categories = [ "Development" "Utility" ];
    startupWMClass = "WorkBuddy";
  };
in
stdenvNoCC.mkDerivation {
  inherit pname version;

  # 大文件优先用 $HOME/Downloads 下的同名文件，没有（或 hash 不符）时再从
  # GitHub Releases 下载；两者 content hash 相同，store 路径一致。
  # 不写死用户名：getEnv 只在 --impure 求值下生效；纯求值下读不到本地路径，
  # tryEval 失败后自动走 fetchurl 分支，不影响别人构建。
  src =
    let
      localFile = /. + (builtins.getEnv "HOME") + "/Downloads/" + fileName;
      local = builtins.tryEval (
        builtins.path {
          path = localFile;
          name = fileName;
          recursive = false;
          sha256 = srcHash;
        }
      );
    in
    if local.success then
      local.value
    else
      fetchurl {
        url = "https://github.com/acgq/workbuddy-linux/releases/download/port-v${version}-r3/${fileName}";
        name = fileName;
        hash = "sha256-${srcHash}";
      };

  sourceRoot = "WorkBuddy";

  nativeBuildInputs = [ makeWrapper ];

  dontBuild = true;
  dontStrip = true;
  dontPatchELF = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/opt/workbuddy
    cp -a . $out/opt/workbuddy/

    mkdir -p $out/bin $out/share/applications \
      $out/share/pixmaps $out/share/icons/hicolor/1024x1024/apps

    makeWrapper $out/opt/workbuddy/launch-workbuddy $out/bin/workbuddy \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath runtimeLibs}" \
      --prefix PATH : "${xdg-utils}/bin"

    cat > $out/bin/workbuddy-cli <<EOF
    #!${stdenv.shell}
    export WORKBUDDY_CONFIG_DIR="''${WORKBUDDY_CONFIG_DIR:-$HOME/.workbuddy}"
    unset ELECTRON_RUN_AS_NODE
    exec $out/opt/workbuddy/resources/runtime/node/bin/node \
      $out/opt/workbuddy/resources/app.asar.unpacked/cli/dist/codebuddy-lite-wb.mjs "$@"
    EOF
    chmod +x $out/bin/workbuddy-cli

    icon="$out/opt/workbuddy/resources/app.asar.unpacked/resources/icon.png"
    cp "$icon" $out/share/pixmaps/workbuddy.png
    cp "$icon" $out/share/icons/hicolor/1024x1024/apps/workbuddy.png
    cp ${desktopItem}/share/applications/workbuddy.desktop $out/share/applications/
    # Icon 用包内图标的绝对路径：按主题名查找在本机 GNOME 下不可靠，
    # 会回退成系统默认图标；绝对路径稳定生效，且图标与包同生命周期。
    substituteInPlace $out/share/applications/workbuddy.desktop \
      --replace-fail "Icon=workbuddy" "Icon=$icon"

    runHook postInstall
  '';

  meta = {
    description = "Tencent WorkBuddy AI Agent desktop app (unofficial Linux port)";
    homepage = "https://github.com/acgq/workbuddy-linux";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "workbuddy";
  };
}
