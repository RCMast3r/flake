# this nix function creates a dataset from a given input url
{ lib, stdenv, fetchurl, unzip, dataset_url}:
# shoutout to this dude: https://nono.ma/download-dropbox-file-curl
stdenv.mkDerivation rec {
  name = "dataset";
  dontUnpack = true;
  dontFixup = true;
  buildInputs = [ unzip ];
  src = dataset_url;
  dontBuild = true;
  installPhase = ''
    mkdir -p $out
    echo ${src}
    unzip ${src} -d $out -x /
  '';

}
