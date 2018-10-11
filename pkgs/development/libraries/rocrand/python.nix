{ buildPythonPackage, numpy, rocr, hip, rocrand }:
{
  rocrand-python = buildPythonPackage {
    pname = "rocrand-python";
    version = rocrand.version;
    buildInputs = [ numpy ];
    src = rocrand.src + /python/rocrand;
    doCheck = false;
    patchPhase = ''
      sed -e 's|os.getenv("ROCRAND_PATH")|"${rocrand}/rocrand"|' \
          -i rocrand/rocrand.py
      sed -e 's|os.getenv("ROCM_PATH")|"${rocr}"|' \
          -e 's|os.getenv("HIP_PATH")|"${hip}"|' \
          -i rocrand/hip.py
    '';
  };
  hiprand-python = buildPythonPackage {
    pname = "hiprand-python";
    version = rocrand.version;
    buildInputs = [ numpy ];
    src = rocrand.src + /python/hiprand;
    doCheck = false;
    patchPhase = ''
      sed -e 's|os.getenv("HIPRAND_PATH")|"${rocrand}/hiprand"|' \
          -e 's|os.getenv("ROCRAND_PATH")|"${rocrand}/rocrand"|' \
          -i hiprand/hiprand.py
      sed -e 's|os.getenv("ROCM_PATH")|"${rocr}"|' \
          -e 's|os.getenv("HIP_PATH")|"${hip}"|' \
          -i hiprand/hip.py
    '';
  };
}
