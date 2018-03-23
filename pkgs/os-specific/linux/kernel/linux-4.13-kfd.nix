{ stdenv, buildPackages, hostPlatform, fetchFromGitHub, perl, buildLinux, ... } @ args:

let
  ver = "4.13.0";
  revision = "kfd-roc-1.7.1";
in

buildLinux (args // rec {
  version = "${ver}-${revision}";
  modDirVersion = "${ver}";
  extraMeta.branch = "4.13";

  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "ROCK-Kernel-Driver";
    rev = "roc-1.7.1";
    sha256 = "03lkqryy6lsw9vvb8z6w4rbvba8dszqdahd3gfzq6yb1vlih8ax9";
  };
} // (args.argsOverride or {}))
