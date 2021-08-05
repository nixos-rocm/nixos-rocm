{ stdenv
, lib
, fetchFromGitHub
, cmake
, rocm-cmake
, clang
, rocm-comgr
, rocm-opencl-runtime
, rocm-runtime
, rocm-thunk
, libelf
, libglvnd
, libX11
, numactl
}:

stdenv.mkDerivation rec {
  pname = "rocclr";
  version = "4.3.0";

  src = fetchFromGitHub {
    owner = "ROCm-Developer-Tools";
    repo = "ROCclr";
    rev = "rocm-${version}";
    hash = "sha256-3lk7Zucoam+11gFBzg/TWQI1L8uAlxTrPz/mDwTwod4=";
  };

  nativeBuildInputs = [ cmake rocm-cmake ];

  buildInputs = [ clang rocm-comgr rocm-runtime rocm-thunk ];

  propagatedBuildInputs = [ libelf libglvnd libX11 numactl ];

  prePatch = ''
    substituteInPlace CMakeLists.txt \
      --replace 'set (CMAKE_LIBRARY_OUTPUT_DIRECTORY ''${CMAKE_CURRENT_BINARY_DIR}/lib)' \
        'set (CMAKE_LIBRARY_OUTPUT_DIRECTORY ''${CMAKE_INSTALL_LIBDIR})' \
      --replace '"''${CMAKE_CURRENT_BINARY_DIR}/''${ROCCLR_PACKAGE_PREFIX}' \
        '"''${CMAKE_INSTALL_PREFIX}/''${ROCCLR_PACKAGE_PREFIX}'
    substituteInPlace device/comgrctx.cpp \
      --replace "libamd_comgr.so" "${rocm-comgr}/lib/libamd_comgr.so"
  '';

  cmakeFlags = [
    "-DOPENCL_DIR=${rocm-opencl-runtime.src}"
  ];

  preFixup = ''
    # Work around broken cmake files
    ln -s $out/include/compiler/lib/include/* $out/include
    ln -s $out/include/elf/elfio $out/include/elfio

    substituteInPlace $out/lib/cmake/rocclr/rocclr-targets.cmake \
      --replace "/build/source/build" "$out/lib" \
      --replace "/build/source/include" "$out/include" \
      --replace "/build/source" "$out/include"
  '';

  meta = with lib; {
    description = "Radeon Open Compute common language runtime";
    homepage = "https://github.com/ROCm-Developer-Tools/ROCclr";
    license = licenses.mit;
    maintainers = with maintainers; [ acowley danieldk ];
    # rocclr seems to have some AArch64 ifdefs, but does not seem
    # to be supported yet by the build infrastructure. Recheck in
    # the future.
    platforms = [ "x86_64-linux" ];
  };
}
