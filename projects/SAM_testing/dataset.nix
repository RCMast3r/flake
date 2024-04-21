{ lib, stdenv, fetchurl, unzip }:
# shoutout to this dude: https://nono.ma/download-dropbox-file-curl
stdenv.mkDerivation rec {
  name = "dataset";
  dontUnpack = true;
  dontFixup = true;
  buildInputs = [ unzip ];
  src = fetchurl {
    url = "https://www.dropbox.com/scl/fo/h42wt4t2k9ize3bleztlp/h/Prompting%20results.zip?rlkey=s7zs8j9gcu3fgik05490oqjvl&dl=1";
    curlOptsList = [ "-L" ];
    sha256 = "sha256-Fr5uXLG8zzyUM3g7i/KMfNiVKddvQwebFOj9odMwVcw=";
  };
  dontBuild = true;
  installPhase = ''
    mkdir -p $out
    unzip ${src} -d $out -x /
    unzip $out/*.zip -d $out 
  '';

}
