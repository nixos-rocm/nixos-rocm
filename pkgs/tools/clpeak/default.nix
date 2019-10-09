{ stdenv, fetchFromGitHub, cmake, opencl }:
stdenv.mkDerivation {
  name = "clpeak";
  version = "2019-08-24";
  src = fetchFromGitHub {
    owner = "krrishnarraj";
    repo = "clpeak";
    rev = "8e18c59bfbbeee0eb2005f882cd3bb5ad4cf6107";
    sha256 = "0kvca1hp7b8ac429gs6wqji0x4i9lnixjbn275pl8b9zxnis9lp1";
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
