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
  llvmPackages_rocm = callPackage ./development/compilers/llvm/rocm {};
  rocm-runtime = callPackage ./development/libraries/rocm-runtime {
    # inherit (self) rocm-thunk;
    inherit (self.llvmPackages_rocm) clang-unwrapped llvm;
  };
  rocm-thunk = callPackage ./development/libraries/rocm-thunk {};
  rocm-cmake = callPackage ./development/tools/build-managers/rocm-cmake {};
  rocminfo = callPackage ./development/tools/rocminfo.nix {
    inherit (self) rocm-cmake rocm-runtime;
    defaultTargets = config.rocmTargets or ["gfx803" "gfx900" "gfx906"];
  };

  rocm-device-libs = callPackage ./development/libraries/rocm-device-libs {
    inherit (self.llvmPackages_rocm) clang clang-unwrapped lld llvm;
  };

  rocm-comgr = callPackage ./development/libraries/rocm-comgr {
    inherit (self.llvmPackages_rocm) clang lld llvm;
    device-libs = self.rocm-device-libs;
  };

  rocclr = callPackage ./development/libraries/rocclr {
    inherit (self) rocm-comgr rocm-opencl-runtime rocm-runtime rocm-thunk;
    inherit (self.llvmPackages_rocm) clang; 
  };

  rocm-opencl-runtime = callPackage ./development/libraries/rocm-opencl-runtime {
    inherit (self) rocclr rocm-comgr rocm-device-libs rocm-runtime
      rocm-thunk;
    inherit (self.llvmPackages_rocm) clang clang-unwrapped lld llvm;
    stdenv = pkgs.overrideCC stdenv self.llvmPackages_rocm.clang;
  };

  rocm-opencl-icd = callPackage ./development/libraries/rocm-opencl-icd {
    inherit (self) rocm-opencl-runtime;
  };

  # HIP

  # A HIP compiler that does not go through hcc
  hip-clang = callPackage ./development/compilers/hip-clang {
    inherit (self) rocm-device-libs rocm-thunk rocm-runtime rocminfo rocclr;
    inherit (self.llvmPackages_rocm) clang clang-unwrapped llvm compiler-rt lld;
    comgr = self.rocm-comgr;
  };

  # `hip` is an alias for `hip-clang`
  hip = self.hip-clang;

  clang-ocl = callPackage ./development/compilers/clang-ocl {
    inherit (self) rocm-cmake rocm-device-libs rocm-opencl-runtime;
    inherit (self.llvmPackages_rocm) clang clang-unwrapped lld llvm;
    # inherit (self) amd-clang amd-clang-unwrapped;
    # inherit (pkgs.llvmPackages_10) clang clang-unwrapped;
  };

  rocm-smi = python3Packages.callPackage ./tools/system/rocm-smi { };

  rocm-bandwidth = callPackage ./tools/rocm-bandwidth {
    inherit (self) rocm-thunk rocm-runtime;
  };

  rocm-openmp = pkgs.llvmPackages_latest.openmp.override {
    inherit (self.llvmPackages_rocm) llvm;
  };

  rocblas-tensile = python3Packages.callPackage ./development/libraries/rocblas/tensile.nix {
    inherit (self) rocminfo rocm-smi hip-clang;
  };

  rocblas = callPackage ./development/libraries/rocblas {
    inherit (self) rocm-cmake rocm-runtime rocblas-tensile hip;
    inherit (self.llvmPackages_rocm) clang llvm compiler-rt;
    openmp = self.rocm-openmp;
    comgr = self.rocm-comgr;
    # llvm = pkgs.llvmPackages_7.llvm;
    inherit (python3Packages) python;
  };

  # rocblas-test = callPackage ./development/libraries/rocblas {
  #   inherit (self) rocm-cmake hcc hcc-unwrapped rocr rocblas-tensile;
  #   hip = self.hip;
  #   clang = self.hcc-clang;
  #   openmp = self.hcc-openmp;
  #   comgr = self.amd-comgr;
  #   llvm = pkgs.llvmPackages_7.llvm;
  #   inherit (python3Packages) python;
  #   doCheck = true;
  # };

  # MIOpen

  miopengemm = callPackage ./development/libraries/miopengemm {
    inherit (self) rocm-cmake rocm-opencl-runtime;
    inherit (self.llvmPackages_rocm) clang;
  };

  # # Currently broken
  miopen-cl = callPackage ./development/libraries/miopen {
    inherit (self) rocm-cmake rocm-opencl-runtime rocm-runtime
                   clang-ocl miopengemm rocblas;
    inherit (self.llvmPackages_rocm) clang clang-unwrapped;
    hip = self.hip-clang;
    comgr = self.rocm-comgr;
  };

  miopen-hip = self.miopen-cl.override {
    useHip = true;
  };

  rocfft = callPackage ./development/libraries/rocfft {
    inherit (self) rocm-runtime rocminfo rocm-cmake;
    inherit (self.llvmPackages_rocm) clang;
    hip = self.hip-clang;
    comgr = self.rocm-comgr;
  };

  rccl = callPackage ./development/libraries/rccl {
    inherit (self) rocm-cmake;
    hip = self.hip-clang;
    comgr = self.rocm-comgr;
  };

  rocrand = callPackage ./development/libraries/rocrand {
    inherit (self) rocm-cmake rocminfo rocm-runtime;
    comgr = self.rocm-comgr;
    hip = self.hip-clang;
  };

  rocrand-python-wrappers = callPackage ./development/libraries/rocrand/python.nix {
    inherit (self) rocm-runtime rocrand;
    inherit (python3Packages) buildPythonPackage numpy;
    hip = self.hip-clang;
  };

  rocprim = callPackage ./development/libraries/rocprim {
    inherit (self) rocm-cmake rocm-runtime;
    # stdenv = pkgs.overrideCC stdenv;
    hip = self.hip-clang;
  };

  hipcub = callPackage ./development/libraries/hipcub {
    inherit (self) rocm-cmake rocprim;
    hip = self.hip-clang;
  };

  rocsparse = callPackage ./development/libraries/rocsparse {
    inherit (self) rocprim hipcub rocm-cmake;
    hip = self.hip-clang;
    comgr = self.rocm-comgr;
  };

  hipsparse = callPackage ./development/libraries/hipsparse {
    inherit (self) rocm-runtime rocsparse rocm-cmake;
    hip = self.hip-clang;
    comgr = self.rocm-comgr;
  };

  rocthrust = callPackage ./development/libraries/rocthrust {
    inherit (self) rocm-cmake rocprim;
    hip = self.hip-clang;
    comgr = self.rocm-comgr;
  };

  # roctracer = callPackage ./development/tools/roctracer {
  #   inherit (self) hcc-unwrapped rocm-thunk rocm-runtime;
  #   hip = self.hip;
  #   inherit (pkgs.pythonPackages) python buildPythonPackage fetchPypi ply;
  # };

  # rocprofiler = callPackage ./development/tools/rocprofiler {
  #   inherit (self) rocm-runtime rocm-thunk roctracer hcc-unwrapped;
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

  tensorflow-rocm = python37Packages.callPackage ./development/libraries/tensorflow/bin.nix {
    inherit (self) miopen-hip miopengemm rocrand
                   rocfft rocblas rocm-runtime rccl cxlactivitylogger;
    hip = self.hip-clang;
  };

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
  #                  rocfft rocblas rocm-runtime rccl cxlactivitylogger;
  #   hip = self.hip;
  # };

  # pytorch-rocm = python37Packages.callPackage ./development/libraries/pytorch/default.nix {
  #   inherit (self) rocm-runtime miopengemm rocsparse hipsparse rocthrust
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

  # Deprecated names
  rocm-clang = builtins.trace "'rocm-clang' was renamed to 'llvmPackages_rocm.clang'" self.llvmPackages_rocm.clang;
  rocm-clang-unwrapped = builtins.trace "'rocm-clang-unwrapped' was renamed to 'llvmPackages_rocm.clang-unwrapped'" self.llvmPackages_rocm.clang-unwrapped;
  rocm-lld = builtins.trace "'rocm-lld' was renamed to 'llvmPackages_rocm.lld'" self.llvmPackages_rocm.lld;
  rocm-llvm = builtins.trace "'rocm-llvm' was renamed to 'llvmPackages_rocm.llvm'" self.llvmPackages_rocm.llvm;
  rocr = builtins.trace "'rocr' was renamed to 'rocm-runtime'" self.rocm-runtime;
  roct = builtins.trace "'roct' was renamed to 'rocm-thunk'" self.rocm-thunk;
  rocr-ext = throw "rocm-runtime-ext has been removed, since its functionality was added to rocm-runtime"; #added 2020-08-21
}
