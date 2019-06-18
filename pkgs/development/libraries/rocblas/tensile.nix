{ fetchFromGitHub, buildPythonPackage, pyyaml, lib }:
buildPythonPackage rec {
  pname = "Tensile";
  version = "2.5.0";
  src = fetchFromGitHub {
    owner = "ROCmSoftwarePlatform";
    repo = "Tensile";
    rev = with lib.versions; 
      "rocm-${lib.concatStringsSep "." [(major version) (minor version)]}";
    sha256 = "1cz6i2rfjkrc5p4xs0vspl9gbrqfw6zxw5fp1lnp002cdnhyqcx4";
  };
  buildInputs = [ pyyaml ];
}
