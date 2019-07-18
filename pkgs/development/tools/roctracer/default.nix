{stdenv, fetchFromGitHub, cmake, roct, rocr, hcc-unwrapped, hip, python}:
stdenv.mkDerivation rec {
  name = "roctracer";
  version = "2.6.0";
  src = fetchFromGitHub {
    owner = "ROCm-Developer-Tools";
    repo = "roctracer";
    rev = "roc-${version}";
    sha256 = "1pa499rpj8mpswsslf1c13c9man45cr7jkgxsia8rvp321jw45ww";
  };
  src2 = fetchFromGitHub {
    owner = "ROCmSoftwarePlatform";
    repo = "hsa-class";
    rev = "7defb6d9b40d20f6b085be3a5727d1b6bf601d14";
    sha256 = "0wbya4s7wbsxwg39lbz545c19qj17qc80ccs6gw8ypyal6yix6l5";
  };
  nativeBuildInputs = [ cmake python ];
  buildInputs = [ roct rocr hcc-unwrapped hip ];
  preConfigure = ''
    export HCC_HOME=${hcc-unwrapped}
    export HIP_PATH=${hip}
    ln -s ${src2} "test/hsa"
  '';
  patchPhase = ''
    patchShebangs script
    patchShebangs bin
    patchShebangs test
    sed 's|/usr/bin/clang++|clang++|' -i cmake_modules/env.cmake
    sed -e 's|"libhip_hcc.so"|"${hip}/lib/libhip_hcc.so"|' \
        -e 's|"libmcwamp.so"|"${hcc-unwrapped}/lib/libmcwamp.so"|' \
        -i src/core/loader.h
  '';
  postFixup = ''
    patchelf --replace-needed libroctracer64.so.1 $out/roctracer/lib/libroctracer64.so.1 $out/roctracer/tool/libtracer_tool.so
  '';

}
