# Radeon Open Compute (2.1.0) packages for NixOS

## Installation

This overlay should work with the latest nixos-unstable channel. To use these
packages, clone this repo somewhere and then add `(import /path/to/this/repo)`
to `nixpkgs.overlays` in `configuration.nix`.

As of ROCm 1.9.0, mainline kernels newer than 4.17 may be used with the ROCm stack.

Add these lines to configuration.nix to enable the ROCm stack:
```
  boot.kernelPackages = pkgs.linuxPackages_4_19;
  hardware.opengl.enable = true;
  hardware.opengl.extraPackages = [ pkgs.rocm-opencl-icd ]
```

After a `nixos-rebuild` and a reboot, both of these should work:
```
  nix-shell -p rocminfo --run rocminfo
  nix-shell -p rocm-opencl-runtime --run clinfo
```

(for the former, it may be necessary to link the rocm overlay into
~/.config/nixpkgs/overlays/ so that the rocminfo package is available.)

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

So far, this has been tested with a Radeon Vega Frontier Edition and an RX 580.  Other cards supported by the upstream ROCm should also work, but have not been tested. Please let us know if we can expand the list of expected-to-work hardware!

## Highlights of Included Software

Libraries and compilers for: [OpenCL](https://github.com/RadeonOpenCompute/ROCm-OpenCL-Runtime), [HCC](https://github.com/RadeonOpenCompute/hcc), [HIP](https://github.com/ROCm-Developer-Tools/HIP), and [TensorFlow](https://github.com/ROCmSoftwarePlatform/tensorflow-upstream).
