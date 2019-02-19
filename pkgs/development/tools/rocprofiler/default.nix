{stdenv, fetchFromGitHub, cmake, rocr, roct, python}:
let pyenv = python.withPackages (ps: [ps.sqlite3dbm]); in
stdenv.mkDerivation rec {
  name = "rocprofiler";
  version = "2.1.0";
  src = fetchFromGitHub {
    owner = "ROCm-Developer-Tools";
    repo = "rocprofiler";
    rev = "roc-${version}";
    sha256 = "074hr344gqz69yh9fm4p2scy81bs1m5f5nxlcxq54kkp98k727li";
  };
  nativeBuildInputs = [ cmake ];
  buildInputs = [ rocr roct pyenv ];
  patchPhase = ''
    patchShebangs test/run.sh
    patchShebangs bin
    sed 's|#!/usr/bin/python|#!${pyenv}/bin/python|' -i bin/dform.py
    sed 's|/usr/bin/clang++|clang++|' -i cmake_modules/env.cmake
    sed -e 's|/bin/ls|ls|' \
        -e 's|\([[:space:]]\)python\([[:space:]]\)|\1${pyenv}/bin/python\2|g' \
        -i bin/rpl_run.sh
  '';
}
