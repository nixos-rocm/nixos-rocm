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
    version = "2.3.0";
    src = fetchFromGitHub {
      owner = "RadeonOpenCompute";
      repo = "llvm";
      rev = "roc-ocl-${version}";
      sha256 = "1ym4ai5h9i5cry518v64jadbyj4z786xr0p9vnzw710admdmkv23";
    };
  };
  rocm-lld = self.callPackage ./development/compilers/lld { };
  rocm-clang-unwrapped = self.callPackage ./development/compilers/clang { };
  rocm-clang = pkgs.wrapCCWith rec {
    cc = self.rocm-clang-unwrapped;
    extraPackages = [ libstdcxxHook ];
    extraBuildCommands = ''
      rsrc="$out/resource-root"
      mkdir "$rsrc"
      ln -s "${cc}/lib/clang/9.0.0/include" "$rsrc"
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
  rocm-device-libs = callPackage ./development/libraries/rocm-device-libs {
    stdenv = pkgs.overrideCC stdenv self.rocm-clang;
  };

  # OpenCL stack
  rocm-opencl-driver = callPackage ./development/libraries/rocm-opencl-driver {
    stdenv = pkgs.overrideCC stdenv self.rocm-clang;
    inherit (self) rocm-llvm rocm-clang-unwrapped;
  };
  rocm-opencl-runtime = callPackage ./development/libraries/rocm-opencl-runtime.nix {
    stdenv = pkgs.overrideCC stdenv self.rocm-clang;
    inherit (self) rocm-clang rocm-clang-unwrapped;
  };
  rocm-opencl-icd = callPackage ./development/libraries/rocm-opencl-icd.nix {};

  # hcc relies on submodules for llvm, clang, and compiler-rt at
  # specific revisions that do not track ROCm releases. We break the
  # hcc build into parts to make it a bit more manageable when dealing
  # with failures, and to have an opportunity to wrap hcc-clang before
  # hcc tools are built using that compiler.
  hcc-llvm = callPackage ./development/compilers/llvm rec {
    name = "hcc-llvm";
    version = "2.3.0";
    src = fetchFromGitHub {
      owner = "RadeonOpenCompute";
      repo = "llvm";
      rev = "roc-hcc-${version}";
      sha256 = "08xmphdv3w7kg11zzsvk2jkgalr88fq7ppf1a9vh9lyjnrv8jv72";
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
      ln -s "${cc}/lib/clang/9.0.0/include" "$rsrc"
      echo "-resource-dir=$rsrc" >> $out/nix-support/cc-cflags
      echo "--gcc-toolchain=${stdenv.cc.cc}" >> $out/nix-support/cc-cflags
      rm $out/nix-support/add-hardening.sh
      touch $out/nix-support/add-hardening.sh
    '';
  };

  hcc-compiler-rt = callPackage ./development/compilers/hcc-compiler-rt {
    inherit (self) hcc-llvm;
  };

  # Now we build hcc itself using hcc-llvm, hcc-clang, and hcc-compiler-rt
  hcc-unwrapped = callPackage ./development/compilers/hcc {
    inherit (self) rocr rocm-device-libs rocminfo
                   hcc-lld hcc-llvm hcc-clang-unwrapped hcc-clang
                   hcc-compiler-rt;
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
      rm $out/nix-support/add-hardening.sh
      touch $out/nix-support/add-hardening.sh
    '';
  };

  hip = callPackage ./development/compilers/hip {
    inherit (self) roct rocr rocminfo hcc hcc-unwrapped;
  };

  clang-ocl = callPackage ./development/compilers/clang-ocl {
    inherit (self) rocm-cmake rocm-opencl-runtime hcc;
  };

  rocm-smi = callPackage ./tools/rocm-smi { };

  rocm-bandwidth = callPackage ./tools/rocm-bandwidth {
    inherit (self) roct rocr;
  };

  rocblas-tensile = callPackage ./development/libraries/rocblas/tensile.nix {
    inherit (python2Packages) buildPythonPackage pyyaml;
  };

  rocblas = callPackage ./development/libraries/rocblas {
    inherit (self) rocm-cmake hcc hcc-lld hip rocr rocblas-tensile;
    inherit (python2Packages) python;
  };

  # MIOpen

  miopengemm = callPackage ./development/libraries/miopengemm {
    inherit (self) rocm-cmake rocm-opencl-runtime hcc;
  };

  # Currently broken
  miopen-cl = callPackage ./development/libraries/miopen {
    inherit (self) rocm-cmake rocm-opencl-runtime rocr hcc
                   clang-ocl miopengemm hip rocblas;
  };

  miopen-hip = self.miopen-cl.override {
    useHip = true;
  };

  rocfft = callPackage ./development/libraries/rocfft {
    inherit (self) rocr rocminfo hcc hip rocm-cmake;
  };

  rccl = callPackage ./development/libraries/rccl {
    inherit (self) rocm-cmake hcc hip;
  };

  rocrand = callPackage ./development/libraries/rocrand {
    inherit (self) rocm-cmake rocminfo hcc hip rocr;
  };
  rocrand-python-wrappers = callPackage ./development/libraries/rocrand/python.nix {
    inherit (self) rocr hip rocrand;
    inherit (python3Packages) buildPythonPackage numpy;
  };

  # This is not yet working. We are at least missing hsa-amd-aqlprofile.
  # rocprofiler = callPackage ./development/tools/rocprofiler {
  #   inherit (self) rocr roct;
  # };
  rocprim = callPackage ./development/libraries/rocprim {
    stdenv = pkgs.overrideCC stdenv self.hcc;
    inherit (self) hip;
  };


  amdtbasetools = callPackage ./development/libraries/AMDTBaseTools {};
  amdtoswrappers = callPackage ./development/libraries/AMDTOSWrappers {};
  cxlactivitylogger = callPackage ./development/libraries/cxlactivitylogger {};

  clpeak = pkgs.callPackage ./tools/clpeak { 
    opencl = self.rocm-opencl-runtime; 
  };

  tensorflow-rocm = python36Packages.callPackage ./development/libraries/tensorflow/bin.nix {
    inherit (self) hcc hcc-unwrapped hip miopen-hip miopengemm rocrand
                   rocfft rocblas rocr rccl cxlactivitylogger;
  };

}
