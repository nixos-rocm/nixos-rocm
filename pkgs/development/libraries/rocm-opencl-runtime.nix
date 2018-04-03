{ stdenv
, llvmPackages
, fetchFromGitHub
, libGL
, cmake
, rocr
, mesa_noglu
, python2
, libX11
}:

llvmPackages.stdenv.mkDerivation rec {
  version = "1.7.1";
  tag = "roc-${version}";
  name = "rocm-opencl-runtime-${version}";
  srcs =
    [ (fetchFromGitHub {
        owner = "RadeonOpenCompute";
        repo = "ROCm-OpenCL-Runtime";
        rev = "${tag}";
        sha256 = "00drxc6ql2l346b7v80hajky4b77xdmc175ab06wkx4127cc2gih";
        name = "ROCm-OpenCL-Runtime-${tag}-src";
      })
      (fetchFromGitHub {
        owner = "RadeonOpenCompute";
        repo = "ROCm-OpenCL-Driver";
        rev = "${tag}";
        sha256 = "02lj2qqxdgfcrki3jn6j8vw1vp9vcd3ds8yxrl8j2amsk474r1dd";
        name = "ROCm-OpenCL-Driver-${tag}-src";
      })
      (fetchFromGitHub {
        owner = "RadeonOpenCompute";
        repo = "clang";
        rev = "${tag}";
        sha256 = "0wnbndds11jmkix39zfn07jnzkd7lj82pkb9pl3ncvdp64rnzxnr";
        name = "clang-${tag}-src";
      })
      (fetchFromGitHub {
        owner = "RadeonOpenCompute";
        repo = "llvm";
        rev = "${tag}";
        sha256 = "1ljkl1r3fbm7x937g69ps7a31a21vsf8pf5jxs8gzqm0xmhh2hrm";
        name = "llvm-${tag}-src";
      })
      (fetchFromGitHub {
        owner = "RadeonOpenCompute";
        repo = "lld";
        rev = "${tag}";
        sha256 = "0wd2qhn2qhbmwhw4qnqb914y29rm249jm1k1ssrx11ps7dn34jmk";
        name = "lld-${tag}-src";
      })
      (fetchFromGitHub {
        owner = "RadeonOpenCompute";
        repo = "ROCm-Device-Libs";
        rev = "${tag}";
        sha256 = "1mqqazb4x4lisgahkix2dgmns4x13wixr30li046vj05inybs06j";
        name = "ROCm-Device-Libs-${tag}-src";
      })
      (fetchFromGitHub {
        owner = "KhronosGroup";
        repo = "OpenCL-ICD-Loader";
        # rev = "26a3898";
        # sha256 = "148n8wzf6kp7vjhk6qz5mg4wmrysy8g5z4qmcn8imjgqiinhl05n";
        rev = "b1155e4b4526f1d52cebebd60ab985dbbc923157";
        sha256 = "1ym9n0xy9a7lqk845nnyn475kgcnm2c6lz9wlvrb7w94cgpfz707";
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
    sed 's,"/etc/OpenCL/vendors/","${libGL.driverLink}/etc/OpenCL/vendors/",g' -i api/opencl/khronos/icd/icd_linux.c
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
