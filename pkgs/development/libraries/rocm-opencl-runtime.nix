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
  version = "1.8.0";
  tag = "roc-${version}";
  name = "rocm-opencl-runtime-${version}";
  srcs =
    [ (fetchFromGitHub {
        owner = "RadeonOpenCompute";
        repo = "ROCm-OpenCL-Runtime";
        # rev = "${tag}";
        rev = "15fb9b06ecfb8fd87df2578657a49b0a56886245";
        sha256 = "1mz0jy38lrdha95hdpfb9g4fg9mb0hb6vkpii0x2mabvqi8sa73c";
        name = "ROCm-OpenCL-Runtime-${tag}-src";
      })
      (fetchFromGitHub {
        owner = "RadeonOpenCompute";
        repo = "ROCm-OpenCL-Driver";
        # rev = "${tag}";
        rev = "e0fd00a97a541f5455d583fd5274a9d335165b5e";
        sha256 = "12lvwpdhv6p82mm7cqnxfgcpd3ddlpa0xb3s1r24ziyfc8qrpayi";
        name = "ROCm-OpenCL-Driver-${tag}-src";
      })
      (fetchFromGitHub {
        owner = "RadeonOpenCompute";
        repo = "clang";
        # rev = "${tag}";
        rev = "daee96b5f4ce15e9c89158c27328000a1a13667a";
        sha256 = "1dwrjp5qr64p633gpc0q0k9p2mc0ydjjm13ggxvllnf0gyy88xz7";
        name = "clang-${tag}-src";
      })
      (fetchFromGitHub {
        owner = "RadeonOpenCompute";
        repo = "llvm";
        # rev = "${tag}";
        rev = "ccb913df333e220dd05420918d5755040729707b";
        sha256 = "1ymd5pkx8h55zg5s7x74shn07fbl9x7a3kc6rq1s9caj41bn77gn";
        name = "llvm-${tag}-src";
      })
      (fetchFromGitHub {
        owner = "RadeonOpenCompute";
        repo = "lld";
        # rev = "${tag}";
        rev = "d18b96ee6ceb4398fc09e8676fe87ad33f5fcd3c";
        sha256 = "1r1nlk1qhmrf0563x4aqrjjpxhr7dspmar8q411rnril4djwbjz2";
        name = "lld-${tag}-src";
      })
      (fetchFromGitHub {
        owner = "RadeonOpenCompute";
        repo = "ROCm-Device-Libs";
        # rev = "${tag}";
        rev = "c0acc0acf1c9852dd6a7313dfe060dee90e2b816";
        sha256 = "1cm493zs86nn9d51mhacrjpkjl3xc7s466m6g3b639nl5qkqvlwq";
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
    sed 's,amdgcn--amdhsa-amdgizcl,amdgcn-amd-amdhsa-amdgizcl,' -i library/amdgcn/CMakeLists.txt
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
