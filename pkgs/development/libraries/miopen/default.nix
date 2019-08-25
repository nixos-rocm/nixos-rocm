{ stdenv, fetchFromGitHub, cmake, pkgconfig, half, openssl, boost
, rocm-cmake, rocm-opencl-runtime, rocr, hcc, clang-ocl, miopengemm, rocblas
, useHip ? false, hip }:
assert useHip -> hip != null;
stdenv.mkDerivation rec {
  name = "miopen";
  version = "2.0.1";
  src = fetchFromGitHub {
    owner = "ROCmSoftwarePlatform";
    repo = "MIOpen";
    rev = version;
    sha256 = "0cb6fla6d9dlvjzc5d25dl8m7vpvqq6bh64l29z1cq3vx42ir8ip";
  };
  nativeBuildInputs = [ cmake pkgconfig rocm-cmake ];
  buildInputs = [ rocr half openssl boost rocblas miopengemm ]
    ++ (if useHip then [ hcc hip ] else [rocm-opencl-runtime clang-ocl hip]);

  preConfigure = stdenv.lib.optionalString (!useHip) ''
    NIX_CFLAGS_COMPILE="-D__HIP_PLATFORM_HCC__ ''${NIX_CFLAGS_COMPILE}"
  '';

  cmakeFlags = [
    "-DCMAKE_PREFIX_PATH=${hcc};${hip};${clang-ocl}"
    "-DMIOPEN_AMDGCN_ASSEMBLER_PATH=${hcc}/bin"
    "-DCMAKE_INSTALL_INCLUDEDIR=include"
    "-DMIOPEN_USE_ROCBLAS=ON"
    "-DBoost_USE_STATIC_LIBS=OFF"
  ] ++ (if useHip
  then [ "-DCMAKE_CXX_COMPILER=${hip}/bin/hipcc"
         "-DCMAKE_C_COMPILER=${clang}/bin/clang"
         "-DMIOPEN_BACKEND=HIP"
         "-DENABLE_HIP_WORKAROUNDS=NO" ]
  else [ "-DMIOPEN_BACKEND=OpenCL"
         "-DOPENCL_INCLUDE_DIRS=${rocm-opencl-runtime}/include/opencl2.2"
         "-DOPENCL_LIB_DIRS=${rocm-opencl-runtime}/lib"
  ]);
  patchPhase = ''
    sed -e 's,cmake_minimum_required( VERSION 2.8.12 ),cmake_minimum_required( VERSION 3.10 ),' \
        -e 's,\(set( MIOPEN_INSTALL_DIR\).*,\1 ''${CMAKE_INSTALL_PREFIX}),' \
        -e 's,\(set(MIOPEN_SYSTEM_DB_PATH "\)''${CMAKE_INSTALL_PREFIX}/\(.*\),\1\2,' \
        -e '/enable_testing()/d' \
        -e '/add_subdirectory(test)/d' \
        -e '/^include(ClangTidy)/,/^)$/d' \
        -i CMakeLists.txt
    sed 's/return record;/return std::move(record);/' -i src/include/miopen/db.hpp
    sed 's/return record;/return std::move(record);/' -i src/db.cpp
    for f in src/CMakeLists.txt addkernels/CMakeLists.txt; do
      sed '/^[[:space:]]*clang_tidy_check(.*/d' -i "$f"
    done
    sed '/add_dependencies(tidy miopen_tidy_inlining)/d' -i src/CMakeLists.txt
  '';
}
