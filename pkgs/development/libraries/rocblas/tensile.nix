{ fetchFromGitHub, buildPythonPackage, pyyaml }:
buildPythonPackage rec {
  pname = "Tensile";
  version = "4.5.1";
  src = fetchFromGitHub {
    owner = "ROCmSoftwarePlatform";
    repo = "Tensile";
    rev = "v${version}";
    sha256 = "1sbr04jk000gv0afj6vyddxm2n9frahs2rmw3jsx8j2gkfvkqhih";
  };
  buildInputs = [ pyyaml ];
}
