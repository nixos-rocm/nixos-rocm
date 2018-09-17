{ stdenv
, llvmPackages
, fetchFromGitHub
, libGL_driver
, cmake
, rocr
, mesa_noglu
, python2
, libX11
}:

llvmPackages.stdenv.mkDerivation rec {
  version = "1.9.0";
  tag = "roc-${version}";
  name = "rocm-opencl-runtime-${version}";
  srcs =
    [ (fetchFromGitHub {
        owner = "RadeonOpenCompute";
        repo = "ROCm-OpenCL-Runtime";
        rev = "870b8175b2906d229f7a43e01b0038b0c8e5bb30";
        sha256 = "09sg9l0vp01dw6fn62ci8n3fgn5m02h6clbzqs9whd4ixjyqfs9a";
        name = "ROCm-OpenCL-Runtime-${tag}-src";
      })
      (fetchFromGitHub {
        owner = "RadeonOpenCompute";
        repo = "ROCm-OpenCL-Driver";
        # rev = "${tag}";
        rev = "a3d4fa91d7d625c28247af9f1e909a7d7b51097a";
        sha256 = "0vf254n2sr37lhy7n2c1vdsvijikrjbh44q7df6g0g0z6m96ls10";
        name = "ROCm-OpenCL-Driver-${tag}-src";
      })
      (fetchFromGitHub {
        owner = "RadeonOpenCompute";
        repo = "hcc-clang-upgrade";

        # The 1.9.x branch does not build
        # rev = "e2b51bfd063e4ccd426b64290bdc1587f2bf855a";
        # sha256 = "09q2rms0xy411a7df9p1a2vs1azhk9j324dk13qb76gy79hmzwls";

        # This is newer than 1.9, but does build
        rev = "3752e4af872ddbcddb2ede7a0c6dae3aef4f07a0";
        sha256 = "0lcwmd1srg394hgnv7pl7yhs2c174gnma5131rh95mirghwwc3r0";
        name = "clang-${tag}-src";
      })
      (fetchFromGitHub {
        owner = "RadeonOpenCompute";
        repo = "llvm";
        rev = "90d556e2f760c0b01c662b0f88e74b55944923b4";
        sha256 = "0h93rvfi3bpd9bw5vyy3pbnld0m6c3pz03vwc13np44wn9zyqrxk";
        name = "llvm-${tag}-src";
      })
      (fetchFromGitHub {
        owner = "RadeonOpenCompute";
        repo = "lld";
        # rev = "${tag}";
        rev = "e20dff7f5137e5a89675aa36a77a9a0c86366fd4";
        sha256 = "1n2f7fga3fri1c3hscvvsaxkxvpmw2h0qyglf8yrybyzh6z91075";
        name = "lld-${tag}-src";
      })
      (fetchFromGitHub {
        owner = "RadeonOpenCompute";
        repo = "ROCm-Device-Libs";
        rev = "19dcce7b550db6892d9bc88adb25b4c8d91ea407";
        sha256 = "0k3gl1j4wghw0hr427xayq3c65abja84y62y7w7rm4jmxn4lsz4s";
        name = "ROCm-Device-Libs-${tag}-src";
      })
      (fetchFromGitHub {
        owner = "KhronosGroup";
        repo = "OpenCL-ICD-Loader";
        rev = "b342ff7b7f70a4b3f2cfc53215af8fa20adc3d86";
        sha256 = "104l33xxras1cadn6xxkas8dl2ss6wi4dlqjqh103ww83g95108x";
        name = "OpenCL-ICD-Loader-b342ff7-src";
      })
    ];

  sourceRoot = "ROCm-OpenCL-Runtime-${tag}-src";

  postUnpack = ''
    chmod --recursive +w .
    mv ROCm-OpenCL-Driver-${tag}-src ROCm-OpenCL-Runtime-${tag}-src/compiler/driver
    mv llvm-${tag}-src ROCm-OpenCL-Runtime-${tag}-src/compiler/llvm
    mv clang-${tag}-src ROCm-OpenCL-Runtime-${tag}-src/compiler/llvm/tools/clang
    mv lld-${tag}-src ROCm-OpenCL-Runtime-${tag}-src/compiler/llvm/tools/lld
    mkdir ROCm-OpenCL-Runtime-${tag}-src/library/
    mv ROCm-Device-Libs-${tag}-src ROCm-OpenCL-Runtime-${tag}-src/library/amdgcn
    mv OpenCL-ICD-Loader-b342ff7-src ROCm-OpenCL-Runtime-${tag}-src/api/opencl/khronos/icd
  '';

  patchPhase = ''
    sed -e 's/enable_testing()//' \
        -e 's@add_subdirectory(src/unittest)@@' \
        -i compiler/driver/CMakeLists.txt
    sed 's,"/etc/OpenCL/vendors/","${libGL_driver.driverLink}/etc/OpenCL/vendors/",g' -i api/opencl/khronos/icd/icd_linux.c
  '';

  enableParallelBuilding = true;
  buildInputs = [ cmake rocr mesa_noglu python2 libX11 ];

  #cmakeBuildType = "Debug";
  dontStrip = true;

  preFixup = ''
    patchelf --set-rpath "$out/lib" $out/bin/clinfo
    ln -s $out/lib/libOpenCL.so.1.2 $out/lib/libOpenCL.so.1
    ln -s $out/lib/libOpenCL.so.1 $out/lib/libOpenCL.so
  '';
}
