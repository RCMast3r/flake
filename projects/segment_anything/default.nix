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
      src = inputs.segment-anything-src;

      # function for creating the package variant for a target platform
      mkSegmentAnythingVariant = args: pkgs.callPackage ./package.nix ({ inherit src; } // args);

    in
    {
      devshells.SAM-devshell = {
        # env = [
          # {
            # TODO add in the paths to training sets n stuff that would be cool
            # name = "HTTP_PORT";
          # }
        # ];
        
        packages = [
          python3Variants.nvidia.torch
        ];
      };
      packages = {
        SAM-nvidia = mkSegmentAnythingVariant {
          python3Packages = python3Variants.nvidia;
        };
        # actually calling the mkSegmentAnythingVariant function with specific parameters depending on 
        # desired package platform variant for segment anything 
      };
    };


}
