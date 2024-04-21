{ lib, python3Packages, fetchFromGitHub, fetchgit, src}: 

python3Packages.buildPythonPackage rec {
  pname = "segment_anything";
  version = "1.0.0";
  format="pyproject";
  # Extract the specific subdirectory within the repository
  propagatedBuildInputs = [  python3Packages.setuptools ];

  inherit src;
  meta = with lib; {
    description = "Description of your package";
    license = licenses.mit;
  };
} 