{
  cudaPackages,
  python,
  stdenv,
  lib,
  ninja,
  buildPythonPackage,
  fetchFromGitHub,
  # TODO: maybe this should be torch and assume config.cudaSupport is set
  torchWithCuda,
  torchvision,
  torchaudio,
  setuptools,
  packaging,
  wheel,
}:
let
  torch = torchWithCuda;
in
buildPythonPackage {
  pname = "LTX-Video-Q8-Kernels";
  version = "unstable";
  src = fetchFromGitHub {
    owner = "Lightricks";
    repo = "LTX-Video-Q8-Kernels";
    rev = "f3066edea210082799ca5a2bbf9ef0321c5dd8fc";
    hash = "sha256-BySCwB5dfy59QxLbSJHP/oBYOhITzrnAShQfKhzcZFM=";
    fetchSubmodules = true;
  };
  build-system = [
    setuptools
    packaging
    wheel
  ];
  propagatedBuildInputs = [
    torch
    # TODO: if we rely on config.cudaSupport=true then can use torchvision and torchaudio directly
    (torchvision.override {
      inherit torch;
    })
    (torchaudio.override {
      inherit torch;
    })
  ];
  nativeBuildInputs = [
    ninja
  ];
  buildInputs = with cudaPackages; [
    cuda_nvcc
    cuda_cudart
    cuda_cccl
    libcusparse
    libcublas
    libcusolver
  ];
  env.CUDA_HOME = cudaPackages.cuda_nvcc;

  # Workaround
  # ninja hook can't set -j as setup.py launches ninja so use env var
  # impure dep on local cuda card arch
  # third_party/ deps not being found when isolated build temp dir is used
  postPatch =
    let
      # E.g. 3.11.2 -> "311"
      pythonVersionMajorMinor =
        with lib.versions;
        "${major python.pythonVersion}${minor python.pythonVersion}";

      # E.g. "linux-aarch64"
      platform =
        with stdenv.hostPlatform;
        (lib.optionalString (!isDarwin) "${parsed.kernel.name}-${parsed.cpu.name}")
        + (lib.optionalString isDarwin "macosx-${darwinMinVersion}-${darwinArch}");
    in
    ''
      export MAX_JOBS=$NIX_BUILD_CORES
      build="build/temp.${platform}-cpython-${pythonVersionMajorMinor}"
      mkdir -p $build/
      ln -s $(realpath third_party/) $build/third_party
      substituteInPlace setup.py \
        --replace-fail "major, minor = torch.cuda.get_device_capability(0)" "major, minor = 8, 9" \
        --replace-fail 'subprocess.run(["git", "submodule", "update", "--init", "third_party/cutlass"], check=True)' "pass"
    '';
  meta = {
    # TODO more details

    # broken if torch isn't a cuda torch
    broken = !(torch.cudaSupport or false);
  };
}
