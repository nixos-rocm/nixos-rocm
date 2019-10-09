# Radeon Open Compute (2.9.0) packages for NixOS

## 🚨 Installation Has Changed! 🚨

As of ROCm 2.8, using the `rocm_agent_enumerator` program that is part of the `rocminfo` package no longer works for `nix` builds. Among other checks, the program must be run by a user in the `video` group. Rather than trying to make all `nixbld` users satisfy these requirements, the new arrangement is that we manually specify the GPU targets we are building for. This mechanism is in place in `rocm_agent_enumerator` to support CI configurations that may not have all the required hardware, and so probably also makes sense for `nix` builds. To this end, **we now pass the overlay a list of GPU targets**: e.g. `(import /path/to/nixos-rocm ["gfx900"])`.

## Note on ROCm Hardware Support
Independent of NixOS, the ROCm software stack has a particular hardware requirement for gfx803 (aka Polaris, aka RX570/580/590 GPUs) that is not universally enjoyed: PCI Express 3.0 (PCIe 3.0) with PCIe atomics. This requires that both the CPU and motherboard support atomic operations all the way from the CPU to the GPU (including any PCIe risers or splitters in which the GPU is installed). See the [ROCm documentation](https://github.com/RadeonOpenCompute/ROCm#hardware-support) for more information.

## Installation

This overlay should work with the latest nixos-unstable channel. To use these
packages, clone this repo somewhere and then add `(import /path/to/this/repo ["gfx803"])`
to `nixpkgs.overlays` in `configuration.nix` to target . Other common targets are `"gfx900"` for Vega 10, and `"gfx906"` for Vega 20.

As of ROCm 1.9.0, mainline kernels newer than 4.17 may be used with the ROCm stack.

Add these lines to configuration.nix to enable the ROCm stack:
```
  boot.kernelPackages = pkgs.linuxPackages_5_2;
  hardware.opengl.enable = true;
  hardware.opengl.extraPackages = [ pkgs.rocm-opencl-icd ]
```

After a `nixos-rebuild` and a reboot, both of these should work:
```
  nix-shell -p rocminfo --run rocminfo
  nix-shell -p rocm-opencl-runtime --run clinfo
```

(for the former, it may be necessary to link the rocm overlay into
`~/.config/nixpkgs/overlays/` so that the rocminfo package is available.)

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

So far, this has been tested with a Radeon Vega Frontier Edition, an RX 580, and a Radeon VII.  Other cards supported by the upstream ROCm should also work, but have not been tested. Please let us know if we can expand the list of expected-to-work hardware!

## Highlights of Included Software

Libraries and compilers for: [OpenCL](https://github.com/RadeonOpenCompute/ROCm-OpenCL-Runtime), [HCC](https://github.com/RadeonOpenCompute/hcc), [HIP](https://github.com/ROCm-Developer-Tools/HIP), and [TensorFlow](https://github.com/ROCmSoftwarePlatform/tensorflow-upstream).
