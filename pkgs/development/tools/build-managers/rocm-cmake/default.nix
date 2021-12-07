{ stdenv, lib, fetchFromGitHub, cmake }:

stdenv.mkDerivation rec {
  pname = "rocm-cmake";
  version = "4.5.0";

  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "rocm-cmake";
    rev = "rocm-${version}";
    hash = "sha256-5RwhIIOtqeMl/Gyufl5U1gTEpoCjdPJP5MbVnhEKYMM=";
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
