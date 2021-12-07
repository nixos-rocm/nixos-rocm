{ stdenv, lib, fetchFromGitHub, fetchpatch, cmake, perl, python, writeText
, file, binutils-unwrapped, libxml2, numactl, bash, symlinkJoin, # libGL,
  libX11, libglvnd
, llvm, clang, clang-unwrapped, lld, compiler-rt
, rocm-device-libs, rocm-thunk, rocm-runtime, rocminfo, comgr, rocclr
, rocm-opencl-runtime
, makeWrapper
}:
stdenv.mkDerivation rec {
  name = "hip";
  version = "4.5.0";
  hip = fetchFromGitHub {
    owner = "ROCm-Developer-Tools";
    repo = "HIP";
    rev = "rocm-${version}";
    hash = "sha256-AuA5ubRPywXaBBrjdHg5AT8rrVKULKog6Lh8jPaUcXY=";
  };
  src = fetchFromGitHub {
    owner = "ROCm-Developer-Tools";
    repo = "hipamd";
    rev = "rocm-${version}";
    hash = "sha256-p/rvrlX6PuLwhd6Otfz8RpY25Fe/CRwcI0LRHCQwc6c=";
  };

  nativeBuildInputs = [ cmake python makeWrapper ];
  buildInputs = [ libxml2 numactl libglvnd libX11 ];
  propagatedBuildInputs = [ llvm clang compiler-rt lld rocm-thunk rocminfo rocm-device-libs rocm-runtime comgr ];

  preConfigure = ''
    echo "pwd = $PWD"
    echo "sourceRoot = $sourceRoot"
    export HIP_CLANG_PATH=${clang}/bin
    export DEVICE_LIB_PATH=${rocm-device-libs}/lib
    export HIPAMD_DIR="${src}"
    export HIP_DIR="$(readlink -f hip)"
    export ROCclr_DIR="${rocclr.src}"
    echo "HIP_DIR = ''${HIP_DIR}"
  '';

  # The patch version is the last two digits of year + week number +
  # day in the week: date -d "2021-10-11" +%y%U%w
  workweek = "21411";

  opencl-deps = symlinkJoin {
    name = "HIP-OpenCL-Deps";
    paths = [
      # amdocl headers
      rocm-opencl-runtime.src
      "${rocm-opencl-runtime.src}/amdocl"

      # icd headers
      "${rocm-opencl-runtime.src}/khronos"

      # CL headers
      "${rocm-opencl-runtime}/include"
    ];
  };

  cmakeFlags = [
    "-DHSA_PATH=${rocm-runtime}"
    "-DHIP_COMPILER=clang"
    "-DHIP_PLATFORM=amd"
    "-DHIP_VERSION_GITDATE=${workweek}"
    "-DCMAKE_C_COMPILER=${clang}/bin/clang"
    "-DCMAKE_CXX_COMPILER=${clang}/bin/clang++"
    "-DLLVM_ENABLE_RTTI=ON"
    # "-DLIBROCclr_STATIC_DIR=${rocclr}/lib/cmake"
    "-DROCCLR_PATH=${rocclr.src}"
    "-DHIP_CLANG_ROOT=${clang-unwrapped}"
    "-DPERL_EXECUTABLE=${perl}/bin/perl"
    "-DAMD_OPENCL_INCLUDE_DIR=${opencl-deps}"
  ];

  prePatch = ''
    mkdir hip
    cp -R ${hip}/* hip/
    chmod -R u+w hip
    export ROCM_NIX_BASH=${lib.getBin bash}/bin/bash
    for f in $(find hip/bin -type f); do
      sed -e 's,#!/usr/bin/perl,#!${perl}/bin/perl,' \
          -e 's,#!/usr/bin/env perl,#!${perl}/bin/perl,' \
          -i "$f"
    done
    patchShebangs hip/bin

    substituteInPlace CMakeLists.txt \
      --replace "project(hip)" "project(hip)
set(HIP_COMMON_DIR \$ENV{HIP_DIR})"

    substituteInPlace hip/bin/hip_embed_pch.sh --replace "\$LLVM_DIR/bin/" ""

    substituteInPlace hip/hip_prof_gen.py --replace '#!/usr/bin/python' '#!${python}/bin/python'

    substituteInPlace hip/bin/hipcc \
      --replace '$ROCM_PATH      =   $hipvars::ROCM_PATH;' \
                "\$ROCM_PATH      =   \"$out\";" \
      --replace '$HIP_CLANG_PATH =   $hipvars::HIP_CLANG_PATH;' \
                '$HIP_CLANG_PATH =   "${clang}/bin";' \

    sed -e 's,$ROCM_AGENT_ENUM = "''${ROCM_PATH}/bin/rocm_agent_enumerator";,$ROCM_AGENT_ENUM = "${rocminfo}/bin/rocm_agent_enumerator";,' \
        -e "s,^\($HIP_LIB_PATH=\).*$,\1\"$out/lib\";," \
        -e 's,^\($DEVICE_LIB_PATH=\).*$,\1"${rocm-device-libs}/amdgcn/bitcode";,' \
        -e 's,^\($HIP_COMPILER=\).*$,\1"clang";,' \
        -e 's,^\($HIP_RUNTIME=\).*$,\1"ROCclr";,' \
        -e 's,^\([[:space:]]*$HSA_PATH=\).*$,\1"${rocm-runtime}";,'g \
        -e 's,^\([[:space:]]*\)$HIP_CLANG_INCLUDE_PATH = abs_path("$HIP_CLANG_PATH/../lib/clang/$HIP_CLANG_VERSION/include");,\1$HIP_CLANG_INCLUDE_PATH = "${clang-unwrapped}/lib/clang/$HIP_CLANG_VERSION/include";,' \
        -e 's,^\([[:space:]]*$HIPCXXFLAGS .= " -isystem \\"$HIP_CLANG_INCLUDE_PATH/..\\"\)";,\1 -isystem ${rocm-runtime}/include";,' \
        -e "s,^\$HIP_LIB_PATH=\$ENV{'HIP_LIB_PATH'};,\$HIP_LIB_PATH=\"$out/lib\";," \
        -e 's,`file,`${file}/bin/file,g' \
        -e 's,`readelf,`${binutils-unwrapped}/bin/readelf,' \
        -e 's, ar , ${binutils-unwrapped}/bin/ar ,g' \
        -i hip/bin/hipcc

    sed -e 's,^\($HSA_PATH=\).*$,\1"${rocm-runtime}";,' \
        -e 's,^\($HIP_CLANG_PATH=\).*$,\1"${clang}/bin";,' \
        -e 's,^\($HIP_PLATFORM=\).*$,\1"amd";,' \
        -e 's,$HIP_CLANG_PATH/llc,${llvm}/bin/llc,' \
        -e 's, abs_path, Cwd::abs_path,' \
        -i hip/bin/hipconfig

    sed -e 's, abs_path, Cwd::abs_path,' -i hip/bin/hipvars.pm
  '';

  preInstall = ''
    mkdir -p $out/lib/cmake
  '';

  # The upstream ROCclr setup wants everything built into the same
  # ROCclr output directory. We copy things into the HIP output
  # directory, since it is downstream of ROCclr in terms of dependency
  # direction. Thus we have device-libs and rocclr pieces in the HIP
  # output directory.
  postInstall = ''
    mkdir -p $out/share
    mv $out/lib/cmake $out/share/
    mv $out/cmake/* $out/share/cmake/hip
    mkdir -p $out/lib
    ln -s ${rocm-device-libs}/lib $out/lib/bitcode
    mkdir -p $out/include
    ln -s ${clang-unwrapped}/lib/clang/11.0.0/include $out/include/clang
    wrapProgram $out/bin/hipcc --set HIP_PATH $out --set HSA_PATH ${rocm-runtime} --set HIP_CLANG_PATH ${clang}/bin --prefix PATH : ${lld}/bin --set NIX_CC_WRAPPER_TARGET_HOST_${stdenv.cc.suffixSalt} 1 --prefix NIX_LDFLAGS ' ' -L${compiler-rt}/lib --prefix NIX_LDFLAGS_FOR_TARGET ' ' -L${compiler-rt}/lib --add-flags "-nogpuinc"
    wrapProgram $out/bin/hipconfig --set HIP_PATH $out --set HSA_PATH ${rocm-runtime} --set HIP_CLANG_PATH ${clang}/bin
  '';

  # setupHook = writeText "setupHook.sh" ''
  #   export HIP_PATH="@out@"
  #   export HSA_PATH="${rocm-runtime}"
  #   export HIP_CLANG_PATH=${clang}/bin
  # '';
}
