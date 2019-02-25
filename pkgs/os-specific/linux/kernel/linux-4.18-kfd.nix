{ stdenv, buildPackages, fetchFromGitHub, perl, buildLinux, modDirVersionArg ? null, ... } @ args:

let
  ver = "4.18.0";
  revision = "kfd-roc-2.1.0";
in

buildLinux (args // rec {
  version = "${ver}-${revision}";
  modDirVersion = if (modDirVersionArg == null) then "${ver}-kfd" else modDirVersionArg;
  extraMeta.branch = "4.18";
  defconfig = "rock-rel_defconfig";

  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "ROCK-Kernel-Driver";
    rev = "roc-2.1.0";
    sha256 = "0v5ndh32ags2yzqvjbbc3hpkqv3v8d6p6xc2x9sgfrsizc8ns5pb";
  };
  } // (args.argsOverride or {}))
