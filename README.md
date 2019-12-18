# Radeon Open Compute (2.10.0) packages for NixOS

## 🚨 Installation Has Changed! 🚨

As of ROCm 2.8, using the `rocm_agent_enumerator` program that is part of the `rocminfo` package no longer works for `nix` builds. Among other checks, the program must be run by a user in the `video` group. Rather than trying to make all `nixbld` users satisfy these requirements, the new arrangement is that we manually specify the GPU targets we are building for. This mechanism already exists as part of `rocm_agent_enumerator` to support CI configurations that may not have all the required hardware, and so probably also makes sense for `nix` builds. To this end, we now provide a list of GPU targets for the ROCm overlay in the `nixpkgs.config.rocmTargets` field. 

## Installation

This overlay should work with the latest nixos-unstable channel. To use these
packages, clone this repo somewhere and then add `(import /path/to/this/repo)`
to `nixpkgs.overlays` in `configuration.nix`, or in `~/.config/nixpkgs/overlays.nix` (see [the manual](https://nixos.org/nixpkgs/manual/#chap-overlays) for more information on overlays). To specify GPU compilation targets, your `~/.config/nixpkgs/config.nix` can include a `rocmTargets` field that lists GPU targets. An example fragment is shown here; the essential line is the definition of the `rocmTarget` field. The list shown here is the default list of targets used if you do not include this definition in your `config.nix`.

```
{
  allowUnfree = true;
  rocmTargets = ["gfx803" "gfx900" "gfx906"];
  packageOverrides = ...
}
```

The named GPU targets are the common ones for RX480/RX580 GPUs, Vega 10, and Vega 20. You can include only the specific one you need if you prefer.

As of ROCm 1.9.0, mainline kernels newer than 4.17 may be used with the ROCm stack.

Add these lines to `configuration.nix` to enable the ROCm stack (you might also use `pkgs.linuxPackages_5_4`):
```
  boot.kernelPackages = pkgs.linuxPackages_5_3;
  hardware.opengl.enable = true;
  hardware.opengl.extraPackages = [ pkgs.rocm-opencl-icd ]
```

After a `nixos-rebuild` and a reboot, both of these should work:
```
  nix-shell -p rocminfo --run rocminfo
  nix-shell -p rocm-opencl-runtime --run clinfo
```

OpenCL applications should work, and `glxinfo` should report that the Mesa
stack is running hardware-accelerated on an AMD gpu.

### OpenCL Image Support
You may notice that `clinfo` reports a lack of `Image support`. This is because AMD has not open sourced this component of their OpenCL driver. You may make use of the closed-source component by bringing the `rocr-ext` package into scope.
```
nix-shell -p rocr-ext rocm-opencl-runtime --run clinfo
```

### `rocblas`, `rocfft`, and the Sandbox

The `rocblas` and `rocfft` packages (and those that depend upon them) require a bit of additional configuration. The `nix` builder sandbox must be expanded to allow for build-time inspection of the current system for these packages to build. This may be achieved by adding the following lines to your `/etc/nix/configuration.nix` (with the caveat that your AMD GPU may not be at `/dev/dri/renderD128`):
```
  nix.sandboxPaths = [ 
    "/dev/kfd" 
    "/sys/devices/virtual/kfd" 
    "/dev/dri/renderD128"
  ];

```

## Hardware support

So far, this has been tested with Radeon Vega Frontier Edition, RX 580, and Radeon VII GPUs.  Other cards supported by the upstream ROCm should also work, but have not been tested. Please let us know if we can expand the list of expected-to-work hardware!

Independent of NixOS, the ROCm software stack has a particular hardware requirement for gfx803 (aka Polaris, aka RX570/580/590 GPUs) that is not universally enjoyed: PCI Express 3.0 (PCIe 3.0) with PCIe atomics. This requires that both the CPU and motherboard support atomic operations all the way from the CPU to the GPU (including any PCIe risers or splitters in which the GPU is installed). See the [ROCm documentation](https://github.com/RadeonOpenCompute/ROCm#hardware-support) for more information.

## Highlights of Included Software

Libraries and compilers for: 

* [OpenCL](https://github.com/RadeonOpenCompute/ROCm-OpenCL-Runtime)
* [HCC](https://github.com/RadeonOpenCompute/hcc)
* [HIP](https://github.com/ROCm-Developer-Tools/HIP)
* [pytorch](https://github.com/ROCmSoftwarePlatform/pytorch) (Note that AMD's ROCm port of pytorch does not support current pytorch extension mechanisms for C++ or CUDA plugins, so many libraries that depend upon pytorch will not work.)
* [TensorFlow](https://github.com/ROCmSoftwarePlatform/tensorflow-upstream)

## Miscellaneous Notes and Workarounds

The ROCm suite of libraries and compilers is still somewhat immature and changing rapidly. This brings with it some irregularities due to upstream quirks, and means that our packaging is always racing to keep up with the rapid rate of change. These are notes on problems you may run into as a ROCm user.

-  When running things like pytorch or tensorflow that rely upon MIOpen on a gfx803 GPU, you may need to set the environment variable `MIOPEN_DEBUG_CONV_IMPLICIT_GEMM=0` to avoid an error like `Failed to get function: gridwise_convolution_implicit_gemm_v4_nchw_kcyx_nkhw_lds_double_buffer`.
