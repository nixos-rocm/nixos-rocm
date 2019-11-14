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
    version = "2.9.0";
    src = fetchFromGitHub {
      owner = "RadeonOpenCompute";
      repo = "llvm";
      rev = "roc-ocl-${version}";
      sha256 = "1m7041rr5f85cknlz49mvy8xpk4bhm5b5p1wxnv6adkf1mmp4qq4";
    };
  };
  rocm-lld = self.callPackage ./development/compilers/lld rec {
    name = "rocm-lld";
    version = "2.9.0";
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
    version = "2.9.0";
    src = fetchFromGitHub {
      owner = "RadeonOpenCompute";
      repo = "clang";
      rev = "roc-${version}";
      sha256 = "1z9k1qfbf3vjjrzy7qc90bm2ck04pi6a7r2yl4gkqvsp5djdb4w3";
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
  rocminfo = callPackage ./development/tools/rocminfo.nix {
    defaultTargets = config.rocmTargets or ["gfx803" "gfx900" "gfx906"];
  };

  # OpenCL stack
  rocm-device-libs = callPackage ./development/libraries/rocm-device-libs {
    stdenv = pkgs.overrideCC stdenv self.rocm-clang;
    llvm = self.rocm-llvm;
    clang = self.rocm-clang;
    lld = self.rocm-lld;
    tagPrefix = "roc-ocl";
    sha256 = "0i3s9261v0xlm5n274vcjhqp7b82hlkismqiblj44cwf622bwqar";
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
    version = "2.9.0";
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

  hcc-openmp = pkgs.llvmPackages_8.openmp.override {
    llvm = self.hcc-llvm;
  };

  # HIP's clang backend requires the `amd-common` branches of the
  # LLVM, LLD, and Clang forks.

  # The amd-common branch of the llvm fork
  amd-llvm = callPackage ./development/compilers/llvm rec {
    name = "amd-llvm";
    version = "20191003";
    src = fetchFromGitHub {
      owner = "RadeonOpenCompute";
      repo = "llvm";
      rev = "c38780c1b2096b9d8c4c88b8000fe2774b0f892a";
      sha256 = "0a9d7cdc6cyi8lzadkccy68yh00wg62qw17wpldmr8jpzcihhb2n";
    };
  };

  # The amd-common branch of the lld fork
  amd-lld = callPackage ./development/compilers/lld {
    name = "amd-lld";
    version = "20191003";
    src = fetchFromGitHub {
      owner = "RadeonOpenCompute";
      repo = "lld";
      rev = "e5162a691f6596aa1f165305ebeeffce93597968";
      sha256 = "0f504n7nvdw0ggncqgij98r6r013hnzlz12xxk57z2m3zcm728mq";
    };
    llvm = self.amd-llvm;
  };

  amd-openmp = pkgs.llvmPackages_8.openmp.override {
    llvm = self.amd-llvm;
  };

  amd-clang-tools-src = pkgs.fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "clang-tools-extra";
    rev = "6f382a084eda3115da1ec10040dab24ef0db9749";
    sha256 = "1ny12mlg8mfxicy8x7pspr7n9m1vyrnm44dhda1hc1q59r0gdfyn";
  };

  # The amd-common branch of the clang fork
  amd-clang-unwrapped = (callPackage ./development/compilers/clang {
    name = "amd-clang";
    version = "20191003";
    src = fetchFromGitHub {
      owner = "RadeonOpenCompute";
      repo = "clang";
      rev = "a09d37e345861d68f9768939e485d265f4fcb0ce";
      sha256 = "185fq21dpng55y80jxw7g03cpas26glx2rh5ib62nyi2q3h4yfia";
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
      ln -s ${self.amd-llvm}/bin/llvm-link $out/bin/llvm-link
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
    inherit (self) roct rocr rocminfo hcc hcc-unwrapped;
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
    inherit (self) rocm-cmake hcc hcc-unwrapped hcc-lld rocr rocblas-tensile;
    # hip = self.hip;
    # comgr = self.hcc-comgr;
    # clang = self.hcc-clang;
    hip = self.hip-clang;
    comgr = self.amd-comgr;
    clang = self.amd-clang;
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
    # clang = self.hcc-clang;
    hip = self.hip-clang;
    comgr = self.amd-comgr;
    clang = self.amd-clang;
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
    hip = self.hip;
  };

  tensorflow2-rocm = python37Packages.callPackage ./development/libraries/tensorflow/bin2.nix {
    inherit (self) hcc hcc-unwrapped miopen-hip miopengemm rocrand
                   rocfft rocblas rocr rccl cxlactivitylogger;
    hip = self.hip;
  };

  pytorch-rocm = python37Packages.callPackage ./development/libraries/pytorch/default.nix {
    inherit (self) rocr miopengemm miopen-hip rocsparse hipsparse rocthrust 
      rccl rocrand rocblas rocfft rocprim hipcub roctracer;
    hip = self.hip;
    comgr = self.hcc-comgr;
    openmp = self.hcc-openmp;
    hcc = self.hcc-unwrapped;
    # hip = self.hip-clang;
    # comgr = self.amd-comgr;
    # openmp = self.amd-openmp;
  };

  torchvision-rocm = python37Packages.torchvision.override {
    pytorch = self.pytorch-rocm;
  };
}
