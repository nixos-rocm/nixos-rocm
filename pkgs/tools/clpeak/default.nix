{ stdenv, fetchFromGitHub, cmake, opencl }:
stdenv.mkDerivation {
  name = "clpeak";
  version = "2019-02-12";
  src = fetchFromGitHub {
    owner = "krrishnarraj";
    repo = "clpeak";
    rev = "652fe4370f656f8c350791ab3cb20ad5ccf9d6cc";
    sha256 = "1fcb58n36jzfsbg2ifchlvx1iw7x4di8m4jp06z3bc3cni30fif7";
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
