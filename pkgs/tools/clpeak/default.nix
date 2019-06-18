{ stdenv, fetchFromGitHub, cmake, opencl }:
stdenv.mkDerivation {
  name = "clpeak";
  version = "2019-05-04";
  src = fetchFromGitHub {
    owner = "krrishnarraj";
    repo = "clpeak";
    rev = "15330946a225b1f083ea042ee8db2722e962b3d2";
    sha256 = "0xkkqashqsdaj24yndpi4xqkzmb0xhdbyhg7a35r4amfwjj4g5m7";
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
