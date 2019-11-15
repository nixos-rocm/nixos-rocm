{ stdenv, fetchFromGitHub, cmake, symlinkJoin, utillinux, which, git, openssl
, buildPythonPackage, python, numpy, pyyaml, cffi, numactl, opencv3, lmdb, pkg-config
, rocr, hip, openmp, rocrand, rocblas, rocfft, rocm-cmake, rccl, rocprim, hipcub
, miopen-hip, miopengemm, rocsparse, hipsparse, rocthrust, comgr
, hcc
, roctracer }:
buildPythonPackage rec {
  version = "1.0.0";
  pname = "pytorch";
  src = fetchFromGitHub {
    owner = "ROCmSoftwarePlatform";
    repo = "pytorch";
    rev = "c3a845bb0682f5ced87af2c8c38d1907edebfdd5";
    sha256 = "1194j8yyi2q0s3v7qi68366qx65pzzq3j8xhdfxqiiwscsicwy9l";
    fetchSubmodules = true;
  };

  nativeBuildInputs = [ cmake pkg-config utillinux which git hip ];
  buildInputs = [ 
    numpy.blas
    numactl
    lmdb
    opencv3
    openssl
    hcc
    hip
    openmp
    rocr
    rccl
    miopen-hip
    miopengemm
    rocrand
    rocblas
    rocfft
    rocsparse
    hipsparse
    rocthrust
    comgr
    rocprim
    hipcub
    roctracer
  ];
  propagatedBuildInputs = [ cffi numpy pyyaml ];

  preConfigure = ''
    export USE_ROCM=1
    export USE_OPENCV=1
    export USE_LMDB=1
    export NIX_CFLAGS_COMPILE="$NIX_CFLAGS_COMPILE -std=c++14 -D__HIP_PLATFORM_HCC__ -Wno-implicit-int-float-conversion"
    sed 's|^\([[:space:]]*src =\)os.path.join("torch", rel_site_packages, filename)|\1 filename|' -i setup.py
    for f in caffe2/CMakeLists.txt c10/hip/CMakeLists.txt test/cpp/jit/CMakeLists.txt; do
      substituteInPlace "$f" --replace @mcwamp@ ${hcc}/lib/libmcwamp.so
    done
    python3 tools/amd_build/build_amd.py
  '';

  cmakeFlags = [
    "-DUSE_CUDA=OFF"
    "-DATEN_NO_TEST=ON"
    "-DUSE_GLOO=OFF"
    "-DUSE_MKLDNN=OFF"
    "-DUSE_OPENMP=ON"
    "-DUSE_OPENCV=ON"
    "-DUSE_DISTRIBUTED=OFF"
    "-DBUILD_TEST=ON"
  ];

  doCheck = false;

  patches = [ 
    ./no-hex-float-lit.patch 
    ./protobuf-cmake-install.patch 
    ./hip-version-torch.patch
    ./torch-python-lib-dirs.patch
    ./setup-lib-dirs.patch
    ./link-mcwamp.patch
    ./add-jit-srcs.patch
    ./hip-cmake.patch
  ];

  postConfigure = ''
    cd ..
  '';

  # From the CUDA nixpkgs pytorch

  # Override the (weirdly) wrong version set by default. See
  # https://github.com/NixOS/nixpkgs/pull/52437#issuecomment-449718038
  # https://github.com/pytorch/pytorch/blob/v1.0.0/setup.py#L267
  PYTORCH_BUILD_VERSION = version;
  PYTORCH_BUILD_NUMBER = 0;
  
  preFixup = ''
    function join_by { local IFS="$1"; shift; echo "$*"; }
    function strip2 {
      IFS=':'
      read -ra RP <<< $(patchelf --print-rpath $1)
      IFS=' '
      RP_NEW=$(join_by : ''${RP[@]:2})
      patchelf --set-rpath \$ORIGIN:''${RP_NEW} "$1"
    }

    for f in $(find ''${out} -regex '.*/\(lib\)?caffe2.*\.so')
    do
      strip2 $f
    done
    ln -s $out/bin $out/${python.sitePackages}/torch
  '';

}
