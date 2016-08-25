{ stdenv
, fetchurl
, qt

, alsaLib
, dbus
, fontconfig
, freetype
, gcc
, glib
, gst_plugins_base
, gstreamer
, icu_54_1
, libpulseaudio
, libuuid
, libxml2
, libxslt
, nspr
, nss
, pkgconfig
, sqlite
, xlibs
, xorg
, zlib
}:


stdenv.mkDerivation rec {

  name = "zoom-us";

  version = "2.0.57232.0713";
  src = fetchurl {
    url = "https://zoom.us/client/latest/zoom_${version}_x86_64.tar.xz";
    sha256 = "0ik1xiir14c2n2l5yxa4gnd19p726bvz4jz1gp9svm4831i30cj5";
  };

  phases = [ "unpackPhase" "installPhase" ];
  nativeBuildInputs = [ pkgconfig qt.makeQtWrapper ];
  libPath = stdenv.lib.makeLibraryPath [
    alsaLib
    dbus
    fontconfig
    freetype
    gcc.cc
    glib
    gst_plugins_base
    gstreamer
    icu_54_1
    libpulseaudio
    libuuid
    libxml2
    libxslt
    nspr
    nss
    qt.qtbase
    sqlite
    xorg.libX11
    xorg.libXcomposite
    xorg.libXcursor
    xorg.libXdamage
    xorg.libXext
    xorg.libXfixes
    xorg.libXi
    xorg.libXrender
    xorg.libXtst
    xorg.libxcb
    xorg.xcbutilimage
    xorg.xcbutilkeysyms
    zlib
  ];

  installPhase = ''
    mkdir -p $out/share
    cp -r \
      application-x-zoom.png \
      audio \
      imageformats \
      chrome.bmp \
      config-dump.sh \
      dingdong1.pcm \
      dingdong.pcm \
      doc \
      Droplet.pcm \
      Droplet.wav \
      platforminputcontexts \
      platforms \
      platformthemes \
      Qt \
      QtQml \
      QtQuick \
      QtQuick.2 \
      ring.pcm \
      ring.wav \
      version.txt \
      xcbglintegrations \
      zcacert.pem \
      zoom \
      Zoom.png \
      ZXMPPROOT.cer \
      $out/share

    mkdir -p $out/lib
    cp lib* $out/lib

    patchelf \
      --set-interpreter $(cat $NIX_CC/nix-support/dynamic-linker) \
      $out/share/zoom
    wrapQtProgram "$out/share/zoom" \
      --prefix LD_LIBRARY_PATH ':' ${libPath}:$out/lib
    mkdir -p $out/bin
    ln -s $out/share/zoom $out/bin/zoom-us
  '';
 }
