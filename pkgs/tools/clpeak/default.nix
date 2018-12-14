{ stdenv, fetchFromGitHub, cmake, opencl }:
stdenv.mkDerivation {
  name = "clpeak";
  version = "2018-11-23";
  src = fetchFromGitHub {
    owner = "krrishnarraj";
    repo = "clpeak";
    rev = "2b3d89c1cdede64042ef87703f99be58f5ca92ae";
    sha256 = "1fici1ffaagdvn74vlb2y9ymhqbgqvsczbdfjcd5aqjhqmazizx7";
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
