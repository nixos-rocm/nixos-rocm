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

  # Userspace ROC stack
  rocm-thunk = callPackage ./development/libraries/rocm-thunk {};
  rocr = callPackage ./development/libraries/rocr { inherit (self) rocm-thunk; };
  rocr-ext = callPackage ./development/libraries/rocr/rocr-ext.nix {};
  rocm-cmake = callPackage ./development/tools/rocm-cmake.nix {};
  rocminfo = callPackage ./development/tools/rocminfo.nix {
    inherit (self) rocm-cmake rocr;
    defaultTargets = config.rocmTargets or ["gfx803" "gfx900" "gfx906"];
  };

  # ROCm LLVM, LLD, and Clang
  rocm-llvm-project = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "llvm-project";
    rev = "rocm-3.5.0";
    sha256 = "0k1939yp8liblskx147n132ds21mmrgid2pd4kngs5rhjif8hfzj";
  };

  rocm-llvm = callPackage ./development/compilers/llvm rec {
    version = "3.5.0";
    src = "${self.rocm-llvm-project}/llvm";
  };
  rocm-lld = self.callPackage ./development/compilers/lld rec {
    name = "rocm-lld";
    version = "3.5.0";
    src = "${self.rocm-llvm-project}/lld";
    llvm = self.rocm-llvm;
  };
  rocm-clang-unwrapped = callPackage ./development/compilers/clang rec {
    name = "clang-unwrapped";
    version = "3.5.0";
    src = "${self.rocm-llvm-project}/clang";
    llvm = self.rocm-llvm;
    lld = self.rocm-lld;
    inherit (self) rocr;
  };
  rocm-clang = pkgs.wrapCCWith rec {
    cc = self.rocm-clang-unwrapped;
    extraPackages = [ libstdcxxHook ];
    extraBuildCommands = ''
      rsrc="$out/resource-root"
      mkdir "$rsrc"
      ln -s "${cc}/lib/clang/11.0.0/include" "$rsrc"
      echo "-resource-dir=$rsrc" >> $out/nix-support/cc-cflags
      echo "--gcc-toolchain=${stdenv.cc.cc}" >> $out/nix-support/cc-cflags
      echo "-Wno-unused-command-line-argument" >> $out/nix-support/cc-cflags
      rm $out/nix-support/add-hardening.sh
      touch $out/nix-support/add-hardening.sh
    '';
  };

  rocm-device-libs = callPackage ./development/libraries/rocm-device-libs {
    inherit (self) rocr;
    stdenv = pkgs.overrideCC stdenv self.rocm-clang;
    llvm = self.rocm-llvm;
    clang-unwrapped = self.rocm-clang-unwrapped;
    clang = self.rocm-clang;
    lld = self.rocm-lld;
    tagPrefix = "rocm-ocl";
    sha256 = "0h4aggj2766gm3grz387nbw3bn0l461walgkzmmly9a5shfc36ah";
  };

  rocm-comgr = callPackage ./development/libraries/comgr {
    llvm = self.rocm-llvm;
    lld = self.rocm-lld;
    clang = self.rocm-clang;
    device-libs = self.rocm-device-libs;
  };

  rocclr = callPackage ./development/libraries/rocclr {
    comgr = self.rocm-comgr;
    clang = self.rocm-clang;
    inherit (self) rocm-opencl-src;
  };

  # OpenCL stack
  rocm-opencl-src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "ROCm-OpenCL-Runtime";
    rev = "roc-3.5.0";
    sha256 = "1wrr6mmn4gf6i0vxp4yqk0ny2wglvj1jfj50il8czjwy0cwmhykk";
    name = "ROCm-OpenCL-Runtime-src";
  };

  rocm-opencl-runtime = callPackage ./development/libraries/rocm-opencl-runtime.nix {
    stdenv = pkgs.overrideCC stdenv self.rocm-clang;
    inherit (self) rocm-thunk rocm-clang rocm-clang-unwrapped rocm-cmake;
    inherit (self) rocm-device-libs rocm-lld rocm-llvm rocr rocclr;
    comgr = self.rocm-comgr;
    src = self.rocm-opencl-src;
  };

  rocm-opencl-icd = callPackage ./development/libraries/rocm-opencl-icd.nix {
    inherit (self) rocm-opencl-runtime;
  };

  # HIP

  # A HIP compiler that does not go through hcc
  hip-clang = callPackage ./development/compilers/hip-clang {
    inherit (self) rocm-thunk rocr rocminfo rocclr;
    llvm = self.rocm-llvm;
    clang-unwrapped = self.rocm-clang-unwrapped;
    clang = self.rocm-clang;
    device-libs = self.rocm-device-libs;
    comgr = self.rocm-comgr;
  };

  # `hip` is an alias for `hip-clang`
  hip = hip-clang;

  clang-ocl = callPackage ./development/compilers/clang-ocl {
    inherit (self) rocm-cmake rocm-device-libs rocm-opencl-runtime;
    lld = self.rocm-lld;
    llvm = self.rocm-llvm;
    clang = self.rocm-clang;
    clang-unwrapped = self.rocm-clang-unwrapped;
    # inherit (self) amd-clang amd-clang-unwrapped;
    # inherit (pkgs.llvmPackages_10) clang clang-unwrapped;
  };

  rocm-smi = callPackage ./tools/rocm-smi { };

  rocm-bandwidth = callPackage ./tools/rocm-bandwidth {
    inherit (self) rocm-thunk rocr;
  };

  rocm-openmp = pkgs.llvmPackages_latest.openmp.override {
    llvm = self.rocm-llvm;
  };

  rocblas-tensile = callPackage ./development/libraries/rocblas/tensile.nix {
    inherit (python3Packages) buildPythonPackage pyyaml pytest;
    inherit (self) rocminfo rocm-smi hip-clang;
  };

  rocblas = callPackage ./development/libraries/rocblas {
    inherit (self) rocm-cmake rocr rocblas-tensile hip-clang;
    clang = self.rocm-clang;
    openmp = self.rocm-openmp;
    comgr = self.rocm-comgr;
    # llvm = pkgs.llvmPackages_7.llvm;
    llvm = self.rocm-llvm;
    inherit (python3Packages) python;
  };

  # MIOpen

  miopengemm = callPackage ./development/libraries/miopengemm {
    inherit (self) rocm-cmake rocm-opencl-runtime;
    clang = self.rocm-clang;
  };

  # # Currently broken
  miopen-cl = callPackage ./development/libraries/miopen {
    inherit (self) rocm-cmake rocm-opencl-runtime rocr
                   clang-ocl miopengemm rocblas;
    hip = self.hip-clang;
    clang = self.rocm-clang;
    comgr = self.rocm-comgr;
  };

  miopen-hip = self.miopen-cl.override {
    useHip = true;
  };

  rocfft = callPackage ./development/libraries/rocfft {
    inherit (self) rocr rocminfo rocm-cmake;
    hip = self.hip-clang;
    clang = self.rocm-clang;
    comgr = self.rocm-comgr;
  };

  # rccl = callPackage ./development/libraries/rccl {
  #   inherit (self) rocm-cmake hcc;
  #   hip = self.hip;
  #   comgr = self.hcc-comgr;
  # };

  # rocrand = callPackage ./development/libraries/rocrand {
  #   inherit (self) rocm-cmake rocminfo hcc rocr;
  #   comgr = self.hcc-comgr;
  #   hip = self.hip;
  # };
  # rocrand-python-wrappers = callPackage ./development/libraries/rocrand/python.nix {
  #   inherit (self) rocr rocrand;
  #   inherit (python3Packages) buildPythonPackage numpy;
  #   hip = self.hip;
  # };

  # rocprim = callPackage ./development/libraries/rocprim {
  #   inherit (self) rocm-cmake rocr;
  #   stdenv = pkgs.overrideCC stdenv self.hcc;
  #   hip = self.hip;
  # };

  # hipcub = callPackage ./development/libraries/hipcub {
  #   inherit (self) hcc hip rocm-cmake rocprim;
  # };

  # rocsparse = callPackage ./development/libraries/rocsparse {
  #   inherit (self) rocprim hipcub rocm-cmake hcc;
  #   hip = self.hip;
  #   comgr = self.hcc-comgr;
  # };

  # hipsparse = callPackage ./development/libraries/hipsparse {
  #   inherit (self) rocr rocsparse rocm-cmake hcc;
  #   hip = self.hip;
  #   comgr = self.hcc-comgr;
  # };

  # rocthrust = callPackage ./development/libraries/rocthrust {
  #   inherit (self) rocm-cmake rocprim hcc;
  #   hip = self.hip;
  #   comgr = self.hcc-comgr;
  # };

  # roctracer = callPackage ./development/tools/roctracer {
  #   inherit (self) hcc-unwrapped rocm-thunk rocr;
  #   hip = self.hip;
  #   inherit (pkgs.pythonPackages) python buildPythonPackage fetchPypi ply;
  # };

  # rocprofiler = callPackage ./development/tools/rocprofiler {
  #   inherit (self) rocr rocm-thunk roctracer hcc-unwrapped;
  # };

  amdtbasetools = callPackage ./development/libraries/AMDTBaseTools {};
  amdtoswrappers = callPackage ./development/libraries/AMDTOSWrappers {
    inherit (self) amdtbasetools;
  };
  cxlactivitylogger = callPackage ./development/libraries/cxlactivitylogger {
    inherit (self) amdtbasetools amdtoswrappers;
  };

  clpeak = pkgs.callPackage ./tools/clpeak {
    opencl = self.rocm-opencl-runtime;
  };

  # tensorflow-rocm = python37Packages.callPackage ./development/libraries/tensorflow/bin.nix {
  #   inherit (self) hcc hcc-unwrapped miopen-hip miopengemm rocrand
  #                  rocfft rocblas rocr rccl cxlactivitylogger;
  #   hip = self.hip;
  # };

  # tf2PyPackages = python37.override {
  #   packageOverrides = self: super: {
  #     protobuf = super.buildPythonPackage {
  #       pname = "protobuf";
  #       version = "3.11.3";
  #       format = "wheel";
  #       src = fetchurl {
  #         url = "https://files.pythonhosted.org/packages/ff/f1/8dcd4219bbae8aa44fe8871a89f05eca2dca9c04f8dbfed8a82b7be97a88/protobuf-3.11.3-cp37-cp37m-manylinux1_x86_64.whl";
  #         sha256 = "01zwn19vl2iccjg7rrk950wcqwwvkyxa0dnyv50z215rk0vwkfcf";
  #       };
  #       propagatedBuildInputs = [
  #         self.six
  #       ];
  #     };
  #   };
  # };

  # tensorflow2-rocm = self.tf2PyPackages.pkgs.callPackage ./development/libraries/tensorflow/bin2.nix {
  #   inherit (self) hcc hcc-unwrapped miopen-hip miopengemm rocrand
  #                  rocfft rocblas rocr rccl cxlactivitylogger;
  #   hip = self.hip;
  # };

  # pytorch-rocm = python37Packages.callPackage ./development/libraries/pytorch/default.nix {
  #   inherit (self) rocr miopengemm rocsparse hipsparse rocthrust
  #     rccl rocrand rocblas rocfft rocprim hipcub roctracer rocm-cmake;
  #   miopen = self.miopen-hip;
  #   hip = self.hip;
  #   comgr = self.amd-comgr;
  #   openmp = self.hcc-openmp;
  #   hcc = self.hcc-unwrapped;
  # };

  # torchvision-rocm = python37Packages.torchvision.override {
  #   pytorch = self.pytorch-rocm;
  # };

  # The OpenCL compiler (called through clBuildProgram by darktable)
  # is not properly supporting `-I` flags to add to the include
  # path. To avoid relying on that mechanism, we edit `#include`
  # directives in the OpenCL kernels to use absolute paths.
  darktable-rocm = pkgs.darktable.overrideAttrs (old: {
    preFixup = (old.preFixup or "") + ''
      for f in $(find $out/share/darktable/kernels -name '*.cl'); do
        sed "s|#include \"\(.*\)\"|#include \"$out/share/darktable/kernels/\1\"|g" -i "$f"
      done
    '';
  });

  hashcat-rocm = pkgs.hashcat.overrideAttrs (old: {
    preFixup = (old.preFixup or "") + ''
      for f in $(find $out/share/hashcat/OpenCL -name '*.cl'); do
        sed "s|#include \"\(.*\)\"|#include \"$out/share/hashcat/OpenCL/\1\"|g" -i "$f"
      done
    '';
  });

  # rocm-llvm-project-aomp = fetchFromGitHub {
  #   owner = "ROCm-Developer-Tools";
  #   repo = "llvm-project";
  #   rev = "roc-aomp-3.0.0";
  #   sha256 = "00cw8azj2jh7zs79klk6zcrw76dkiplrignazl9lavyr9qcbiy7v";
  # };

  # Deprecated names
  roct = builtins.trace "'roct' was renamed to 'rocm-thunk'" self.rocm-thunk;
}
