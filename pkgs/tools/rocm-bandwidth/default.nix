{ stdenv, fetchFromGitHub, cmake, rocr, roct }:
stdenv.mkDerivation {
  name = "rocm-bandwidth";
  version = "2018-04-19";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "rocm_bandwidth_test";
    rev = "d942f282be5a15590f447fa820230656e268236f";
    sha256 = "1a47k3a2zzjgmzcc6hg23v86qp4s8y9ca5w3nkd8fv837chsmqg2";
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
