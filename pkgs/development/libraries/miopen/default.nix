{ stdenv, fetchFromGitHub, cmake, pkgconfig, half, openssl, boost, sqlite, bzip2
, rocm-cmake, rocm-opencl-runtime, rocm-runtime, clang, clang-unwrapped, clang-ocl, miopengemm, rocblas
, comgr, useHip ? false, hip }:
assert useHip -> hip != null;
stdenv.mkDerivation rec {
  name = "miopen";
  version = "2.4.0";
  src = fetchFromGitHub {
    owner = "ROCmSoftwarePlatform";
    repo = "MIOpen";
    rev = "${version}";
    sha256 = "1qs4zxqza4bg1055fnbyhrvyskbg8f4nc6adlrn6yqq2xin50jsz";
  };
  nativeBuildInputs = [ cmake pkgconfig rocm-cmake ];
  buildInputs = [ rocm-runtime half openssl boost rocblas miopengemm comgr sqlite bzip2 ]
    ++ (if useHip then [ hip ] else [rocm-opencl-runtime clang-ocl hip]);

  cmakeFlags = [
    "-DCMAKE_PREFIX_PATH=${hip};${clang-ocl}"
    "-DCMAKE_INSTALL_INCLUDEDIR=include"
    "-DMIOPEN_USE_ROCBLAS=ON"
    "-DBoost_USE_STATIC_LIBS=OFF"
    "-DMIOPEN_USE_MIOPENGEMM=ON"
    "-DMIOPEN_AMDGCN_ASSEMBLER_PATH=${clang}/bin"
    "-DMIOPEN_OFFLOADBUNDLER_BIN=${clang-unwrapped}/bin/clang-offload-bundler"
  ] ++ (if useHip
        then [ # "-DCMAKE_CXX_COMPILER=${clang}/bin/clang++"
               # "-DCMAKE_C_COMPILER=${clang}/bin/clang"
               "-DCMAKE_CXX_COMPILER=${hip}/bin/hipcc"
               "-DCMAKE_C_COMPILER=${hip}/bin/hipcc"
               "-DMIOPEN_BACKEND=HIP"
               # "-DENABLE_HIP_WORKAROUNDS=YES"
        ]
        else [ "-DMIOPEN_BACKEND=OpenCL"
               "-DCMAKE_CXX_COMPILER=${clang}/bin/clang++"
               "-DCMAKE_C_COMPILER=${clang}/bin/clang"
               # "-DOPENCL_INCLUDE_DIRS=${rocm-opencl-runtime}/include/opencl2.2"
               # "-DOPENCL_LIB_DIRS=${rocm-opencl-runtime}/lib"
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
    sed 's/std::move(SQLite{filename_, is_system})/SQLite{filename_, is_system}/' -i src/include/miopen/sqlite_db.hpp
    for f in src/CMakeLists.txt addkernels/CMakeLists.txt; do
      sed '/^[[:space:]]*clang_tidy_check(.*/d' -i "$f"
    done
    sed '/add_dependencies(tidy miopen_tidy_inlining)/d' -i src/CMakeLists.txt
    sed -e 's/clang_tidy_check.*//' \
        -i speedtests/CMakeLists.txt
  '';
}
