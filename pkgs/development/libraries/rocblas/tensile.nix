{ fetchFromGitHub, buildPythonPackage, pyyaml }:
buildPythonPackage rec {
  pname = "Tensile";
  version = "4.7.0";
  src = fetchFromGitHub {
    owner = "ROCmSoftwarePlatform";
    repo = "Tensile";
    rev = "v${version}";
    sha256 = "0h5g10ihz244s96pd03ca9dmsa0xrl51851a3s7q5v3xn65yq3mg";
  };
  buildInputs = [ pyyaml ];
}
