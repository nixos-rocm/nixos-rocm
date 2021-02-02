{ stdenv, lib, fetchFromGitHub, cmake, perl, python, writeText
, hcc, hcc-unwrapped, rocm-runtime, rocminfo, comgr
, file, binutils-unwrapped }:
stdenv.mkDerivation rec {
  name = "hip";
  version = "3.3.0";
  src = fetchFromGitHub {
    owner = "ROCm-Developer-Tools";
    repo = "HIP";
    rev = "rocm-${version}";
    sha256 = "038qb1ammhg0di32pvbb9j1yq0mxrpd9iyhy159x9gk1vjm1rvxc";
  };
  nativeBuildInputs = [ cmake python ];
  buildInputs = [ hcc comgr ];

  # The patch version is the last two digits of year + week number +
  # day in the week: date -d "2020-03-28" +%y%U%w
  workweek = "20126";

  cmakeFlags = [
    "-DHSA_PATH=${rocm-runtime}"
    "-DHCC_HOME=${hcc}"
    "-DHIP_PLATFORM='hcc'"
    "-DHIP_VERSION_GITDATE=${workweek}"
    "-DCMAKE_C_COMPILER=${hcc}/bin/clang"
    "-DCMAKE_CXX_COMPILER=${hcc}/bin/clang++"
    "-DCMAKE_BUILD_TYPE=Release"
  ];

  # - fix bash paths
  # - fix path to rocm_agent_enumerator
  # - fix hcc path
  # - fix hcc version parsing
  postPatch = ''
    for f in $(find bin -type f); do
      sed -e 's,#!/usr/bin/perl,#!${perl}/bin/perl,' \
          -e 's,#!/bin/bash,#!${stdenv.shell},' \
          -i "$f"
    done

    for f in $(find . -regex '.*\.cpp\|.*\.h\(pp\)?'); do
      if grep -q __hcc_workweek__ "$f" ; then
        substituteInPlace "$f" --replace '__hcc_workweek__' '${workweek}'
      fi
    done

    sed 's,#!/usr/bin/python,#!${python}/bin/python,' -i hip_prof_gen.py

    sed -e 's,$ROCM_AGENT_ENUM = "''${ROCM_PATH}/bin/rocm_agent_enumerator";,$ROCM_AGENT_ENUM = "${rocminfo}/bin/rocm_agent_enumerator";,' \
        -e 's,^\([[:space:]]*$HSA_PATH=\).*$,\1"${rocm-runtime}";,' \
        -e 's,^\([[:space:]]*$HCC_HOME=\).*$,\1"${hcc}";,' \
        -e 's,\([[:space:]]*$HOST_OSNAME=\).*,\1"nixos";,' \
        -e 's,\([[:space:]]*$HOST_OSVER=\).*,\1"${lib.versions.majorMinor lib.version}";,' \
        -e "s,\$HIP_PATH/\(bin\|lib\),$out/\1,g" \
        -e "s,^\$HIP_LIB_PATH=\$ENV{'HIP_LIB_PATH'};,\$HIP_LIB_PATH=\"$out/lib\";," \
        -e 's,`file,`${file}/bin/file,g' \
        -e 's,`readelf,`${binutils-unwrapped}/bin/readelf,' \
        -e 's, ar , ${binutils-unwrapped}/bin/ar ,g' \
        -i bin/hipcc
    sed -i 's,\([[:space:]]*$HCC_HOME=\).*$,\1"${hcc}";,' -i bin/hipconfig

    sed -e '/execute_process(COMMAND git show -s --format=@%ct/,/    OUTPUT_STRIP_TRAILING_WHITESPACE)/d' \
        -i CMakeLists.txt
  '';

  postInstall = ''
    mkdir -p $out/share
    mv $out/lib/cmake $out/share/
  '';

  setupHook = writeText "setupHook.sh" ''
    export HIP_PATH="@out@"
  '';
}
