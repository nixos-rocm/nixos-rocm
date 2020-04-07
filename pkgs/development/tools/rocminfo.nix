{ stdenv, fetchFromGitHub, fetchpatch, cmake, rocr, python, rocm-cmake, busybox, gnugrep
  # rocminfo requires that the calling user have a password and be in
  # the video group. If we let rocm_agent_enumerator rely upon
  # rocminfo's output, then it, too, has those requirements. Instead,
  # we can specify the GPU targets for this system (e.g. "gfx803" for
  # Polaris) such that no system call is needed for downstream
  # compilers to determine the desired target.
, defaultTargets ? []}:
stdenv.mkDerivation rec {
  version = "3.3.0";
  pname = "rocminfo";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "rocminfo";
    rev = "rocm-${version}";
    sha256 = "1cr4x02s564w8sxdyjmpcl1dm6sb4zg6cdpdbbcr1iqm7cbb8z8p";
  };

  enableParallelBuilding = true;
  buildInputs = [ cmake rocm-cmake ];
  cmakeFlags = [
    "-DROCM_DIR=${rocr}"
    "-DROCRTST_BLD_TYPE=Release"
  ];

  prePatch = ''
    sed 's,#!/usr/bin/python,#!${python}/bin/python,' -i rocm_agent_enumerator
    sed 's,lsmod | grep ,${busybox}/bin/lsmod | ${gnugrep}/bin/grep ,' -i rocminfo.cc
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp rocminfo $out/bin
    cp rocm_agent_enumerator $out/bin
  '' + stdenv.lib.optionalString (defaultTargets != []) ''
    echo '${stdenv.lib.concatStringsSep "\n" defaultTargets}' > $out/bin/target.lst
  '';
}
