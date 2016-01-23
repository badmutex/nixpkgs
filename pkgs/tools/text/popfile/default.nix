{ stdenv, fetchzip, makeWrapper,
perl, perlPackages,
... }:

let perlLibs = with perlPackages; [
    perl
    DBI
    DBDSQLite
    Digest
    DigestMD5
    HTMLTagset
    MIMEBase64 # == MIMEQuotedPrint
    TimeDate # == DateParse
    HTMLTemplate
    # IOSocketSocks # FIXME error
    IOSocketSSL
    NetSSLeay
    SOAPLite
  ];
in

stdenv.mkDerivation rec {
  shortname = "popfile";
  version = "1.1.3";
  name = "${shortname}-${version}";

  src = fetchzip {
    url = "http://getpopfile.org/downloads/popfile-1.1.3.zip";
    sha256 = "0gcib9j7zxk8r2vb5dbdz836djnyfza36vi8215nxcdfx1xc7l63";
    stripRoot = false;
  };

  buildInputs = [ makeWrapper ] ++ perlLibs;
  # propagatedBuildInputs = perlLibs;

  phases = [ "unpackPhase" "installPhase" "patchPhase" "postInstall" ];

  installPhase = ''
    mkdir -p $out/bin
    cd $src
    cp -r * $out/bin
    cd $out/bin
    chmod +x *.pl
  '';

  patchPhase = "patchShebangs $out";

  postInstall = ''
    find $out -name '*.pl' -executable | while read path; do
      wrapProgram "$path" --prefix PERL5LIB : $PERL5LIB:$out/bin --set POPFILE_ROOT $out/bin --set POPFILE_USER \$HOME/.popfile
    done
  '';

  meta = {
    description = "An email classification system that automatically sorts messages and fights spam.";
    homepage = http://getpopfile.org;
    license = stdenv.lib.licenses.gpl2;

    # Should work on OS X, but havent tested it.
    # Windows support is more complicated.
    # http://getpopfile.org/docs/faq:systemrequirements
    platforms = stdenv.lib.platforms.linux;
  };

}
  
