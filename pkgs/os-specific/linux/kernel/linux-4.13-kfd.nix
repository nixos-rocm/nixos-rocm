{ stdenv, buildPackages, hostPlatform, fetchFromGitHub, perl, buildLinux, ... } @ args:

let
  ver = "4.13.0";
  revision = "kfd-roc-1.8.0";
in

buildLinux (args // rec {
  version = "${ver}-${revision}";
  modDirVersion = "${ver}";
  extraMeta.branch = "4.13";

  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "ROCK-Kernel-Driver";
    rev = "roc-1.8.0";
    sha256 = "07nsci09zqx3dzgm4hzdcdnp78gm7gap09is8q9m1hhlrcpnf49d";
  };
} // (args.argsOverride or {}))
