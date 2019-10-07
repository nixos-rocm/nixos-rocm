{stdenv, fetchFromGitHub, cmake, llvm, lld, clang, device-libs}:
stdenv.mkDerivation rec {
  pname = "comgr";
  version = "2.8.0";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "ROCm-CompilerSupport";
    rev = "roc-${version}";
    sha256 = "13nd1d1i2waxz5byfl46vjqp2b0baaca71jb4z67vg1jdck0849q";
  };
  sourceRoot = "source/lib/comgr";
  nativeBuildInputs = [ cmake ];
  buildInputs = [ llvm lld clang device-libs ];
  
  cmakeFlags = [
    "-DCMAKE_CXX_COMPILER=${clang}/bin/clang++"
    "-DCMAKE_C_COMPILER=${clang}/bin/clang"
    "-DCMAKE_BUILD_TYPE=Release"
    "-DLLVM_TARGETS_TO_BUILD=\"AMDGPU;X86\""
    "-DLLD_INCLUDE_DIRS=${lld.src}/include"
    "-DCMAKE_PREFIX_PATH=${llvm}/lib/cmake/llvm"
    "-DCMAKE_CXX_FLAGS=\"-std=c++17\""
  ];

  # The comgr build tends to link against the static LLVM libraries
  # *and* the dynamic library. Linking against both causes errors
  # about command line options being registered twice. This patch
  # removes the static library linking.
  patchPhase = ''
    sed -e '/^llvm_map_components_to_libnames/,/[[:space:]]*Symbolize)/d' \
        -e 's/CXX_STANDARD 11/CXX_STANDARD 14/' \
        -i CMakeLists.txt
  '';
}
