{ stdenv, fetchFromGitHub, cmake, ed, pkgconfig
, libunwind, git, rocm-cmake, rocminfo, hcc, hip, rocr, comgr
, doCheck ? false
, gtest }:
stdenv.mkDerivation rec {
  name = "rocrand";
  version = "2.7";
  src = fetchFromGitHub {
    owner = "ROCmSoftwarePlatform";
    repo = "rocRAND";
    rev = "rocm-${version}";
    sha256 = "10m3gpv9fp5g739c54hqrhlal2kzzwvny6ah2ih6zr2rj3a3shbc";
  };
  nativeBuildInputs = [ cmake ed git rocm-cmake pkgconfig ];
  buildInputs = [ hcc hip rocminfo libunwind rocr comgr ]
    ++ stdenv.lib.optionals doCheck [ gtest ];

  # We first move the `project` command to before we `include` another
  # cmake file that looks for libraries. Then, cmake runs into
  # problems if including hcc and hip config files as they have
  # unguarded add_library calls, so we define HSA_HEADER and
  # HSA_LIBRARY ourselves.
#    printf '%s\n' 15m20 20-m15- w q | ed -s CMakeLists.txt
  # preConfigure = ''
  #   sed '/include(cmake\/SetToolchain.cmake)/d' -i CMakeLists.txt
  #   sed 's,project(rocRAND CXX),project(rocRAND CXX)\ninclude(cmake/SetToolchain.cmake),' -i CMakeLists.txt
  #   sed -e '/^[[:space:]]*find_package(hcc REQUIRED CONFIG PATHS .*$/ d' \
  #       -e '/^[[:space:]]*find_package(hip REQUIRED CONFIG PATHS .*$/ d' \
  #       -i cmake/Dependencies.cmake
  # '';
  # patchPhase = ''
  #   sed -e "s,\(set(INCLUDE_INSTALL_DIR \).*,\1\"$out/rocrand/include\")," \
  #       -e "s,\(set(LIB_INSTALL_DIR \).*,\1\"$out/rocrand/lib\")," \
  #       -i library/CMakeLists.txt
  # '';
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
