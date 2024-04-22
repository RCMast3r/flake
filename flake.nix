{
  nixConfig = {
    extra-substituters = [ "https://ai.cachix.org" ];
    extra-trusted-public-keys = [ "ai.cachix.org-1:N9dzRK+alWwoKXQlnn0H6aUx0lU/mspIoz8hMvGvbbc=" ];
  };

  description = "A Nix Flake that makes AI reproducible and easy to run";

  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };
    invokeai-src = {
      url = "github:invoke-ai/InvokeAI/v3.3.0post3";
      flake = false;
    };
    textgen-src = {
      url = "github:oobabooga/text-generation-webui/v1.7";
      flake = false;
    };
    segment-anything-src = {
      url = "github:facebookresearch/segment-anything";
      flake = false;
    };

    SAM-FunML-src = {
      url = "github:RCMast3r/SAM-FunML-sp24";
      flake = false;
    };

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    hercules-ci-effects = {
      url = "github:hercules-ci/hercules-ci-effects";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    clock_dataset_url = {
      url = "https://www.dropbox.com/scl/fo/zxmucpwwnd4w0428bj9r9/h/Clock?rlkey=mtvz27lainry7anehq8ahf7sn&dl=1";
      flake = false;
    };
    facebook
    devshell.url = "github:numtide/devshell";
  };
  outputs = { flake-parts, invokeai-src, hercules-ci-effects, devshell, segment-anything-src, SAM-FunML-src, clock_dataset_url, ... }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      perSystem = { system, ... }: {
        _module.args.pkgs = import inputs.nixpkgs { config.allowUnfree = true; inherit system; };
        legacyPackages = {
          koboldai = builtins.throw ''
                   koboldai has been dropped from nixified.ai due to lack of upstream development,
                   try textgen instead which is better maintained. If you would like to use the last
                   available version of koboldai with nixified.ai, then run:

                   nix run github:nixified.ai/flake/0c58f8cba3fb42c54f2a7bf9bd45ee4cbc9f2477#koboldai
          '';
        };
      };
      systems = [
        "x86_64-linux"
      ];
      debug = true;
      imports = [
        devshell.flakeModule
        hercules-ci-effects.flakeModule
#        ./modules/nixpkgs-config
        ./overlays
        ./projects/invokeai
        ./projects/textgen
        ./projects/segment_anything
        ./projects/SAM_testing
        ./website
      ];
    };
}
