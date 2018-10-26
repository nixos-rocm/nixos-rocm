{ fetchFromGitHub, buildPythonPackage, pyyaml }:
buildPythonPackage rec {
  pname = "Tensile";
  version = "4.6.0";
  src = fetchFromGitHub {
    owner = "ROCmSoftwarePlatform";
    repo = "Tensile";
    rev = "v${version}";
    sha256 = "048sji67gm10z7nj3sssjvp3k2ri0xnl7awh2n92iscf4zk6c9nr";
  };
  buildInputs = [ pyyaml ];
}
