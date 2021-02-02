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
, google-auth-oauthlib
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
, rocm-runtime, rccl, cxlactivitylogger
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
              rocrand rocfft rocblas rocm-runtime rccl cxlactivitylogger ];
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
  tensorboard_2_1_0 = buildPythonPackage rec {
    pname = "tensorflow-tensorboard";
    version = "2.1.0";
    format = "wheel";
    # src = fetchPypi {
    #   inherit pname version;
    #   sha256 = "1w5dzdb3gpcfmd2s0b93d8gff40a1s41rvggg58z14inb3s9v4zy";
    # };
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/40/23/53ffe290341cd0855d595b0a2e7485932f473798af173bbe3a584b99bb06/tensorboard-2.1.0-py3-none-any.whl";
      sha256 = "1wpjdzhjpcdkyaahzd4bl71k4l30z5c55280ndiwj32hw70lxrp6";
    };
    propagatedBuildInputs = [
      numpy
      werkzeug
      protobuf
      markdown
      google-auth-oauthlib
      grpcio absl-py
      wheel
    ];
  };
  tensorflow-estimator_2_1_0 = buildPythonPackage rec {
    pname = "tensorflow-estimator";
    version = "2.1.0";
    format = "wheel";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/18/90/b77c328a1304437ab1310b463e533fa7689f4bfc41549593056d812fab8e/tensorflow_estimator-2.1.0-py2.py3-none-any.whl";
      sha256 = "0wk9viil54ms1s2ir7zxygqa425i69hx8zngwhdqvw9nlr4gdig5";
    };
  };
in buildPythonPackage {
  pname = "tensorflow";
  version = "2.1.1";
  format = "wheel";

  src = fetchurl {
    url = "https://files.pythonhosted.org/packages/65/0f/8182aa8735817340b9e7442fd6826b89bbee55ab79739f39d9d244d1c063/tensorflow_rocm-2.1.1-cp37-cp37m-manylinux1_x86_64.whl";
    sha256 = "18yn40w2p7xck8n8a6wjwqn2rx71c40z01fvrii6x6f7cgyd69wd";
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
    tensorflow-estimator_2_1_0
    tensorboard_2_1_0
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
    rpath = lib.makeLibraryPath
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

  meta = with lib; {
    description = "Computation using data flow graphs for scalable machine learning";
    homepage = http://tensorflow.org;
    license = licenses.asl20;
    maintainers = with maintainers; [ acowley ];
    platforms = with platforms; linux;
  };
}
