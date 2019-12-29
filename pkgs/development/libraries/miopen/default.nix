{ stdenv, fetchFromGitHub, cmake, pkgconfig, half, openssl, boost, sqlite, zlib
, rocm-cmake, rocm-opencl-runtime, rocr, hcc, clang, clang-ocl, miopengemm, rocblas
, comgr, useHip ? false, hip }:
assert useHip -> hip != null;
stdenv.mkDerivation rec {
  name = "miopen";
  version = "3.0.0";
  src = fetchFromGitHub {
    owner = "ROCmSoftwarePlatform";
    repo = "MIOpen";
    rev = "roc-${version}";
    sha256 = "1f2p71g0c47g0vzlmfmhih13mj4gh26z80dn3a13kiqw6cqx3l7a";
  };
  nativeBuildInputs = [ cmake pkgconfig rocm-cmake ];
  buildInputs = [ rocr half openssl boost rocblas miopengemm comgr sqlite zlib ]
    ++ (if useHip then [ hcc hip ] else [rocm-opencl-runtime clang-ocl hip hcc]);

  cmakeFlags = [
    "-DCMAKE_PREFIX_PATH=${hcc};${hip};${clang-ocl}"
    "-DCMAKE_INSTALL_INCLUDEDIR=include"
    "-DMIOPEN_USE_ROCBLAS=ON"
    "-DBoost_USE_STATIC_LIBS=OFF"
    "-DMIOPEN_USE_MIOPENGEMM=ON"
  ] ++ (if useHip
        then [ "-DCMAKE_CXX_COMPILER=${hcc}/bin/clang++"
               "-DCMAKE_C_COMPILER=${clang}/bin/clang"
               "-DMIOPEN_BACKEND=HIP"
               "-DENABLE_HIP_WORKAROUNDS=YES" ]
        else [ "-DMIOPEN_BACKEND=OpenCL"
               "-DCMAKE_CXX_COMPILER=${hcc}/bin/hcc"
               "-DCMAKE_C_COMPILER=${clang}/bin/clang"
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
