{ lib, stdenv, train_script }:

stdenv.mkDerivation rec {
  name = "weights";
  dontUnpack = true;
  dontFixup = true;
  dontBuild = true;

  installPhase = ''
    mkdir -p $out
    
    ${train_script}/bin/train.py
    cp *.pth $out
  '';

}