{ lib
, python3Packages
, dataset
, GT_type
, groundtruths
, torch
, cudaPackages
, input_weights
}:

python3Packages.buildPythonApplication {
  pname = "train_script";
  version = "1.0.0";

  propagatedBuildInputs = [
    torch
    # python3Packages.torch
    python3Packages.torchvision
    python3Packages.numpy
    python3Packages.transformers
    python3Packages.monai
  ];
  makeWrapperArgs = [ "--set WEIGHTS_BASE ${input_weights}" "--set DATASET ${dataset}" "--set GROUNDTRUTH ${groundtruths}" "--set GT_TYPE ${GT_type}" ];
  src = ./SAMtraining;
}