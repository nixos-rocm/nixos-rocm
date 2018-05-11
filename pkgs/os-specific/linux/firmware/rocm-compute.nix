{ stdenv, fetchurl }:

stdenv.mkDerivation rec {
  version = "1.7.18";
  name = "rocm-firmware-${version}";
  src = fetchurl {
    url = "http://repo.radeon.com/rocm/apt/debian/pool/main/c/compute-firmware/compute-firmware_${version}_all.deb";
    sha256 = "1r1qj49iz1jfwlz7rz0js6zl2sy166gvya3jmgzrcc90q0dg92hy";
  };

  unpackPhase = ''
    ar p $src data.tar.xz | tar -xJ
  '';

  installPhase = ''
    mkdir -p $out/lib/
    cp -r lib/firmware/ $out/lib/
  '';
}
