{ lib
, python3Packages
, dataset
, GT_type
, groundtruths
}:

python3Packages.buildPythonApplication {
  pname = "train_script";
  version = "1.0.0";

  propagatedBuildInputs = [
    python3Packages.torch
    python3Packages.torchvision
    python3Packages.numpy
    python3Packages.transformers
    python3Packages.monai
  ];
  makeWrapperArgs = ["--set DATASET ${dataset}" "--set GROUNDTRUTH ${groundtruths}" "--set GT_TYPE ${GT_type}" ];
  src = ./SAMtraining;
}