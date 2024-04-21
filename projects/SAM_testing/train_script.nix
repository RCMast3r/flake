{ lib
, python3Packages
, dataset
}:

python3Packages.buildPythonApplication {
  pname = "train_script";
  version = "1.0.0";

  propagatedBuildInputs = [
    python3Packages.torch
    python3Packages.torchvision
    python3Packages.numpy
  ];
  makeWrapperArgs = ["--set DATASET ${dataset}"];
  src = ./SAMtraining;
}