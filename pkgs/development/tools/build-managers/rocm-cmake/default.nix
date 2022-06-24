{ stdenv, lib, fetchFromGitHub, cmake }:

stdenv.mkDerivation rec {
  pname = "rocm-cmake";
  version = "5.1.3";

  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "rocm-cmake";
    rev = "rocm-${version}";
    hash = "sha256-7jLn0FIjsww1lu1J9MB0s/Ksnw66BL1U0jQwiwmgw64=";
  };

  nativeBuildInputs = [ cmake ];

  meta = with lib; {
    description = "CMake modules for common build tasks for the ROCm stack";
    homepage = "https://github.com/RadeonOpenCompute/rocm-cmake";
    license = licenses.mit;
    maintainers = with maintainers; [ acowley danieldk ];
    platforms = platforms.linux;
  };
}
