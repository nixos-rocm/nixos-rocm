{ stdenv, fetchFromGitHub, cmake, rocr, roct }:
stdenv.mkDerivation rec {
  name = "rocm-bandwidth";
  version = "2.0.0";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "rocm_bandwidth_test";
    rev = "roc-${version}";
    sha256 = "10rr6fqjzf7dz4l5xk8mn5kyrs298jpfwqhzxc821bbsij3i2vaz";
  };
  nativeBuildInputs = [ cmake ];
  buildInputs = [ rocr roct ];
  cmakeFlags = [
    "-DROCR_INC_DIR=${rocr}/include"
    "-DROCR_LIB_DIR=${rocr}/lib"
  ];
  meta = {
    description = "Bandwidth test for ROCm";
    homepage = https://github.com/RadeonOpenCompute/rocm_bandwidth_test;
    license = stdenv.lib.licenses.ncsa;
    platforms = stdenv.lib.platforms.linux;
  };
}
