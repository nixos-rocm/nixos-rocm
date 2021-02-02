{stdenv, lib, fetchFromGitHub, cmake, rocm-thunk, rocm-runtime, hcc-unwrapped, hip
, python, buildPythonPackage, fetchPypi, ply}:
let
  CppHeaderParser = buildPythonPackage rec {
    pname = "CppHeaderParser";
    version = "2.7.4";

    src = fetchPypi {
      inherit pname version;
      sha256 = "0hncwd9y5ayk8wa6bqhp551mcamcvh84h89ba3labc4mdm0k0arq";
    };

    doCheck = false;
    propagatedBuildInputs = [ ply ];

    meta = with lib; {
      homepage = http://senexcanis.com/open-source/cppheaderparser/;
      description = "Parse C++ header files and generate a data structure representing the class";
      license = licenses.bsd3;
      maintainers = [];
    };
  };
  pyenv = python.withPackages (ps: [CppHeaderParser]);
in stdenv.mkDerivation rec {
  name = "roctracer";
  version = "3.3.0";
  src = fetchFromGitHub {
    owner = "ROCm-Developer-Tools";
    repo = "roctracer";
    rev = "roc-${version}";
    sha256 = "00iwah3x1cm5ghhrwcp0njiy5vvwnh4wcpcfs8k6zacn9fd2dh8l";
  };
  src2 = fetchFromGitHub {
    owner = "ROCmSoftwarePlatform";
    repo = "hsa-class";
    rev = "7defb6d9b40d20f6b085be3a5727d1b6bf601d14";
    sha256 = "0wbya4s7wbsxwg39lbz545c19qj17qc80ccs6gw8ypyal6yix6l5";
  };
  nativeBuildInputs = [ cmake pyenv ];
  buildInputs = [ rocm-thunk rocm-runtime hcc-unwrapped hip ];
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
    ln -s $out/roctracer/include/* $out/include
  '';

}
