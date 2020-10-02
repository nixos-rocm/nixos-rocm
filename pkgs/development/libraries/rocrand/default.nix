{ stdenv, lib, fetchFromGitHub, cmake, config, ed, pkgconfig
, libunwind, git, rocm-cmake, rocminfo, hip, rocm-runtime, comgr
, doCheck ? false, gtest ? null 
}:

assert doCheck -> gtest != null;

stdenv.mkDerivation rec {
  name = "rocrand";
  version = "3.8.0";
  src = fetchFromGitHub {
    owner = "ROCmSoftwarePlatform";
    repo = "rocRAND";
    rev = "rocm-${version}";
    sha256 = "0qzscqjflcq0h60y36rp0x2vlih7lakacn1f0nkwkagny19lkys2";
  };
  
  nativeBuildInputs = [ cmake ed git rocm-cmake pkgconfig ];

  buildInputs = [ hip rocminfo libunwind rocm-runtime comgr ];
  
  checkInputs = [ gtest ];

  cmakeFlags = [
    "-DHSA_HEADER=${rocm-runtime}/include"
    "-DHSA_LIBRARY=${rocm-runtime}/lib/libhsa-runtime64.so"
    "-DHIP_PLATFORM=rocclr"
    "-DHIP_PATH=${hip}"
    "-DCMAKE_CXX_COMPILER=${hip}/bin/hipcc"
    "-DCMAKE_INSTALL_INCLUDEDIR=include"
    "-DAMDGPU_TARGETS=${lib.strings.concatStringsSep ";" (config.rocmTargets or [ "gfx803" "gfx900" "gfx906" ])}"
  ] ++ (let flag = if doCheck then "ON" else "OFF";
        in [ "-DBUILD_TEST=${flag} -DBUILD_BENCHMARK=${flag}" ]);
        
  postInstall = ''
    mkdir -p $out/include $out/lib
    cp -rs $out/hiprand/include/* $out/include
    cp -rs $out/rocrand/include/* $out/include
    cp -rs $out/hiprand/lib/* $out/lib
    cp -rs $out/rocrand/lib/* $out/lib
    for f in $(find $out/lib/cmake -name '*.cmake'); do
      sed -e "s,get_filename_component(PACKAGE_PREFIX_DIR .*,set(PACKAGE_PREFIX_DIR \"$out\")," \
          -e "s,get_filename_component(_IMPORT_PREFIX .*,set(_IMPORT_PREFIX \"$out\")," \
          -i ''${f}
    done
  '';
}
