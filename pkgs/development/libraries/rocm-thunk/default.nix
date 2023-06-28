{ stdenv
, lib
, fetchFromGitHub
, cmake
, pkg-config
, numactl
, libdrm
}:

stdenv.mkDerivation rec {
  pname = "rocm-thunk";
  version = "5.1.3";

  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "ROCT-Thunk-Interface";
    rev = "rocm-${version}";
    hash = "sha256-Qvbvfe1fhoLTkDnzG0WzfAxbyDoEJwkzVvlBGTBkq0w=";
  };

  preConfigure = ''
    export cmakeFlags="$cmakeFlags "
  '';

  nativeBuildInputs = [ cmake pkg-config ];

  buildInputs = [ numactl libdrm ];

  postInstall = ''
    cp -r $src/include $out
  '';

  meta = with lib; {
    description = "Radeon open compute thunk interface";
    homepage = "https://github.com/RadeonOpenCompute/ROCT-Thunk-Interface";
    license = with licenses; [ bsd2 mit ];
    maintainers = with maintainers; [ acowley danieldk ];
  };
}
