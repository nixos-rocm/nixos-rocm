# All packages in the 30_rocm package set that are ready for use.

self: pkgs:

with pkgs;

{

  # The kernel
  linux_4_13_kfd = callPackage ./os-specific/linux/kernel/linux-4.13-kfd.nix {
    kernelPatches =
      [ kernelPatches.bridge_stp_helper
        kernelPatches.p9_fixes
        # See pkgs/os-specific/linux/kernel/cpu-cgroup-v2-patches/README.md
        # when adding a new linux version
        kernelPatches.cpu-cgroup-v2."4.11"
        kernelPatches.modinst_arg_list_too_long
      ]
      ++ lib.optionals ((platform.kernelArch or null) == "mips")
      [ kernelPatches.mips_fpureg_emu
        kernelPatches.mips_fpu_sigill
        kernelPatches.mips_ext3_n32
      ];
  };
  linuxPackages_rocm = self.linuxPackages.extend (kSelf: kSuper: {
    kernel = self.linux_4_13_kfd.override
      (attrs: {
        extraConfig = ''
          KALLSYMS_ALL y
          DRM_AMD_DC y
        '';
      });
  });

  # ROCm needs extra firmware
  rocm_compute_firmware = callPackage ./os-specific/linux/firmware/rocm-compute.nix {};

  # Userspace ROC stack
  roct = callPackage ./development/libraries/roct.nix {};
  rocr = callPackage ./development/libraries/rocr {};
  rocminfo = callPackage ./development/tools/rocminfo.nix {};

  # OpenCL stack
  rocm-opencl-runtime = callPackage ./development/libraries/rocm-opencl-runtime.nix {};
  rocm-opencl-icd = callPackage ./development/libraries/rocm-opencl-icd.nix {};
}
