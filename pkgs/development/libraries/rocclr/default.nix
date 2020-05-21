{ stdenv, fetchFromGitHub, cmake, rocm-cmake
, libglvnd, libX11, libelf
, roct, rocr, rocm-opencl-src, comgr, clang}:
stdenv.mkDerivation rec {
  pname = "rocclr";
  version = "3.5.0";
  src = fetchFromGitHub {
    owner = "ROCm-Developer-Tools";
    repo = "ROCclr";
    rev = "roc-${version}";
    sha256 = "0j70lxpwrdrb1v4lbcyzk7kilw62ip4py9fj149d8k3x5x6wkji1";
  };
  nativeBuildInputs = [ cmake rocm-cmake ];
  buildInputs = [ roct rocr comgr clang ];
  propagatedBuildInputs = [ libelf libglvnd libX11 ];

  prePatch = ''
    sed -e 's|set(ROCCLR_EXPORTS_FILE "''${CMAKE_CURRENT_BINARY_DIR}/amdrocclr_staticTargets.cmake")|set(ROCCLR_EXPORTS_FILE "''${CMAKE_INSTALL_LIBDIR}/cmake/amdrocclr_staticTargets.cmake")|' \
        -e 's|set (CMAKE_LIBRARY_OUTPUT_DIRECTORY ''${CMAKE_CURRENT_BINARY_DIR}/lib)|set (CMAKE_LIBRARY_OUTPUT_DIRECTORY ''${CMAKE_INSTALL_LIBDIR})|' \
        -i CMakeLists.txt

    sed 's|libamd_comgr.so|${comgr}/lib/libamd_comgr.so|' -i device/comgrctx.cpp
  '';

  cmakeFlags = [
    "-DOPENCL_DIR=${rocm-opencl-src}"
  ];

  preFixup = ''
    mv $out/include/include/* $out/include
    ln -s $out/include/compiler/lib/include/* $out/include/include
    ln -s $out/include/compiler/lib/include/* $out/include
    sed "s|^\([[:space:]]*IMPORTED_LOCATION_RELEASE \).*|\1 \"$out/lib/libamdrocclr_static.a\"|" -i $out/lib/cmake/amdrocclr_staticTargets.cmake
  '';
}
