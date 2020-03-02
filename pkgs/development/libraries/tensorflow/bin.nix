# This is adapted from the nixpkgs tensorflow wheel-based derivation.
# Usage note: This derivation includes a `setupHook` that sets
# `LD_PRELOAD` to avoid a crash due to conflicting libstdc++
# definitions. To benefit from this hook, add `tensorflow-rocm` to a
# `nix-shell` as its own entity rather than among a list of packages
# in a `withPackages` call. For example:
# `nix-shell -p 'python37.withPackages (ps: [ps.jupyter])' -p tensorflow-rocm`
#
# You can then start `jupyter-notebook` as normal.
{ stdenv
, lib
, fetchurl
, buildPythonPackage
, fetchPypi
, astor
, numpy
, six
, termcolor
, wrapt
, protobuf
, absl-py
, astunparse
, grpcio
, google-pasta
, markdown
, opt-einsum
, backports_weakref
, enum34
, werkzeug
, wheel
, tensorflow-tensorboard
, tensorflow-estimator
, zlib
, python, bootstrapped-pip
, symlinkJoin
, keras-applications
, keras-preprocessing
, writeText
, addOpenGLRunpath

# ROCm components
, hcc, hcc-unwrapped
, hip, miopen-hip, miopengemm, rocrand, rocfft, rocblas
, rocr, rccl, cxlactivitylogger
}:
assert python.pythonVersion == "3.7";

# We keep this binary build for two reasons:
# - the source build doesn't work on Darwin.
# - the source build is currently brittle and not easy to maintain

let
  rocmtoolkit_joined = symlinkJoin {
    name = "unsplit_rocmtoolkit";
    paths = [ hcc hcc-unwrapped
              hip miopen-hip miopengemm
              rocrand rocfft rocblas rocr rccl cxlactivitylogger ];
  };

  gast_0_2_2 = buildPythonPackage rec {
    pname = "gast";
    version = "0.2.2";
    src = fetchPypi {
      inherit pname version;
      sha256 = "1w5dzdb3gpcfmd2s0b93d8gff40a1s41rv31458z14inb3s9v4zy";
    };
    propagatedBuildInputs = [ astunparse ];
  };
  # tensorboard_1_15_0 = buildPythonPackage rec {
  #   pname = "tensorflow-tensorboard";
  #   version = "1.15.0";
  #   format = "wheel";
  #   src = fetchurl {
  #     url = "https://files.pythonhosted.org/packages/1e/e9/d3d747a97f7188f48aa5eda486907f3b345cd409f0a0850468ba867db246/tensorboard-1.15.0-py3-none-any.whl";
  #     sha256 = "1g62i3nrgp8q9wfsyqqjkkfnsz7x2k018c26kdh527h1yrjjrbac";
  #   };
  #   propagatedBuildInputs = [
  #     numpy
  #     werkzeug
  #     protobuf
  #     markdown
  #     grpcio absl-py
  #     wheel
  #   ];
  # };
  # tensorflow-estimator_1_15_2 = buildPythonPackage rec {
  #   pname = "tensorflow-estimator";
  #   version = "1.15.2";
  #   format = "wheel";
  #   src = fetchurl {
  #     url = "https://files.pythonhosted.org/packages/72/33/f678e8c2a14a139aec1c376f2e8cbb11abececf656c40addc94a3d1d020d/tensorflow_estimator-1.15.2-py2.py3-none-any.whl";
  #     sha256 = "0px0gp068akw22ibmzfijfk6qh93865k6k650vazm1xfs5hgpb4s";
  #   };
  # };
in buildPythonPackage {
  pname = "tensorflow";
  version = "1.15.2";
  format = "wheel";

  src = fetchurl {
    url = "https://files.pythonhosted.org/packages/e8/3f/f514bb6ef96e41ecf40cf28903ec2fbe4c236ead430d5783f86262070a2f/tensorflow_rocm-1.15.2-cp37-cp37m-manylinux1_x86_64.whl";
    sha256 = "07j0ciaajgwn154cdr6z7bcjg25jx35aaadxaxrl7l3dbwyfr1ln";
  };

  propagatedBuildInputs = [
    protobuf
    numpy
    termcolor
    grpcio
    six
    astor
    absl-py
    gast_0_2_2
    google-pasta
    opt-einsum
    wrapt
    tensorflow-estimator
    tensorflow-tensorboard
    keras-applications
    keras-preprocessing
  ];

  nativeBuildInputs = [ addOpenGLRunpath rocmtoolkit_joined ];

  preInstall = ''
    pushd dist
    echo 'manylinux1_compatible = True' > _manylinux.py
    popd
  '';

  # Upstream has a pip hack that results in bin/tensorboard being in both tensorflow
  # and the propageted input tensorflow-tensorboard which causes environment collisions.
  # another possibility would be to have tensorboard only in the buildInputs
  # https://github.com/tensorflow/tensorflow/blob/v1.7.1/tensorflow/tools/pip_package/setup.py#L79
  postInstall = ''
    rm $out/bin/tensorboard
  '';

  # Note that we need to run *after* the fixup phase because the
  # libraries are loaded at runtime. If we run in preFixup then
  # patchelf --shrink-rpath will remove the cuda libraries.
  postFixup = let
    rpath = stdenv.lib.makeLibraryPath
              [ stdenv.cc.cc.lib zlib rocmtoolkit_joined ];
  in
  lib.optionalString (stdenv.isLinux) ''
    rrPath="$out/${python.sitePackages}/tensorflow_core/:$out/${python.sitePackages}/tensorflow_core/contrib/tensor_forest/:${rpath}"
    internalLibPath="$out/${python.sitePackages}/tensorflow_core/python/_pywrap_tensorflow_internal.so"
    find $out -type f \( -name '*.so' -or -name '*.so.*' \) | while read lib; do
      patchelf --set-rpath "$rrPath" "$lib"
      addOpenGLRunpath "$lib"
    done
  '';

  meta = with stdenv.lib; {
    description = "Computation using data flow graphs for scalable machine learning";
    homepage = http://tensorflow.org;
    license = licenses.asl20;
    maintainers = with maintainers; [ acowley ];
    platforms = with platforms; linux;
  };
}
