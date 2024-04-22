{ lib, stdenv, fetchurl, src, fetchgit }:

stdenv.mkDerivation rec {
  name = "weights_passthrough";
  dontUnpack = true;
  dontFixup = true;
  dontBuild = true;
  src = fetchgit {
    url = src.url;
    
  };
  installPhase = ''
    mkdir -p $out
    ls source
    ls ${src}
    cp -r ${src} $out
  '';

}