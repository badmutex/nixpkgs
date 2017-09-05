{ pkgs
, stdenv
, dpkg
, patchelf
, makeWrapper
, fetchurl
, bluez

, remotes ? "/var/lib/unified-remote/remotes"
, ... }:

stdenv.mkDerivation {
  name = "unified-remote-3.6.0.745";
  src = fetchurl {
    url = "https://www.unifiedremote.com/download/linux-x64-deb";
    sha256 = "92c1c8828bc9337fa84036cda8a880ed913b81e12a10a8835d034367af2f75a6";
  };

  nativeBuildInputs = [ dpkg patchelf makeWrapper ];
  buildInputs = [ bluez ];

  buildCommand = ''
    mkdir -p $out
    dpkg -x $src $out
    mv $out/opt/urserver $out/bin
    rmdir $out/opt
    mv $out/bin/urserver-autostart.desktop $out/usr/share/applications
    
    for name in urserver urserver-autostart; do
      path=$out/usr/share/applications/$name.desktop
      substituteInPlace "$path" --replace /opt/urserver $out/bin
    done
    
    patchelf \
      --set-interpreter $(cat $NIX_CC/nix-support/dynamic-linker) \
      $out/bin/urserver

    mkdir $out/lib

    ln -s "${stdenv.lib.makeLibraryPath [ stdenv.cc.cc ]}/libstdc++.so.6" $out/lib/
    ln -s "${stdenv.lib.makeLibraryPath [ bluez ]}/libbluetooth.so.3" $out/lib/

    wrapProgram $out/bin/urserver --prefix LD_LIBRARY_PATH : $out/lib

  '';

}
