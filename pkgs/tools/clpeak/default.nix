{ stdenv, fetchFromGitHub, cmake, opencl }:
stdenv.mkDerivation {
  name = "clpeak";
  version = "2019-10-20";
  src = fetchFromGitHub {
    owner = "krrishnarraj";
    repo = "clpeak";
    rev = "e1fc83281f8c0f540477650ab5121fe183b369b4";
    sha256 = "1fcll33x6n911h7w30i7rvmknl1n41j7xx1728xjss22gmssbinc";
  };
  nativeBuildInputs = [ cmake ];
  buildInputs = [ opencl ];
  patchPhase = ''
    sed -e '/^find_path( OPENCL_INCLUDES/,/^[[:space:]]*)/d' \
        -e '/^if(BITNESS EQUAL 64)/,/^endif()/d' \
        -e '/^if( (NOT OPENCL_INCLUDES) OR (NOT OPENCL_LIBS) )/,/^endif()/d' \
        -e 's/''${OPENCL_INCLUDES}//' \
        -e 's/''${OPENCL_LIBS}/OpenCL/' \
        -i CMakeLists.txt
    sed 's/strlen(stringifiedKernels)+1/strlen(stringifiedKernels)/g' -i src/clpeak.cpp
  '';
  installPhase = ''
    mkdir -p $out/bin
    mv clpeak $out/bin
  '';
}
