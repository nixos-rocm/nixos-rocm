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
  roct = callPackage ./development/libraries/roct.nix {};
  rocr = callPackage ./development/libraries/rocr { inherit (self) roct; };
  rocr-ext = callPackage ./development/libraries/rocr/rocr-ext.nix {};
  rocm-cmake = callPackage ./development/tools/rocm-cmake.nix {};
  rocminfo = callPackage ./development/tools/rocminfo.nix {
    inherit (self) rocm-cmake rocr;
    defaultTargets = config.rocmTargets or ["gfx803" "gfx900" "gfx906"];
  };

# I wonder if we could fetch the source for the llvm-project monorepo,
# then use subdirectories of that as the source directories for the
# individual builds.

  # ROCm LLVM, LLD, and Clang
  rocm-llvm-project = tag: sha256: fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "llvm-project";
    rev = "roc-${tag}-3.0.0";
    inherit sha256;
  };

  rocm-llvm-project-ocl = self.rocm-llvm-project "ocl" "0hxdk8cwwzxw0vha65bsqsav98i2sspi0fk43jhvh27nl4lxdw33";
  rocm-llvm-project-hcc = self.rocm-llvm-project "hcc" "1zxjdv526gf5wqynsixxnp3zpbbcdll7dhxp27mha8mq3jsnandh";

  rocm-llvm = callPackage ./development/compilers/llvm rec {
    version = "3.0.0";
    src = "${self.rocm-llvm-project-ocl}/llvm";
  };
  rocm-lld = self.callPackage ./development/compilers/lld rec {
    name = "rocm-lld";
    version = "3.0.0";
    src = "${self.rocm-llvm-project-ocl}/lld";
    llvm = self.rocm-llvm;
  };
  rocm-clang-unwrapped = callPackage ./development/compilers/clang rec {
    name = "clang-unwrapped";
    version = "3.0.0";
    src = "${self.rocm-llvm-project-ocl}/clang";
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

  # OpenCL stack
  rocm-device-libs = callPackage ./development/libraries/rocm-device-libs {
    inherit (self) rocr;
    stdenv = pkgs.overrideCC stdenv self.rocm-clang;
    llvm = self.rocm-llvm;
    clang = self.rocm-clang;
    lld = self.rocm-lld;
    tagPrefix = "roc-ocl";
    sha256 = "07xhywpdd6d073q1px81cl2zf0cyll37air2dj1h8s9kbm48wc0q";
  };
  # rocm-opencl-driver = callPackage ./development/libraries/rocm-opencl-driver {
  #   stdenv = pkgs.overrideCC stdenv self.rocm-clang;
  #   inherit (self) rocm-lld rocm-llvm rocm-clang-unwrapped;
  # };
  rocm-ocl-comgr = (callPackage ./development/libraries/comgr {
    llvm = self.rocm-llvm;
    lld = self.rocm-lld;
    clang = self.rocm-clang;
    device-libs = self.rocm-device-libs;
  });

  rocm-opencl-runtime = callPackage ./development/libraries/rocm-opencl-runtime.nix {
    stdenv = pkgs.overrideCC stdenv self.rocm-clang;
    inherit (self) roct rocm-clang rocm-clang-unwrapped rocm-device-libs;
    inherit (self) rocm-lld rocm-llvm rocr;
    comgr = self.rocm-ocl-comgr;
  };
  rocm-opencl-icd = callPackage ./development/libraries/rocm-opencl-icd.nix {
    inherit (self) rocm-opencl-runtime;
  };

  # HCC

  # hcc relies on submodules for llvm, clang, and compiler-rt at
  # specific revisions that do not track ROCm releases. We break the
  # hcc build into parts to make it a bit more manageable when dealing
  # with failures, and to have an opportunity to wrap hcc-clang before
  # hcc tools are built using that compiler.
  hcc-llvm = callPackage ./development/compilers/llvm rec {
    name = "hcc-llvm";
    version = "3.0.0";
    src = "${self.rocm-llvm-project-hcc}/llvm";
  };
  hcc-lld = callPackage ./development/compilers/lld {
    name = "hcc-lld";
    version = "3.0.0";
    src = "${self.rocm-llvm-project-hcc}/lld";
    llvm = self.hcc-llvm;
  };
  hcc-clang-unwrapped = callPackage ./development/compilers/hcc-clang {
    inherit (self) rocr rocminfo hcc-llvm hcc-lld;
    version = "3.0.0";
    src = "${self.rocm-llvm-project-hcc}/clang";
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
    src = "${self.rocm-llvm-project-hcc}/compiler-rt";
    inherit (self) hcc-llvm;
  };
  hcc-device-libs = callPackage ./development/libraries/rocm-device-libs {
    inherit (self) rocr;
    stdenv = pkgs.overrideCC stdenv self.hcc-clang;
    llvm = self.hcc-llvm;
    clang = self.hcc-clang;
    lld = self.hcc-lld;
    tagPrefix = "roc-hcc";
    sha256 = "1f4jl14164g2x4iqmiaj284msdp12qj4fin5ks0jsqiwgv6fnjna";
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
  });

  hip = callPackage ./development/compilers/hip {
    inherit (self) roct rocr rocminfo hcc hcc-unwrapped;
    # comgr = self.hcc-comgr;
    comgr = self.amd-comgr;
  };

  hcc-openmp = pkgs.llvmPackages_9.openmp.override {
    llvm = self.hcc-llvm;
  };

  # HIP's clang backend requires the `amd-common` branches of the
  # LLVM, LLD, and Clang forks.

  rocm-llvm-project-amd = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "llvm-project";
    # 2019-12-30
    rev = "0b668a1616cb52927f46587d057029d0a73255c8";
    sha256 = "1q0g2g7f15h7xzkawqkzbypicvicb52vxrkdlqhypirwck4glh5g";
  };

  # The amd-common branch of the llvm fork
  amd-llvm = callPackage ./development/compilers/llvm rec {
    name = "amd-llvm";
    version = "20191230";
    src = "${self.rocm-llvm-project-amd}/llvm";
  };

  # The amd-common branch of the lld fork
  amd-lld = callPackage ./development/compilers/lld {
    name = "amd-lld";
    version = "20191230";
    src = "${self.rocm-llvm-project-amd}/lld";
    llvm = self.amd-llvm;
  };

  amd-openmp = pkgs.llvmPackages_9.openmp.override {
    llvm = self.amd-llvm;
  };

  # The amd-common branch of the clang fork
  amd-clang-unwrapped = (callPackage ./development/compilers/clang {
    name = "amd-clang";
    version = "20191230";
    src = "${self.rocm-llvm-project-amd}/clang";
    inherit (self) rocr;
    llvm = self.amd-llvm;
    lld = self.amd-lld;
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
    inherit (self) rocr;
    stdenv = pkgs.overrideCC stdenv self.amd-clang;
    llvm = self.amd-llvm;
    clang = self.amd-clang;
    lld = self.amd-lld;
    source = pkgs.fetchFromGitHub {
      owner = "RadeonOpenCompute";
      repo = "ROCm-Device-Libs";
      rev = "628eea44063452c5c7fcea6432d35efd8d302548";
      sha256 = "07xhywpdd6d073q1px81cl2zf0cyll37air2dj1h8s9kbm48wc0q";
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
  });

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
    inherit (self) rocm-cmake rocm-device-libs rocm-lld rocm-llvm;
    inherit (self) hcc hcc-clang-unwrapped rocm-opencl-runtime;
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
    inherit (self) rocm-cmake hcc hcc-unwrapped rocr rocblas-tensile;
    hip = self.hip;
    # comgr = self.hcc-comgr;
    clang = self.hcc-clang;
    # llvm = self.hcc-llvm;
    openmp = self.hcc-openmp;

    # hip = self.hip-clang;
    comgr = self.amd-comgr;
    # clang = self.amd-clang;
    # # llvm = self.amd-llvm;
    # openmp = self.amd-openmp;

    llvm = pkgs.llvmPackages_6.llvm;
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
    hip = self.hip;
    clang = self.hcc-clang;

    # hip = self.hip-clang;
    comgr = self.amd-comgr;
    # clang = self.amd-clang;
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
    comgr = self.amd-comgr;
    hip = self.hip;
  };
  rocrand-python-wrappers = callPackage ./development/libraries/rocrand/python.nix {
    inherit (self) rocr rocrand;
    inherit (python3Packages) buildPythonPackage numpy;
    hip = self.hip;
  };

  rocprim = callPackage ./development/libraries/rocprim {
    inherit (self) rocm-cmake rocr;
    stdenv = pkgs.overrideCC stdenv self.hcc;
    hip = self.hip;
  };

  hipcub = callPackage ./development/libraries/hipcub {
    inherit (self) hcc hip rocm-cmake rocprim;
  };

  rocsparse = callPackage ./development/libraries/rocsparse {
    inherit (self) rocprim hipcub rocm-cmake hcc;
    hip = self.hip;
    comgr = self.amd-comgr;
  };

  hipsparse = callPackage ./development/libraries/hipsparse {
    inherit (self) rocr rocsparse rocm-cmake hcc;
    hip = self.hip;
    comgr = self.amd-comgr;
  };

  rocthrust = callPackage ./development/libraries/rocthrust {
    inherit (self) rocm-cmake rocprim;
    hip = self.hip;
    comgr = self.amd-comgr;
  };

  roctracer = callPackage ./development/tools/roctracer {
    inherit (self) hcc-unwrapped roct rocr;
    hip = self.hip;
  };

  rocprofiler = callPackage ./development/tools/rocprofiler {
    inherit (self) rocr roct roctracer hcc-unwrapped;
  };

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
    inherit (self) rocr miopengemm rocsparse hipsparse rocthrust
      rccl rocrand rocblas rocfft rocprim hipcub roctracer rocm-cmake;
    miopen = self.miopen-hip;
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

  rocm-llvm-project-aomp = fetchFromGitHub {
    owner = "ROCm-Developer-Tools";
    repo = "llvm-project";
    rev = "roc-aomp-3.0.0";
    sha256 = "00cw8azj2jh7zs79klk6zcrw76dkiplrignazl9lavyr9qcbiy7v";
  };
}
