{ lib
, python3Packages
, segment_anything
, src
}:

python3Packages.buildPythonApplication {
  pname = "predictor";
  version = "1.0.0";

  propagatedBuildInputs = [
    python3Packages.ipython
    python3Packages.matplotlib
    python3Packages.numpy
    python3Packages.opencv4
    python3Packages.openpyxl
    python3Packages.pillow
    python3Packages.torch
    python3Packages.torchvision
    segment_anything

  ];
  inherit src; 
}