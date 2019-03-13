{ fetchFromGitHub, buildPythonPackage, pyyaml }:
buildPythonPackage rec {
  pname = "Tensile";
  version = "4.9.0";
  src = fetchFromGitHub {
    owner = "ROCmSoftwarePlatform";
    repo = "Tensile";
    rev = "v${version}";
    sha256 = "1znyljj89mpbzbhs0acq9xwb9lhjw33nk4z45vi3cicha72h20kr";
  };
  buildInputs = [ pyyaml ];
}
