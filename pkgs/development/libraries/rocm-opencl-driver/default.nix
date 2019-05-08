{ stdenv, fetchFromGitHub, cmake, rocm-llvm, rocm-lld, rocm-clang-unwrapped }:
stdenv.mkDerivation rec {
  name = "rocm-opencl-driver";
  version = "2.4.0";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "ROCm-OpenCL-Driver";
    rev = "roc-${version}";
    sha256 = "08jhngvfpmzhsyyvhnpqf6j48j8ql9yvpfnf27js8c89p7b64vfz";
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
