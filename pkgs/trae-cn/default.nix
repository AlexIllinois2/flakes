{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  binutils,
  copyDesktopItems,
  makeDesktopItem,
  makeWrapper,
  xz,

  # Hardened electron build inputs
  glib,
  gtk3,
  gdk-pixbuf,
  atk,
  at-spi2-atk,
  at-spi2-core,
  cairo,
  pango,
  nss,
  nspr,
  cups,
  curl,
  dbus,
  expat,
  fontconfig,
  freetype,
  libdrm,
  mesa,
  alsa-lib,
  libpulseaudio,
  libGL,
  libgbm,
  zlib,
  libgcrypt,
  libkrb5,
  udev,
  libxkbcommon,
  libxkbfile,
  libxcb,
  libX11,
  libXcomposite,
  libXdamage,
  libXext,
  libXfixes,
  libXrandr,
  libXScrnSaver,
  libXtst,
  xcbutilwm,
  xcbutilimage,
  xcbutilkeysyms,
  xcbutilrenderutil,
  vulkan-loader,
  webkitgtk_4_1,
  libsoup_3,
  libsecret,
}:

let
  current = lib.trivial.importJSON ./version.json;

  pname = "trae-cn";
  version = current.version;
  buildId = current.buildId;

  baseUrl = "https://lf-cdn.trae.com.cn/obj/trae-com-cn/pkg/app/releases/stable";

  architectures = {
    x86_64-linux = "x64";
    aarch64-linux = "arm64";
  };

  system = stdenv.hostPlatform.system;

  # Generate download URL for a given system and version.
  debUrl =
    system: buildId:
    let
      arch = architectures.${system} or (throw "trae-cn: unsupported system: ${system}");
    in
    "${baseUrl}/${buildId}/linux/TRAE_CN-linux-${arch}.deb";

  src = fetchurl {
    url = debUrl system buildId;
    hash = current.${system + "-hash"};
  };

  runtimeLibs = [
    glib.out
    gtk3.out
    gdk-pixbuf
    atk
    at-spi2-atk
    at-spi2-core
    cairo
    pango
    nss
    nspr
    cups
    curl
    dbus
    expat
    fontconfig
    freetype
    libdrm
    mesa
    alsa-lib
    libpulseaudio
    libGL
    libgbm
    zlib
    libkrb5
    udev
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
    xcbutilwm
    xcbutilimage
    xcbutilkeysyms
    xcbutilrenderutil
    vulkan-loader
    libgcrypt.lib
    webkitgtk_4_1
    libsoup_3
    libsecret
    stdenv.cc.cc.lib
  ];
in
stdenv.mkDerivation (finalAttrs: {
  inherit pname version src;

  nativeBuildInputs = [
    autoPatchelfHook
    binutils
    copyDesktopItems
    dpkg
    makeWrapper
    xz
  ];

  buildInputs = runtimeLibs;

  autoPatchelfIgnoreMissingDeps = [
    "libc.musl-x86_64.so.1"
    "libc.musl-aarch64.so.1"
    "libwebkit2gtk-4.1.so.0"
    "libsoup-3.0.so.0"
    "libsecret-1.so.0"
  ];

  desktopItems = [
    (makeDesktopItem {
      name = "trae-cn";
      desktopName = "Trae CN";
      genericName = "Text Editor";
      comment = "TRAE, The Real AI Engine.";
      exec = "trae-cn %F";
      icon = "trae-cn";
      terminal = false;
      startupNotify = false;
      startupWMClass = "Trae CN";
      categories = [
        "TextEditor"
        "Development"
        "IDE"
      ];
      mimeTypes = [
        "application/x-trae-cn-workspace"
      ];
      keywords = [
        "trae-cn"
      ];
    })
  ];

  installPhase = ''
    runHook preInstall

    # Extract deb manually - dpkg -x fails on chrome-sandbox setuid bit
    mkdir -p ./extracted
    (
      cd ./extracted
      ar x $src
      if [ -f data.tar.xz ]; then
        tar xf data.tar.xz --no-same-permissions
      elif [ -f data.tar.gz ]; then
        tar xf data.tar.gz --no-same-permissions
      elif [ -f data.tar.zst ]; then
        tar --use-compress-program=unzstd -xf data.tar.zst --no-same-permissions
      else
        echo "ERROR: unknown data.tar format"
        ls -la
        exit 1
      fi
    )

    mkdir -p $out/share
    mv ./extracted/usr/share/trae-cn $out/share/trae-cn
    mv ./extracted/usr/share/pixmaps $out/share/pixmaps
    mv ./extracted/usr/share/appdata $out/share/appdata 2>/dev/null || true
    mv ./extracted/usr/share/bash-completion $out/share/bash-completion 2>/dev/null || true
    mv ./extracted/usr/share/mime $out/share/mime 2>/dev/null || true

    # deb 只提供 share/pixmaps 下的单张图标；按 icon theme 规范
    # 再装入 hicolor，桌面环境（GNOME 等）才能正确显示应用图标。
    mkdir -p $out/share/icons/hicolor/1024x1024/apps
    cp $out/share/pixmaps/trae-cn.png \
      $out/share/icons/hicolor/1024x1024/apps/trae-cn.png

    mkdir -p $out/bin
    makeWrapper $out/share/trae-cn/bin/trae-cn $out/bin/trae-cn \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath runtimeLibs}" \
      --prefix PATH : ${lib.makeBinPath [ stdenv.cc ]}

    runHook postInstall
  '';

  meta = {
    description = "Trae CN - AI-powered IDE by ByteDance (China edition)";
    homepage = "https://www.trae.com.cn";
    license = lib.licenses.unfree;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = builtins.attrNames architectures;
    mainProgram = "trae-cn";
    maintainers = with lib.maintainers; [ lonerOrz ];
  };
})
