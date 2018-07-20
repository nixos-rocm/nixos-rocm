{ stdenv, rocm-opencl-runtime, writeText }:

stdenv.mkDerivation rec {
  version = "1.8.2";
  name = "rocm-opencl-icd";
  src = writeText "amdocl64.icd" "${rocm-opencl-runtime}/lib/libamdocl64.so";
  unpackPhase = ":";
  installPhase = ''
    mkdir -p $out/etc/OpenCL/vendors
    cp $src $out/etc/OpenCL/vendors/amdocl64.icd
  '';
}
