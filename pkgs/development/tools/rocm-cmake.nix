{ stdenv, fetchFromGitHub, cmake }:
stdenv.mkDerivation {
  name = "rocm-cmake";
  version = "2019-02-20";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "rocm-cmake";
    rev = "cfd021c1c5cfb07979904b23f54152d8a410acb1";
    sha256 = "0vwqmv15cjmzdqv4z294n6jr6bkrjq6ckz8gjbc6a40glvkalib7";
  };
  nativeBuildInputs = [ cmake ];
}
