{ fetchFromGitHub, buildPythonPackage, pyyaml, lib }:
buildPythonPackage rec {
  pname = "Tensile";
  version = "2.4.0";
  src = fetchFromGitHub {
    owner = "ROCmSoftwarePlatform";
    repo = "Tensile";
    rev = with lib.versions; 
      "rocm-${lib.concatStringsSep "." [(major version) (minor version)]}";
    sha256 = "18gssbl7rvsk8i717kr4cdnqagwgc3qd5fn2fxhja8098ppcycmq";
  };
  buildInputs = [ pyyaml ];
}
