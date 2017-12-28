{ stdenv, fetchurl }:

stdenv.mkDerivation rec {
  version = "1.7.15";
  name = "rocm-firmware-${version}";
  src = fetchurl {
    url = "http://repo.radeon.com/rocm/apt/debian/pool/main/c/compute-firmware/compute-firmware_1.7.15_all.deb";
    sha256 = "09xsvjq5ffijm8jhdncbwhmykc016ciyk024r5z8lb1dnbpbiq4d";
  };
 
  unpackPhase = ''
    ar p $src data.tar.xz | tar -xJ
  '';

  installPhase = ''
    mkdir -p $out/lib/
    cp -r lib/firmware/ $out/lib/
  '';
}
