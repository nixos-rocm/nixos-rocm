{ stdenv, fetchFromGitHub, cmake, rocr, roct }:
stdenv.mkDerivation rec {
  name = "rocm-bandwidth";
  version = "2.1.0-2019-02-11";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "rocm_bandwidth_test";
    # rev = "roc-${version}";
    rev = "fe64704aa9a357aff8d9ab9aa3a433282e9e4dd6";
    sha256 = "08giirfxm9w9w4awz0ppmvdij2w8mvkrf96idhm1navizw3wxjid";
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
