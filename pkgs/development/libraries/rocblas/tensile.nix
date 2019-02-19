{ fetchFromGitHub, buildPythonPackage, pyyaml }:
buildPythonPackage rec {
  pname = "Tensile";
  version = "4.8.0";
  src = fetchFromGitHub {
    owner = "ROCmSoftwarePlatform";
    repo = "Tensile";
    rev = "v${version}";
    sha256 = "1948ydr40gzirb0jdjkcapack31sq2zjybihd0v7qa502japb5pk";
  };
  buildInputs = [ pyyaml ];
}
