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

  pname = "qoder-cn";
  version = current.version;

  baseUrl = "https://static.qoder.com.cn/qoder-app/releases/latest";

  architectures = {
    x86_64-linux = "amd64";
    aarch64-linux = "arm64";
  };

  system = stdenv.hostPlatform.system;

  debUrl =
    system:
    let
      arch = architectures.${system} or (throw "qoder-cn: unsupported system: ${system}");
    in
    "${baseUrl}/Qoder-CN-linux-${arch}.deb";

  src = fetchurl {
    url = debUrl system;
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
      name = "qoder-cn";
      desktopName = "Qoder CN";
      genericName = "Text Editor";
      comment = "Qoder - Agent workbench for human and AI software teams";
      exec = "qoder-cn --open-file %U";
      icon = "qoder-cn";
      terminal = false;
      startupNotify = false;
      startupWMClass = "qoder-cn";
      categories = [
        "Development"
        "IDE"
      ];
      mimeTypes = [
        "text/plain"
        "text/markdown"
        "text/x-markdown"
        "text/csv"
        "text/tab-separated-values"
        "text/html"
        "application/xhtml+xml"
        "application/json"
        "application/xml"
        "text/xml"
        "application/yaml"
        "text/yaml"
        "application/toml"
        "text/x-log"
        "text/css"
        "text/javascript"
        "application/javascript"
        "application/typescript"
        "text/x-typescript"
        "text/x-python"
        "text/x-python3"
        "text/x-script.python"
        "text/x-c"
        "text/x-csrc"
        "text/x-chdr"
        "text/x-c++"
        "text/x-c++src"
        "text/x-c++hdr"
        "text/x-java"
        "text/x-java-source"
        "text/x-csharp"
        "text/x-go"
        "text/x-rust"
        "text/x-ruby"
        "application/x-ruby"
        "text/x-php"
        "application/x-php"
        "text/x-perl"
        "application/x-perl"
        "text/x-lua"
        "text/x-sql"
        "text/x-shellscript"
        "application/x-shellscript"
        "text/x-makefile"
        "text/x-cmake"
        "text/x-patch"
        "text/x-diff"
        "text/x-tex"
        "text/x-scala"
        "text/x-objcsrc"
        "text/x-objcppsrc"
        "text/x-swift"
        "text/x-kotlin"
        "text/x-dart"
        "text/x-groovy"
        "text/x-clojure"
        "text/x-lisp"
        "text/x-ocaml"
        "application/x-ipynb+json"
        "application/x-bat"
        "application/pdf"
        "image/png"
        "image/jpeg"
        "image/gif"
        "image/webp"
        "image/svg+xml"
        "x-scheme-handler/qoder-cn"
      ];
      keywords = [
        "qoder"
        "qoder-cn"
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
    mv ./extracted/opt/Qoder-CN $out/share/qoder-cn
    mv ./extracted/usr/share/icons $out/share/icons
    mv ./extracted/usr/share/mime $out/share/mime 2>/dev/null || true

    mkdir -p $out/bin
    makeWrapper $out/share/qoder-cn/qoder-cn $out/bin/qoder-cn \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath runtimeLibs}" \
      --prefix PATH : ${lib.makeBinPath [ stdenv.cc ]}

    runHook postInstall
  '';

  meta = {
    description = "Qoder CN - Agentic AI coding IDE by Alibaba (China edition)";
    homepage = "https://qoder.com.cn";
    license = lib.licenses.unfree;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = builtins.attrNames architectures;
    mainProgram = "qoder-cn";
    maintainers = with lib.maintainers; [ lonerOrz ];
  };
})
