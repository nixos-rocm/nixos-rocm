# This is adapted from the nixpkgs tensorflow wheel-based derivation.
# Usage example:
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
, mock
, backports_weakref
, enum34
, tensorflow-tensorboard
, tensorflow-estimator
, zlib
, python, bootstrapped-pip
, symlinkJoin
, keras-applications
, keras-preprocessing
, opt-einsum

# For tensorboard
, markdown
, werkzeug
, wheel

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
  tensorboard_2_0_0 = buildPythonPackage rec {
    pname = "tensorflow-tensorboard";
    version = "2.0.0";
    format = "wheel";
    # src = fetchPypi {
    #   inherit pname version;
    #   sha256 = "1w5dzdb3gpcfmd2s0b93d8gff40a1s41rvggg58z14inb3s9v4zy";
    # };
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/9b/a6/e8ffa4e2ddb216449d34cfcb825ebb38206bee5c4553d69e7bc8bc2c5d64/tensorboard-2.0.0-py3-none-any.whl";
      sha256 = "0hz9nn4bbr1k5iwdrsrcdvkg36qswqdzbgsrlbkp53ddrhb9cmfk";
    };
    propagatedBuildInputs = [
      numpy
      werkzeug
      protobuf
      markdown
      grpcio absl-py
      wheel
    ];
  };
  tensorflow-estimator_2_0_0 = buildPythonPackage rec {
    pname = "tensorflow-estimator";
    version = "2.0.0";
    format = "wheel";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/95/00/5e6cdf86190a70d7382d320b2b04e4ff0f8191a37d90a422a2f8ff0705bb/tensorflow_estimator-2.0.0-py2.py3-none-any.whl";
      sha256 = "1nkjlwlnpr1avwdl3kmj5h25gg9vsk729mf6kdbjfinm2a3zxzal";
    };
  };
in buildPythonPackage {
  pname = "tensorflow";
  version = "2.0.1";
  format = "wheel";

  src = fetchurl {
    url = "https://files.pythonhosted.org/packages/09/89/367e129509477506194eb21d0c873e9649c73dc233d045e18b2786529988/tensorflow_rocm-2.0.1-cp37-cp37m-manylinux1_x86_64.whl";
    sha256 = "0kf2fxhlwxr4m81dwxd19pwqwgk4drhnr5471x82dkk8n6976gcz";
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
    wrapt
    tensorflow-estimator_2_0_0
    tensorboard_2_0_0
    keras-applications
    keras-preprocessing
    opt-einsum
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
    rrPath="$out/${python.sitePackages}/tensorflow_core/:${rpath}"
    internalLibPath="$out/${python.sitePackages}/tensorflow/python/_pywrap_tensorflow_internal.so"
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
