{ stdenv, fetchFromGitHub, scons, amdtbasetools, amdtoswrappers }:
let srcs = {
  logger = fetchFromGitHub {
    owner = "GPUOpen-Tools";
    repo = "common-src-AMDTActivityLogger";
    rev = "97621e32a32c068e42304f2115043df51bc4824f";
    sha256 = "0022zm3iz6gfdapn5bmi4yj4zh20hgrvxjbk8f6mr12b2s1z1bxw";
  };
  common = fetchFromGitHub {
    owner = "GPUOpen-Tools";
    repo = "common-src-SCons";
    rev = "e9c301ef944a3449a316fc4bf109c1cae2a758d8";
    sha256 = "0mc2bm9n4ixvmwycf5pv5hz8ik7v8lhnfg9g34by1l4kvxswzbm3";
  };
  tsingleton = fetchFromGitHub {
    owner = "GPUOpen-Tools";
    repo = "common-src-TSingleton";
    rev = "ebde730c07eac1c1da7f486d65517b93e1550edb";
    sha256 = "1fz6xdml64p7n9ig3qiyjrr58ylmyx4m7bci7g1nv2s0mx3cq02k";
  };
}; in
stdenv.mkDerivation rec {
  name = "cxlactivitylogger";
  version = "2018-10-08";
  src = srcs.logger;
  nativeBuildInputs = [ scons ];
  buildInputs = [ amdtbasetools amdtoswrappers ];
  postUnpack = ''
    cp -n ${srcs.common}/* $sourceRoot
    cp -n ${srcs.tsingleton}/* $sourceRoot
  '';
  buildCommand = ''
    unpackPhase
    cd $sourceRoot
    $CXX AMDTActivityLogger.cpp AMDTActivityLoggerProfileControl.cpp AMDTActivityLoggerTimeStamp.cpp -lAMDTOSWrappers -lAMDTBaseTools -std=c++11 -fno-strict-aliasing -D_LINUX -DAMDT_BUILD_SUFFIX= -DAMDT_DEBUG_SUFFIX= -DAMDT_PUBLIC -DNDEBUG -shared -o libCXLActivityLogger.so
    mkdir -p $out/lib $out/include
    cp libCXLActivityLogger.so $out/lib
    cp CXLActivityLogger.h $out/include
  '';
}
