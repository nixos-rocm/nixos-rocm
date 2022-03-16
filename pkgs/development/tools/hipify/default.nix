{ stdenv, fetchFromGitHub, perl, writeText }:
stdenv.mkDerivation rec {
  pname = "hipify-perl";
  version = "5.0.2";
  src = fetchFromGitHub {
    owner = "ROCm-Developer-Tools";
    repo = "HIPIFY";
    rev = "rocm-${version}";
    hash = "sha256-VLvbVwfbTf5fni7K/kvYQ3VE8l0yuo4I/OQRlwW7loY=";
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
