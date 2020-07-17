{ stdenv, fetchFromGitHub, cmake, ed, pkgconfig
, libunwind, git, rocm-cmake, rocminfo, hcc, hip, rocm-runtime, comgr
, doCheck ? false
, gtest }:
stdenv.mkDerivation rec {
  name = "rocrand";
  version = "3.3.0";
  src = fetchFromGitHub {
    owner = "ROCmSoftwarePlatform";
    repo = "rocRAND";
    rev = "rocm-${version}";
    sha256 = "0nbrzpjp87v6p91jzxgxr12q2zzqw33m6cmwhckwiv8c076cfkgy";
  };
  nativeBuildInputs = [ cmake ed git rocm-cmake pkgconfig ];
  buildInputs = [ hcc hip rocminfo libunwind rocm-runtime comgr ]
    ++ stdenv.lib.optionals doCheck [ gtest ];

  cmakeFlags = [
    "-DHSA_HEADER=${rocm-runtime}/include"
    "-DHSA_LIBRARY=${rocm-runtime}/lib/libhsa-runtime64.so"
    "-DHIP_PLATFORM=hcc"
    "-DHIP_PATH=${hip}"
    "-DCMAKE_CXX_COMPILER=${hip}/bin/hipcc"
    "-DCMAKE_INSTALL_INCLUDEDIR=include"
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
