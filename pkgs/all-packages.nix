# All packages in the 30_rocm package set that are ready for use.

self: pkgs:

with pkgs;

{

  # The kernel
  linux_4_18_kfd = (callPackage ./os-specific/linux/kernel/linux-4.18-kfd.nix {
    buildLinux = attrs: callPackage ./os-specific/linux/kernel/generic.nix attrs;
    kernelPatches =
      [ kernelPatches.bridge_stp_helper
        kernelPatches.modinst_arg_list_too_long
      ];
    extraConfig = ''
      KALLSYMS_ALL y
      DRM_AMD_DC y
      UNUSED_SYMBOLS y
    '';
    });
  linuxPackages_rocm = recurseIntoAttrs (linuxPackagesFor self.linux_4_18_kfd);

  # ROCm LLVM, LLD, and Clang
  rocm-llvm = callPackage ./development/compilers/llvm rec {
    version = "2.8.0";
    src = fetchFromGitHub {
      owner = "RadeonOpenCompute";
      repo = "llvm";
      rev = "roc-ocl-${version}";
      sha256 = "161rfsdfsa9fs8ibk3lz7ci4g3wnjx8rsgrm1mfin5xl48x4fjca";
    };
  };
  rocm-lld = self.callPackage ./development/compilers/lld rec {
    name = "rocm-lld";
    version = "2.8.0";
    src = fetchFromGitHub {
      owner = "RadeonOpenCompute";
      repo = "lld";
      rev = "roc-ocl-${version}";
      sha256 = "13lndrykz3m7fzvbkdy1wai0mc2yw3lvwz47wia5wq34gsjj5zfb";
    };
    llvm = self.rocm-llvm;
  };
  rocm-clang-unwrapped = callPackage ./development/compilers/clang rec {
    name = "clang-unwrapped";
    version = "2.8.0";
    src = fetchFromGitHub {
      owner = "RadeonOpenCompute";
      repo = "clang";
      rev = "roc-${version}";
      sha256 = "0rddrcaby2dca3gd4ff7svawr8wqmr2j2v6hwy3vxmx66fihgrkz";
    };
    llvm = self.rocm-llvm;
    inherit (self) rocr;
  };
  rocm-clang = pkgs.wrapCCWith rec {
    cc = self.rocm-clang-unwrapped;
    extraPackages = [ libstdcxxHook ];
    extraBuildCommands = ''
      rsrc="$out/resource-root"
      mkdir "$rsrc"
      ln -s "${cc}/lib/clang/10.0.0/include" "$rsrc"
      echo "-resource-dir=$rsrc" >> $out/nix-support/cc-cflags
      echo "--gcc-toolchain=${stdenv.cc.cc}" >> $out/nix-support/cc-cflags
      echo "-Wno-unused-command-line-argument" >> $out/nix-support/cc-cflags
      rm $out/nix-support/add-hardening.sh
      touch $out/nix-support/add-hardening.sh
    '';
  };

  # Userspace ROC stack
  roct = callPackage ./development/libraries/roct.nix {};
  rocr = callPackage ./development/libraries/rocr {};
  rocr-ext = callPackage ./development/libraries/rocr/rocr-ext.nix {};
  rocm-cmake = callPackage ./development/tools/rocm-cmake.nix {};
  rocminfo = callPackage ./development/tools/rocminfo.nix {};

  # OpenCL stack
  rocm-device-libs = callPackage ./development/libraries/rocm-device-libs {
    stdenv = pkgs.overrideCC stdenv self.rocm-clang;
    llvm = self.rocm-llvm;
    clang = self.rocm-clang;
    lld = self.rocm-lld;
    tagPrefix = "roc-ocl";
    sha256 = "0m2nmzad6ywwz16nahw5qayb5h28i0vnhfnrwf75da8rf2imp76p";
  };
  rocm-opencl-driver = callPackage ./development/libraries/rocm-opencl-driver {
    stdenv = pkgs.overrideCC stdenv self.rocm-clang;
    inherit (self) rocm-llvm rocm-clang-unwrapped;
  };
  rocm-opencl-runtime = callPackage ./development/libraries/rocm-opencl-runtime.nix {
    stdenv = pkgs.overrideCC stdenv self.rocm-clang;
    inherit (self) roct rocm-clang rocm-clang-unwrapped;
  };
  rocm-opencl-icd = callPackage ./development/libraries/rocm-opencl-icd.nix {};

  # HCC

  # hcc relies on submodules for llvm, clang, and compiler-rt at
  # specific revisions that do not track ROCm releases. We break the
  # hcc build into parts to make it a bit more manageable when dealing
  # with failures, and to have an opportunity to wrap hcc-clang before
  # hcc tools are built using that compiler.
  hcc-llvm = callPackage ./development/compilers/llvm rec {
    name = "hcc-llvm";
    version = "2.8.0";
    src = fetchFromGitHub {
      owner = "RadeonOpenCompute";
      repo = "llvm";
      rev = "roc-hcc-${version}";
      sha256 = "1fk9w34xq1qligwys4ims5mgs6hk9lfvb91sk0wl2776ybqkxj26";
    };
  };
  hcc-lld = callPackage ./development/compilers/hcc-lld {
    inherit (self) hcc-llvm;
  };
  hcc-clang-unwrapped = callPackage ./development/compilers/hcc-clang {
    inherit (self) rocr hcc-llvm hcc-lld;
  };
  hcc-clang = pkgs.wrapCCWith rec {
    cc = self.hcc-clang-unwrapped;
    extraPackages = [ libstdcxxHook ];
    extraBuildCommands = ''
      rsrc="$out/resource-root"
      mkdir "$rsrc"
      ln -s "${cc}/lib/clang/10.0.0/include" "$rsrc"
      echo "-resource-dir=$rsrc" >> $out/nix-support/cc-cflags
      echo "--gcc-toolchain=${stdenv.cc.cc}" >> $out/nix-support/cc-cflags
      rm $out/nix-support/add-hardening.sh
      touch $out/nix-support/add-hardening.sh
    '';
  };

  hcc-compiler-rt = callPackage ./development/compilers/hcc-compiler-rt {
    inherit (self) hcc-llvm;
  };
  hcc-device-libs = callPackage ./development/libraries/rocm-device-libs {
    stdenv = pkgs.overrideCC stdenv self.hcc-clang;
    llvm = self.hcc-llvm;
    clang = self.hcc-clang;
    lld = self.hcc-lld;
    tagPrefix = "roc-hcc";
    sha256 = "0i3s9261v0xlm5n274vcjhqp7b82hlkismqiblj44cwf622bwqar";
  };
  # Now we build hcc itself using hcc-llvm, hcc-clang, and hcc-compiler-rt
  hcc-unwrapped = callPackage ./development/compilers/hcc {
    inherit (self) rocr rocminfo;
    lld = self.hcc-lld;
    llvm = self.hcc-llvm;
    clang-unwrapped = self.hcc-clang-unwrapped;
    clang = self.hcc-clang;
    device-libs = self.hcc-device-libs;
    compiler-rt = self.hcc-compiler-rt;
  };

  hcc = pkgs.wrapCCWith rec {
    isClang = true;
    cc = self.hcc-clang-unwrapped;
    extraPackages = [ libstdcxxHook self.hcc-unwrapped ];
    extraBuildCommands = ''
      echo "-resource-dir=${self.hcc-clang}/resource-root" >> $out/nix-support/cc-cflags
      echo "--gcc-toolchain=${stdenv.cc.cc}" >> $out/nix-support/cc-cflags
      ln -s $out/bin/clang++ $out/bin/hcc
      for f in $(find ${self.hcc-unwrapped}/bin); do
        if [ ! -f $out/bin/$(basename "$f") ]; then
          ln -s "$f" $out/bin
        fi
      done
      mkdir -p $out/include
      ln -s ${self.hcc-unwrapped}/include $out/include/hcc
      ln -s ${self.hcc-unwrapped}/include/* $out/include/
      rm $out/nix-support/add-hardening.sh
      touch $out/nix-support/add-hardening.sh
    '';
  };

  # HIP

  # The hcc-llvm doesn't support GFX908, but comgr has been updated to
  # do so. This is another breakage of the ROCm 2.7 release that
  # should go away with hcc.
  hcc-comgr = (callPackage ./development/libraries/comgr {
    llvm = self.hcc-llvm;
    lld = self.hcc-lld;
    clang = self.hcc-clang;
    device-libs = self.hcc-device-libs;
    })# .overrideAttrs (old: {
    #   patchPhase = old.patchPhase + ''
    #     sed '/[[:space:]]*case ELF::EF_AMDGPU_MACH_AMDGCN_GFX908:/,/[[:space:]]*break;/d' -i src/comgr-metadata.cpp
    #   '';
    # })
  ;
  hip = callPackage ./development/compilers/hip {
    inherit (self) roct rocr rocminfo hcc hcc-unwrapped;
    comgr = self.hcc-comgr;
  };

  # HIP's clang backend requires the `amd-common` branches of the
  # LLVM, LLD, and Clang forks.
# BUILD TO HERE
  # The amd-common branch of the llvm fork
  amd-llvm = callPackage ./development/compilers/llvm rec {
    name = "amd-llvm";
    version = "20191002";
    src = fetchFromGitHub {
      owner = "RadeonOpenCompute";
      repo = "llvm";
      rev = "ceab2d5db530debcde830a919bb7f6b8e51d6cfe";
      sha256 = "0h2n6lzgjapfn1qipmhvifjyrk783bagdkg6c3myn884yvl0safn";
    };
  };

  # The amd-common branch of the lld fork
  amd-lld = callPackage ./development/compilers/lld {
    name = "amd-lld";
    version = "20191001";
    src = fetchFromGitHub {
      owner = "RadeonOpenCompute";
      repo = "lld";
      rev = "609a1e2afc44237dbd55ec595b4ec1ae9eecf8fa";
      sha256 = "1032kaj66rafbihx24mm2wacjvqfkdgjcxswhn69ijpd71ah6z5p";
    };
    llvm = self.amd-llvm;
  };

  amd-clang-tools-src = pkgs.fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "clang-tools-extra";
    rev = "6f382a084eda3115da1ec10040dab24ef0db9749";
    sha256 = "1ny12mlg8mfxicy8x7pspr7n9m1vyrnm44dhda1hc1q59r0gdfyn";
  };
# UPDATE TO HERE
  # The amd-common branch of the clang fork
  amd-clang-unwrapped = (callPackage ./development/compilers/clang {
    name = "amd-clang";
    version = "20191002";
    src = fetchFromGitHub {
      owner = "RadeonOpenCompute";
      repo = "clang";
      rev = "45fa31afbc14e159f9267180c9046ef67abe4809";
      sha256 = "1d9wpw57s6wj5pmsybqsampdlw16qhinxgc1fgmvg4292xhczhn1";
    };
    inherit (self) rocr;
    llvm = self.amd-llvm;
    # clang-tools-extra_src = self.amd-clang-tools-src;
  }).overrideAttrs(_: {
    # HIP assumes LLVM and LLD binaries are in its own binary directory
    postPatch = ''
      sed -e 's,  SmallString<128> ExecPath(C.getDriver().Dir);,  SmallString<128> ExecPath("${self.amd-llvm}/bin");,' \
          -e 's,  SmallString<128> OptPath(C.getDriver().Dir);,  SmallString<128> OptPath("${self.amd-llvm}/bin");,' \
          -e 's,  SmallString<128> LlcPath(C.getDriver().Dir);,  SmallString<128> LlcPath("${self.amd-llvm}/bin");,' \
          -e 's,  SmallString<128> LldPath(C.getDriver().Dir);,  SmallString<128> LldPath("${self.amd-lld}/bin");,' \
          -i lib/Driver/ToolChains/HIP.cpp
    '';
  });

  # Wrap clang so it is a usable compiler
  amd-clang = pkgs.wrapCCWith rec {
    isClang = true;
    cc = self.amd-clang-unwrapped;
    extraPackages = [ libstdcxxHook self.amd-clang-unwrapped ];
    extraBuildCommands = ''
      rsrc="$out/resource-root"
      mkdir "$rsrc"
      ln -s "${cc}/lib/clang/10.0.0/include" "$rsrc"
      echo "-resource-dir=$rsrc" >> $out/nix-support/cc-cflags
      echo "--gcc-toolchain=${stdenv.cc.cc}" >> $out/nix-support/cc-cflags
      echo "-Wno-unused-command-line-argument" >> $out/nix-support/cc-cflags
      rm $out/nix-support/add-hardening.sh
      touch $out/nix-support/add-hardening.sh
      ln -s ${self.amd-llvm}/bin/llvm-link $out/llvm-link
    '';
  };

  amd-device-libs = (callPackage ./development/libraries/rocm-device-libs {
    stdenv = pkgs.overrideCC stdenv self.amd-clang;
    llvm = self.amd-llvm;
    clang = self.amd-clang;
    lld = self.amd-lld;
    source = pkgs.fetchFromGitHub {
      owner = "RadeonOpenCompute";
      repo = "ROCm-Device-Libs";
      rev = "c3967062378a1a33b66d8ff10455f4d72d567939";
      sha256 = "1n219sn3636s8nbp779daix155j3rklgahxrlfyi893vxi13yv4h";
    };
  }).overrideAttrs (_: {
    cmakeFlags = [
      "-DCMAKE_C_COMPILER=${self.amd-clang}/bin/clang"
      "-DCMAKE_CXX_COMPILER=${self.amd-clang}/bin/clang++"
      "-DLLVM_DIR=${self.amd-llvm}"
      "-DCLANG_OPTIONS_APPEND=-Wno-unused-command-line-argument"
    ];
  });

  amd-comgr = (callPackage ./development/libraries/comgr {
    llvm = self.amd-llvm;
    lld = self.amd-lld;
    clang = self.amd-clang;
    device-libs = self.amd-device-libs;
  }).overrideAttrs (_: {
    # A newer revision is needed for the latest LLVM
    src = pkgs.fetchFromGitHub {
      owner = "RadeonOpenCompute";
      repo = "ROCm-CompilerSupport";
      rev = "7c581b41567121ef78b5bc8da3c34bb5ce777e75";
      sha256 = "0bb38bgphybhsyyv5xzf3c1vccrqd871mq2jxpb5frxxicgwqaa4";
    };});

  # A HIP compiler that does not go through hcc
  hip-clang = callPackage ./development/compilers/hip-clang {
    inherit (self) roct rocr rocminfo hcc;
    llvm = self.amd-llvm;
    clang-unwrapped = self.amd-clang-unwrapped;
    clang = self.amd-clang;
    comgr = self.amd-comgr;
    device-libs = self.amd-device-libs;
  };

  clang-ocl = callPackage ./development/compilers/clang-ocl {
    inherit (self) rocm-cmake rocm-opencl-runtime hcc;
    inherit (self) amd-clang amd-clang-unwrapped;
  };

  rocm-smi = callPackage ./tools/rocm-smi { };

  rocm-bandwidth = callPackage ./tools/rocm-bandwidth {
    inherit (self) roct rocr;
  };

  rocblas-tensile = callPackage ./development/libraries/rocblas/tensile.nix {
    inherit (python3Packages) buildPythonPackage pyyaml pytest;
    inherit (self) rocminfo hcc rocm-smi;
  };

  rocblas = callPackage ./development/libraries/rocblas {
    inherit (self) rocm-cmake hcc hcc-lld rocr rocblas-tensile;
    # hip = self.hip;
    # comgr = self.hcc-comgr;
    hip = self.hip-clang;
    comgr = self.amd-comgr;
    inherit (python3Packages) python;
    
  };

  # MIOpen

  miopengemm = callPackage ./development/libraries/miopengemm {
    inherit (self) rocm-cmake rocm-opencl-runtime hcc;
  };

  # Currently broken
  miopen-cl = callPackage ./development/libraries/miopen {
    inherit (self) rocm-cmake rocm-opencl-runtime rocr hcc
                   clang-ocl miopengemm rocblas;
    # comgr = self.hcc-comgr;
    # hip = self.hip;
    # clang = self.hcc;

    hip = self.hip-clang;
    comgr = self.amd-comgr;
    clang = self.amd-clang;
  };

  miopen-hip = self.miopen-cl.override {
    useHip = true;
  };

  rocfft = callPackage ./development/libraries/rocfft {
    inherit (self) rocr rocminfo hcc rocm-cmake;
    # hip = self.hip;
    # comgr = self.hcc-comgr;
    hip = self.hip-clang;
    comgr = self.amd-comgr;
  };

  rccl = callPackage ./development/libraries/rccl {
    inherit (self) rocm-cmake hcc;
    # hip = self.hip;
    # comgr = self.hcc-comgr;
    hip = self.hip-clang; 
    comgr = self.amd-comgr;
  };

  rocrand = callPackage ./development/libraries/rocrand {
    inherit (self) rocm-cmake rocminfo hcc rocr;
    hip = self.hip-clang;
    comgr = self.amd-comgr;
    # hip = self.hip;
    # comgr = self.hcc-comgr;
  };
  rocrand-python-wrappers = callPackage ./development/libraries/rocrand/python.nix {
    inherit (self) rocr rocrand;
    inherit (python3Packages) buildPythonPackage numpy;
    hip = self.hip-clang;
  };

  rocprim = callPackage ./development/libraries/rocprim {
    stdenv = pkgs.overrideCC stdenv self.hcc;
    # hip = self.hip;
    hip = self.hip-clang;
  };

  hipcub = callPackage ./development/libraries/hipcub {
    inherit (self) hcc rocprim;
  };

  rocsparse = callPackage ./development/libraries/rocsparse {
    inherit (self) rocprim hipcub rocm-cmake;
    # hip = self.hip;
    hip = self.hip-clang;
    comgr = self.amd-comgr;
  };

  hipsparse = callPackage ./development/libraries/hipsparse {
    inherit (self) rocr rocsparse rocm-cmake;
    # hip = self.hip;
    hip = self.hip-clang;
    comgr = self.amd-comgr;
  };

  rocthrust = callPackage ./development/libraries/rocthrust {
    inherit (self) rocm-cmake rocprim;
    # hip = self.hip;
    hip = self.hip-clang;
    comgr = self.amd-comgr;
  };

  roctracer = callPackage ./development/tools/roctracer {
    inherit (self) hcc-unwrapped;
    hip = self.hip-clang;
  };

  rocprofiler = callPackage ./development/tools/rocprofiler {
    inherit (self) rocr roct roctracer hcc-unwrapped;
  };

  amdtbasetools = callPackage ./development/libraries/AMDTBaseTools {};
  amdtoswrappers = callPackage ./development/libraries/AMDTOSWrappers {};
  cxlactivitylogger = callPackage ./development/libraries/cxlactivitylogger {};

  clpeak = pkgs.callPackage ./tools/clpeak {
    opencl = self.rocm-opencl-runtime;
  };

  tensorflow-rocm = python37Packages.callPackage ./development/libraries/tensorflow/bin.nix {
    inherit (self) hcc hcc-unwrapped miopen-hip miopengemm rocrand
                   rocfft rocblas rocr rccl cxlactivitylogger;
    # hip = self.hip;
    hip = self.hip-clang;
  };

  tensorflow-rocm-src = python37Packages.callPackage ./development/libraries/tensorflow/default.nix {
    inherit (self) hcc hcc-unwrapped miopen-hip miopengemm rocrand
                   rocfft rocblas rocr rccl cxlactivitylogger amd-clang;
    hip = self.hip-clang;
  };


  pytorch-rocm = python37Packages.callPackage ./development/libraries/pytorch/default.nix {
    inherit (self) rocr miopengemm miopen-hip rocsparse hipsparse rocthrust rccl rocrand rocblas rocfft;
    hip = self.hip-clang;
    comgr = self.amd-comgr;
  };

  hipCPU = callPackage ./development/compilers/hipsycl/hipCPU.nix {
    clang = self.amd-clang-unwrapped;
  };

  hipsycl = callPackage ./development/compilers/hipsycl {
    inherit (self) rocr hipCPU;
    device-libs = self.amd-device-libs;
    llvm = self.amd-llvm;
    clang = self.amd-clang;
    clang-unwrapped = self.amd-clang-unwrapped;
    # hcc = self.amd-hcc;
    hip = self.hip-clang;
  };
}
