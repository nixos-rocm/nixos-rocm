{ stdenv
, llvmPackages
, fetchFromGitHub
, cmake
, rocr
, ocl-icd
, mesa_noglu
, python2
, libX11
}:

llvmPackages.stdenv.mkDerivation rec {
  version = "1.7.0";
  tag = "roc-${version}";
  name = "rocm-opencl-runtime-${version}";
  srcs =
    [ (fetchFromGitHub {
        owner = "RadeonOpenCompute";
        repo = "ROCm-OpenCL-Runtime";
        rev = "${tag}";
        sha256 = "01qzh6sfl5k45phaa64n0jimx4d64nsfraql49nkdqkvd2l6js6q";
        name = "ROCm-OpenCL-Runtime-${tag}-src";
      })
      (fetchFromGitHub {
        owner = "RadeonOpenCompute";
        repo = "ROCm-OpenCL-Driver";
        rev = "${tag}";
        sha256 = "1pvwsznlxzrkxjsfn4bk2l021dprhb5r3wg8yfs05nryj2svzzzy";
        name = "ROCm-OpenCL-Driver-${tag}-src";
      })
      (fetchFromGitHub {
        owner = "RadeonOpenCompute";
        repo = "clang";
        rev = "${tag}";
        sha256 = "0yz6krsij9cb92906hd8icsy1qs4bvb0822k9i95ry1728vpnffj";
        name = "clang-${tag}-src";
      })
      (fetchFromGitHub {
        owner = "RadeonOpenCompute";
        repo = "llvm";
        rev = "${tag}";
        sha256 = "19g4idzrx4cwkl6yw0yynvg6vsh5m4cj0a6aqiqss4rd1calig4n";
        name = "llvm-${tag}-src";
      })
      (fetchFromGitHub {
        owner = "RadeonOpenCompute";
        repo = "lld";
        rev = "${tag}";
        sha256 = "0b8nv8j32q5r0arx08i8l2k8hkz6jn38qn2wn5k4mlfzfwpls4dv";
        name = "lld-${tag}-src";
      })
      (fetchFromGitHub {
        owner = "RadeonOpenCompute";
        repo = "ROCm-Device-Libs";
        rev = "${tag}";
        sha256 = "0wf2y9i47ykmp13r567i7cp6a00c2if78sgxrznvn4xvrzdk6hsj";
        name = "ROCm-Device-Libs-${tag}-src";
      })
      (fetchFromGitHub {
        owner = "KhronosGroup";
        repo = "OpenCL-ICD-Loader";
        rev = "26a3898";
        sha256 = "148n8wzf6kp7vjhk6qz5mg4wmrysy8g5z4qmcn8imjgqiinhl05n";
        name = "OpenCL-ICD-Loader-26a3898-src";
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
    mv OpenCL-ICD-Loader-26a3898-src ROCm-OpenCL-Runtime-${tag}-src/api/opencl/khronos/icd
  '';

  patchPhase = ''
    sed -e 's/enable_testing()//' \
        -e 's@add_subdirectory(src/unittest)@@' \
        -i compiler/driver/CMakeLists.txt
  '';

  enableParallelBuilding = true;
  buildInputs = [ cmake rocr ocl-icd mesa_noglu python2 libX11 ];

  #cmakeBuildType = "Debug";
  dontStrip = true;

  preFixup = ''
    patchelf --set-rpath "${stdenv.lib.makeLibraryPath buildInputs}" $out/bin/clinfo
  '';
}
