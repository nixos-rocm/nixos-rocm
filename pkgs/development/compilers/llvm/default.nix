# Adpated from the nixpkgs expression for llvm 6
{ stdenv, fetchFromGitHub, cmake, python
, libxml2, libffi, libbfd, ncurses, zlib
, debugVersion ? false
, enableManpages ? false
, enableSharedLibraries ? true
, name ? "rocm-llvm"
, version ? "2.0.0"
, src}:
stdenv.mkDerivation rec {
  inherit name version src;

  outputs = [ "out" "python" ]
    ++ stdenv.lib.optional enableSharedLibraries "lib";
  nativeBuildInputs = [ cmake python ];
  buildInputs = [ libxml2 libffi ];
  propagatedBuildInputs = [ ncurses zlib ];

  postPatch = stdenv.lib.optionalString stdenv.isDarwin ''
    substituteInPlace cmake/modules/AddLLVM.cmake \
      --replace 'set(_install_name_dir INSTALL_NAME_DIR "@rpath")' "set(_install_name_dir INSTALL_NAME_DIR "$lib/lib")" \
      --replace 'set(_install_rpath "@loader_path/../lib" ''${extra_libdir})' ""
  ''
  # Patch llvm-config to return correct library path based on --link-{shared,static}.
  + stdenv.lib.optionalString (enableSharedLibraries) ''
    substitute '${./llvm-outputs.patch}' ./llvm-outputs.patch --subst-var lib
    patch -p1 < ./llvm-outputs.patch
  '';

  # hacky fix: created binaries need to be run before installation
  preBuild = ''
    mkdir -p $out/
    ln -sv $PWD/lib $out
  '';

  cmakeFlags = with stdenv; [
    "-DCMAKE_BUILD_TYPE=${if debugVersion then "Debug" else "Release"}"
    "-DLLVM_INSTALL_UTILS=ON"  # Needed by rustc
    "-DLLVM_BUILD_TESTS=OFF"
    "-DLLVM_ENABLE_FFI=ON"
    "-DLLVM_ENABLE_RTTI=ON"
    "-DLLVM_ENABLE_DUMP=ON"
    "-DLLVM_TARGETS_TO_BUILD=AMDGPU;X86"
  ]
  ++ stdenv.lib.optional enableSharedLibraries
    "-DLLVM_LINK_LLVM_DYLIB=ON"
  ++ stdenv.lib.optionals enableManpages [
    "-DLLVM_BUILD_DOCS=ON"
    "-DLLVM_ENABLE_SPHINX=ON"
    "-DSPHINX_OUTPUT_MAN=ON"
    "-DSPHINX_OUTPUT_HTML=OFF"
    "-DSPHINX_WARNINGS_AS_ERRORS=OFF"
  ]
  ++ stdenv.lib.optional (!isDarwin)
    "-DLLVM_BINUTILS_INCDIR=${libbfd.dev}/include"
  ++ stdenv.lib.optionals (isDarwin) [
    "-DLLVM_ENABLE_LIBCXX=ON"
    "-DCAN_TARGET_i386=false"
  ]
  ;

  postBuild = ''
    rm -fR $out
    paxmark m bin/{lli,llvm-rtdyld}
    paxmark m bin/lli-child-target
  '';

  preCheck = ''
    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$PWD/lib
  '';

  postInstall = ''
    mkdir -p $python/share
    mv $out/share/opt-viewer $python/share/opt-viewer
  ''
  + stdenv.lib.optionalString enableSharedLibraries ''
    moveToOutput "lib/libLLVM-*" "$lib"
    moveToOutput "lib/libLLVM${stdenv.hostPlatform.extensions.sharedLibrary}" "$lib"
    substituteInPlace "$out/lib/cmake/llvm/LLVMExports-${if debugVersion then "debug" else "release"}.cmake" \
      --replace "\''${_IMPORT_PREFIX}/lib/libLLVM-" "$lib/lib/libLLVM-"
  ''
  + stdenv.lib.optionalString (stdenv.isDarwin && enableSharedLibraries) ''
    substituteInPlace "$out/lib/cmake/llvm/LLVMExports-${if debugVersion then "debug" else "release"}.cmake" \
      --replace "\''${_IMPORT_PREFIX}/lib/libLLVM.dylib" "$lib/lib/libLLVM.dylib"
    ln -s $lib/lib/libLLVM.dylib $lib/lib/libLLVM-${version}.dylib
    ln -s $lib/lib/libLLVM.dylib $lib/lib/libLLVM-${version}.dylib
  '';

  # doCheck = stdenv.isLinux && (!stdenv.isi686);
  doCheck = false;

  checkTarget = "check-all";

  enableParallelBuilding = true;

  passthru.src = src;

}
