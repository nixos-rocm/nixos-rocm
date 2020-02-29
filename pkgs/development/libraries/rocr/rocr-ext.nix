# AMD has not released the source code for image object support for
# their GPUs. This functionality is available in their binary-only
# releases in the `hsa-ext-rocr-dev` deb package. We unpack the
# compiled libraries from that package here, and set an environment
# variable (`ROCR_EXT_DIR`)to this derivation's `lib` directory. The
# `rocr` runtime uses that environment variable when trying to load
# extension libraries, so that downstream rocr consumers like the
# OpenCL runtime can take advantage of the extension libraries if this
# package is a also a dependency of your derivation.
{ stdenv, fetchurl, writeText, dpkg }:
stdenv.mkDerivation rec {
  version = "3.1.0";
  name = "rocr-ext-${version}";
  src = fetchurl {
    url = "http://repo.radeon.com/rocm/apt/3.1/pool/main/h/hsa-ext-rocr-dev/hsa-ext-rocr-dev_1.1.30100.0-rocm-rel-3.1-35-ecafeba1_amd64.deb";
    sha256 = "0vwcgvgc45z1i5j2ilwzp42h5d29bm7cf8ky6jwa1s201zmxgh3z";
  };
  builder = writeText "builder.sh" ''
    source $stdenv/setup
    ${dpkg}/bin/dpkg-deb -R $src tmp
    cp -R tmp/opt/rocm-${version}/hsa/ $out
    mkdir -p $out/nix-support
    echo "export ROCR_EXT_DIR=$out/lib" > $out/nix-support/setup-hook
  '';
  meta = {
    description = "Closed-source runtime extension package";
    homepage = https://github.com/RadeonOpenCompute/ROCR-Runtime;
    license = stdenv.lib.licenses.unfreeRedistributable;
  };
}
