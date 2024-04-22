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

      # get the source code from the inputs to the flake
      # function for creating the package variant for a target platform
      datasetVariants = {
        clock_dataset = pkgs.callPackage ./dataset_creator.nix ({ dataset_url = inputs.clock_dataset_url; });
      };
      mkGroundTruths = pkgs.callPackage ./groundtruths.nix;
      mkTrainScript = args: pkgs.callPackage ./train_script.nix (args);

      cudaSupport = true;
      
    in
    {
      devshells.SAM-devshell = {
        # env = [
        #   {
        #     # TODO add in the paths to training sets n stuff that would be cool
        #     dataset_test = 
        #   }
        # ];

        packages = [
          # datasetenv = [
        #   {
        #     # TODO add in the paths to training sets n stuff that would be cool
        #     dataset_test = 
        #   }
        # ];
          python3Variants.nvidia.torch
        ];
      };
      
      packages = rec {
        trainSAM = mkTrainScript { dataset = datasetVariants.clock_dataset; groundtruths = mkGroundTruths { }; GT_type = "Clock"; python3Packages = python3Variants.nvidia; };
        groundtruths = mkGroundTruths { };
        clock_dataset = datasetVariants.clock_dataset;
        # actually calling the mkSegmentAnythingVariant function with specific parameters depending on 
        # desired package platform variant for segment anything 
      };

      apps = {
        train_clock = let
          trainScript = mkTrainScript { 
            dataset = datasetVariants.clock_dataset; 
            groundtruths = mkGroundTruths { }; 
            GT_type = "Clock";
            python3Packages = python3Variants.nvidia; 
            torch = python3Variants.nvidia.torch; 
          };
        in
        {
          type = "app";
          program = "${trainScript}/bin/train.py";
        };
      };
    };


}
