{ fetchFromGitHub, buildPythonPackage, pyyaml, lib }:
buildPythonPackage rec {
  pname = "Tensile";
  version = "2.3.0";
  src = fetchFromGitHub {
    owner = "ROCmSoftwarePlatform";
    repo = "Tensile";
    rev = with lib.versions; 
      "rocm-${lib.concatStringsSep "." [(major version) (minor version)]}";
    sha256 = "0pc4wqz9sn7isqnsnxgrrv85gqnq12l6ama1s5ffyy1z7rh9ca6j";
  };
  buildInputs = [ pyyaml ];
}
