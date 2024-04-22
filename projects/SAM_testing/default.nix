{ config, inputs, lib, withSystem, ... }:

# variables to be used within this derivation that is per each system
let
  l = lib // config.flake.lib;
  inherit (config.flake) overlays;
in

{
  perSystem = { config, pkgs, ... }:
    let
      # overlays that are common between all of the configurations
      commonOverlays = [
        overlays.python-fixPackages
      ];

      # setting up what overlays get used depending on the platform and what the platforms require
      python3Variants = {
        nvidia = l.overlays.applyOverlays pkgs.python3Packages (commonOverlays ++ [
          overlays.python-torchCuda
          overlays.python-bitsAndBytesOldGpu
        ]);
      };
      # test = inputs.hf_in;
      # get the source code from the inputs to the flake
      # function for creating the package variant for a target platform
      datasetVariants = {
        clock_dataset = pkgs.callPackage ./dataset_creator.nix ({ dataset_url = inputs.clock_dataset_url; });
      };
      mkGroundTruths = pkgs.callPackage ./groundtruths.nix;
      mkTrainScript = args: pkgs.callPackage ./train_script.nix (args);
      mkWeights = args: pkgs.callPackage ./weights.nix (args);
      base_weights = pkgs.callPackage ./weights_passthrough.nix { };
      cudaSupport = true;
    in
    {
      devshells.SAM-devshell = {
        env = [
          {
            name = "dir";
            value = base_weights;
          }
        ];

        packages = [
          base_weights
          python3Variants.nvidia.torch
        ];
      };

      packages = rec {
        trainSAM = mkTrainScript { 
          dataset = datasetVariants.clock_dataset; 
          groundtruths = mkGroundTruths { }; 
          GT_type = "Clock"; 
          python3Packages = python3Variants.nvidia; 
          torch = python3Variants.nvidia.torch; 
          input_weights = base_weights;
        };
        groundtruths = mkGroundTruths { };
        weights = mkWeights { train_script = trainSAM; };
        clock_dataset = datasetVariants.clock_dataset;
        # actually calling the mkSegmentAnythingVariant function with specific parameters depending on 
        # desired package platform variant for segment anything 
      };

      apps = {
        train_clock =
          let
            trainScript = mkTrainScript {
              dataset = datasetVariants.clock_dataset;
              groundtruths = mkGroundTruths { };
              GT_type = "Clock";
              python3Packages = python3Variants.nvidia;
              torch = python3Variants.nvidia.torch;
              input_weights = base_weights;
            };
          in
          {
            type = "app";
            program = "${trainScript}/bin/train.py";
          };
      };
    };


}
