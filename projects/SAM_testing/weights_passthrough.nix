{ lib, stdenv, fetchgit }:

stdenv.mkDerivation rec {
  name = "weights_passthrough";
  dontUnpack = true;
  dontFixup = true;
  dontBuild = true;
  src = fetchgit {
      url = "https://huggingface.co/facebook/sam-vit-base";
      rev = "70c1a07f894ebb5b307fd9eaaee97b9dfc16068f";
      hash = "sha256-8cN98pYePEj+TmuXFSYLQIOsRc0CUP0rhgdERlG8Wl8=";
      fetchLFS = true;
    };
  installPhase = ''
    mkdir -p $out
    cp ${src}/* $out
  '';

}