{ stdenv, fetchFromGitHub, cmake, pkgconfig, libunwind, python
, rocr, hcc, hcc-lld, hip, rocm-cmake, comgr
, doCheck ? false
# Tensile slows the build a lot, but can produce a faster rocBLAS
, useTensile ? true, rocblas-tensile ? null
, gfortran, liblapack, boost, gtest }:
let pyenv = python.withPackages (ps:
               with ps; [pyyaml pip wheel setuptools virtualenv]); in
assert useTensile -> rocblas-tensile != null;
stdenv.mkDerivation rec {
  name = "rocblas";
  version = "2.7.0";
  src = fetchFromGitHub {
    owner = "ROCmSoftwarePlatform";
    repo = "rocBLAS";
    # rev = with stdenv.lib.versions; 
    #   "rocm-${stdenv.lib.concatStringsSep 
    #             "." [(major version) (minor version)]}";
    # sha256 = "0ydzbwxq84ng1ka1ax78mvqx3g37ckbwz2l23iqg7l1qa1q0ymmg";
    # rev = "b548b687b28f95ed6b2a01aab45fc4970c68d763";
    # sha256 = "03x8lmjaw3vdi4wa1j8phbbwy1a2r2hkmgg1bl2ypycm6g7mhw3k";
    rev = "834406c9012bba7fd1c76d6d3b8fe8350bb3ee23";
    sha256 = "1acm1psq61xfqjicax3jm5wpq9jawyk528amw7qrk3cj1fndzdqz";
  };
  nativeBuildInputs = [ cmake rocm-cmake pkgconfig python ];

  buildInputs = [ libunwind pyenv hip rocr comgr ]
    ++ stdenv.lib.optionals doCheck [ gfortran boost gtest liblapack ];

  cmakeFlags = [
    "-DCMAKE_CXX_COMPILER=${hip}/bin/hipcc"
    "-DCMAKE_INSTALL_INCLUDEDIR=include"
    "-DBUILD_WITH_TENSILE=${if useTensile then "ON" else "OFF"}"
  ] ++ stdenv.lib.optionals doCheck [
    "-DBUILD_CLIENTS_SAMPLES=YES"
    "-DBUILD_CLIENTS_TESTS=YES"
    "-DBUILD_CLIENTS_BENCHMARKS=YES"
  ] ++ stdenv.lib.optionals useTensile [
    "-DVIRTUALENV_HOME_DIR=${rocblas-tensile}"
    "-DTensile_TEST_LOCAL_PATH=${rocblas-tensile}"
    "-DTensile_ROOT=${rocblas-tensile}/bin"
    "-DTensile_LOGIC=hip_lite"
  ];

  patchPhase = ''
    sed -e '/include(virtualenv)/d' \
        -e '/virtualenv_install.*/d' \
        -e 's|/opt/rocm/hcc|${hcc}|' \
        -e 's|/opt/rocm/hip|${hip}|' \
        -i CMakeLists.txt
  '';
}
