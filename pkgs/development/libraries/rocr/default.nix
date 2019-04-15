{ stdenv, fetchFromGitHub, cmake, elfutils, roct }:

stdenv.mkDerivation rec {
  version = "2.3.0";
  name = "rocr-${version}";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "ROCR-Runtime";
    rev = "roc-${version}";
    sha256 = "0610rxhvqxqpcr40fwbmr2alhbqqbkl2hs0q0xy16hrqy4z1j5g9";
  };

  postUnpack = ''
    sourceRoot="$sourceRoot/src"
  '';

  # Use the ROCR_EXT_DIR environment variable to try to find
  # binary-only extension libraries. This environment variable is set
  # by the `rocr-ext` derivation. If that derivation is not in scope,
  # then the extension libraries are not loaded. Without this edit, we
  # would have to rely on LD_LIBRARY_PATH to let the HSA runtime
  # discover the shared libraries.
  patchPhase = ''
    sed 's/\(k\(Image\|Finalizer\)Lib\[os_index(os::current_os)\]\)/os::GetEnvVar("ROCR_EXT_DIR") + "\/" + \1/g' -i core/runtime/runtime.cpp
  '';

  enableParallelBuilding = true;
  buildInputs = [ cmake elfutils ];
  cmakeFlags = [ "-DCMAKE_PREFIX_PATH=${roct}" ];

  fixupPhase = ''
    rm -r $out/lib $out/include
    mv $out/hsa/lib $out/hsa/include $out
  '';
}
