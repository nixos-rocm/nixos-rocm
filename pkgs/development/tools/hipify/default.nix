{ stdenv, fetchFromGitHub, perl, writeText }:
stdenv.mkDerivation rec {
  pname = "hipify-perl";
  version = "4.5.0";
  src = fetchFromGitHub {
    owner = "ROCm-Developer-Tools";
    repo = "HIPIFY";
    rev = "rocm-${version}";
    hash = "sha256-SBNYHuMvwNwqUNoxjMhq0XPWLC8wn/YZoQuYOW2BJIU=";
  };
  prePatch = ''
    substituteInPlace bin/hipify-perl \
      --replace "#!/usr/bin/env perl" "#!${perl}/bin/perl"
  '';
  installPhase = ''
    mkdir -p $out/bin
    cp bin/hipify-perl $out/bin
  '';
}
