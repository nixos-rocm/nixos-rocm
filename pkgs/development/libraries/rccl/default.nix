{ stdenv, fetchFromGitHub, cmake, rocm-cmake, hcc, hip }:
stdenv.mkDerivation {
  name = "rccl";
  version = "2018-10-04";
  src = fetchFromGitHub {
    owner = "ROCmSoftwarePlatform";
    repo = "rccl";
    rev = "3e6853a56cee00b2c4470f6c8c283a2c4536daa1";
    sha256 = "06cyj7j03c0nlsdn7lscrr4k1956w2zy07dym8dqkv5wn9i6hi3j";
  };
  nativeBuildInputs = [ cmake hcc hip ];
  cmakeFlags = [
    "-DCMAKE_CXX_COMPILER=${hcc}/bin/hcc"
    "-DCMAKE_INSTALL_INCLUDEDIR=include"
    "-DROCM_DIR=${rocm-cmake}/share/rocm/cmake"
  ];
}
