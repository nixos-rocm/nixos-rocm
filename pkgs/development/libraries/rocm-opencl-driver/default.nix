{ stdenv, fetchFromGitHub, cmake, rocm-llvm, rocm-lld, rocm-clang-unwrapped }:
stdenv.mkDerivation rec {
  name = "rocm-opencl-driver";
  version = "2.8.0";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "ROCm-OpenCL-Driver";
    rev = "roc-${version}";
    sha256 = "0vc2yhyrdyp7jpj4d70k2v44d96ylkwpmj4r7rg49rkxrr5qrdp4";
  };
  nativeBuildInputs = [ cmake ];
  cmakeFlags = [
    "-DLLVM_DIR=${rocm-llvm}/lib/cmake/llvm"
  ];
  enableParallelBuilding = true;
  buildInputs = [ rocm-llvm rocm-lld rocm-clang-unwrapped ];
  patchPhase = ''
    sed -e 's|include(AddLLVM)|include_directories(${rocm-llvm.src}/lib/Target/AMDGPU)|' \
        -e 's|add_subdirectory(src/unittest)||' \
        -i CMakeLists.txt
    sed 's|\(target_link_libraries(roc-cl opencl_driver\))|find_package(Clang CONFIG REQUIRED)\n\1 lldELF lldCommon clangCodeGen clangFrontend)|' -i src/roc-cl/CMakeLists.txt
  '';
}
