{ pkgs
, stdenv
, dpkg
, patchelf
, makeWrapper
, fetchurl
, bluez
, libX11
, libXtst
, ... }:

stdenv.mkDerivation {
  name = "unified-remote-3.6.0.745";
  src = fetchurl {
    url = "https://www.unifiedremote.com/download/linux-x64-deb";
    sha256 = "92c1c8828bc9337fa84036cda8a880ed913b81e12a10a8835d034367af2f75a6";
  };

  nativeBuildInputs = [ dpkg patchelf makeWrapper ];
  buildInputs = [ bluez libX11 ];

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
    ln -s "${stdenv.lib.makeLibraryPath [ libX11 ]}/libX11.so.6" $out/lib
    ln -s "${stdenv.lib.makeLibraryPath [ libXtst ]}/libXtst.so.6" $out/lib

    wrapProgram $out/bin/urserver --prefix LD_LIBRARY_PATH : $out/lib

  '';

  meta = with stdenv.lib; {
    homepage = https://www.unifiedremote.com;
    description = "Turn your smartphone into a universal remote control";
    license = licenses.unfree;
    maintainers = [ maintainers.badi ];
    platforms = platforms.unix;
  };

}
