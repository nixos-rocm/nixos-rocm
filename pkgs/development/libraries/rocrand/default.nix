{ stdenv, fetchFromGitHub, cmake, ed, pkgconfig
, libunwind, git, rocm-cmake, rocminfo, hcc, hip, rocr, comgr
, doCheck ? false
, gtest }:
stdenv.mkDerivation rec {
  name = "rocrand";
  version = "2.10.0";
  src = fetchFromGitHub {
    owner = "ROCmSoftwarePlatform";
    repo = "rocRAND";
    rev = version;
    sha256 = "1kywy7ykwdc0si8yd56iczcy4k4q3km08jj3rr8z66g6gvw11mlw";
  };
  nativeBuildInputs = [ cmake ed git rocm-cmake pkgconfig ];
  buildInputs = [ hcc hip rocminfo libunwind rocr comgr ]
    ++ stdenv.lib.optionals doCheck [ gtest ];

  cmakeFlags = [
    "-DHSA_HEADER=${rocr}/include"
    "-DHSA_LIBRARY=${rocr}/lib/libhsa-runtime64.so"
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
