{ stdenv, fetchFromGitHub, cmake }:
let srcs = {
  utf8cpp = fetchFromGitHub {
    owner = "GPUOpen-Tools";
    repo = "common-lib-ext-utf8cpp";
    rev = "53048f8f7eb69f315a957637d0422845c6652fe5";
    sha256 = "1nmj6l6zdb5v0xp3dshd51kvzsgwb0dcixbx3116zvgq6bk8axbi";
  };
}; in
stdenv.mkDerivation {
  name = "AMDTBaseTools";
  version = "";
  src = fetchFromGitHub {
    owner = "GPUOpen-Tools";
    repo = "common-src-AMDTBaseTools";
    rev = "8ab67ae9ab00cb13d6c9867dbc4fe80bd2776045";
    sha256 = "0w67ip40z5s5kci97xhxcvjrj9l0qsw5hh983g6hpgx2873i8v1i";
  };
  nativeBuildInputs = [ cmake ];
  postUnpack = ''
    ln -s $PWD/$sourceRoot $PWD/$sourceRoot/AMDTBaseTools
    mkdir -p $sourceRoot/Lib/Ext
    ln -s ${srcs.utf8cpp} $sourceRoot/Lib/Ext/utf8cpp
  '';
  patchPhase = ''
    sed -e 's,\(include_directories("''${PROJECT_SOURCE_DIR}\)/../"),\1"),' \
        -e 's,\(add_library(AMDTBaseTools\) STATIC,\1 SHARED,' \
        -i CMakeLists.txt
    echo 'set_target_properties(AMDTBaseTools PROPERTIES PUBLIC_HEADER "Include/AMDTDefinitions.h;Include/gtAlgorithms.h;Include/gtASCIIString.h;Include/gtASCIIStringTokenizer.h;Include/gtAssert.h;Include/gtAutoPtr.h;Include/gtDenseIndexSet.h;Include/gtFlatMap.h;Include/gtFlatSet.h;Include/gtFlatTree.h;Include/gtFragmentedVector.h;Include/gtGRBaseToolsDLLBuild.h;Include/gtHashMap.h;Include/gtHashSet.h;Include/gtIAllocationFailureObserver.h;Include/gtIAssertionFailureHandler.h;Include/gtIgnoreBoostCompilerWarnings.h;Include/gtIgnoreCompilerWarnings.h;Include/gtList.h;Include/gtMap.h;Include/gtPtrVector.h;Include/gtQueue.h;Include/gtRedBlackTree.h;Include/gtSet.h;Include/gtSmallSList.h;Include/gtStack.h;Include/gtStringConstants.h;Include/gtString.h;Include/gtStringTokenizer.h;Include/gtVector.h")' >> CMakeLists.txt
    echo "install(TARGETS AMDTBaseTools LIBRARY DESTINATION $out/lib PUBLIC_HEADER DESTINATION $out/include/AMDTBaseTools/Include)" >> CMakeLists.txt
  '';
  cmakeFlags = [
    "-DCMAKE_CXX_FLAGS=-DAMDT_PUBLIC"
  ];
}
