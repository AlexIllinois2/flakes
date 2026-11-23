{ pkgs, lib }:

pkgs.stdenv.mkDerivation rec {
  pname = "workbuddy";
  version = "5.5.6.38337834";

  src = pkgs.fetchurl {
    url = "https://download.codebuddy.cn/workbuddy/saas/linux-x64-deb/WorkBuddy-linux-x64-deb-${version}-5f969292.deb";
    sha256 = "03d756b259d7086c22098fa077589a032d60948d1de7313473360eefe11e240f";
  };

  nativeBuildInputs = [ pkgs.dpkg ];

  unpackPhase = ''
    mkdir -p pkg
    dpkg-deb -x $src pkg
  '';

  installPhase = ''
    mkdir -p $out

    cp -r pkg/opt/WorkBuddy $out/WorkBuddy
    cp -r pkg/usr/share/applications $out/share
    cp -r pkg/usr/share/icons $out/share

    mkdir -p $out/bin
    cat > $out/bin/workbuddy <<EOF
    #!/bin/sh
    export XDG_DATA_DIRS="$out/share:${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}:\$XDG_DATA_DIRS"
    exec $out/WorkBuddy/WorkBuddy --no-sandbox "\$@"
    EOF
    chmod +x $out/bin/workbuddy

    substituteInPlace $out/share/applications/*.desktop \
      --replace /opt/WorkBuddy/WorkBuddy $out/bin/workbuddy \
      --replace /usr/share/icons $out/share/icons
  '';

  meta = with lib; {
    description = "Tencent WorkBuddy";
    platforms = [ "x86_64-linux" ];
    license = licenses.unfree;
  };
}
