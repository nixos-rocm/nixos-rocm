{ stdenv, fetchFromGitHub, cmake, rocr, roct }:
stdenv.mkDerivation rec {
  name = "rocm-bandwidth";
  version = "3.0.0";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "rocm_bandwidth_test";
    rev = "roc-${version}";
    sha256 = "1hjnj716rzawrqfp1qzmd7zbdaa4sjjg7dfg6s6kkklh7r87sqjp";
  };
  nativeBuildInputs = [ cmake ];
  buildInputs = [ rocr roct ];
  cmakeFlags = [
    "-DROCR_INC_DIR=${rocr}/include"
    "-DROCR_LIB_DIR=${rocr}/lib"
  ];
  # A non-void function doesn't return on all paths, so building with
  # -Werror fails with some compilers (eg. gcc 7.4.0)
  patchPhase = ''
    sed 's/\(add_executable(''${TEST_NAME} ''${Src})\)/\1\ntarget_compile_options(''${TEST_NAME} PRIVATE -Wno-return-type)/' -i CMakeLists.txt
  '';

  meta = {
    description = "Bandwidth test for ROCm";
    homepage = https://github.com/RadeonOpenCompute/rocm_bandwidth_test;
    license = stdenv.lib.licenses.ncsa;
    platforms = stdenv.lib.platforms.linux;
  };
}
