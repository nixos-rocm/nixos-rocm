{ stdenv, fetchurl }:

stdenv.mkDerivation rec {
  version = "1.7.17";
  name = "rocm-firmware-${version}";
  src = fetchurl {
    url = "http://repo.radeon.com/rocm/apt/debian/pool/main/c/compute-firmware/compute-firmware_${version}_all.deb";
    sha256 = "0bq2mbqbqmvsxf2i06q6lh3r4wfy4ryx7nz5kwryldksbjp4ghw1";
  };

  unpackPhase = ''
    ar p $src data.tar.xz | tar -xJ
  '';

  installPhase = ''
    mkdir -p $out/lib/
    cp -r lib/firmware/ $out/lib/
  '';
}
