# FlashAttention 2.8.4 for ROCm gfx1201 (Windows)

Prebuilt **FlashAttention 2.8.4** wheel with native ROCm/HIP (CK) kernels for AMD **gfx1201** (RX 9000 series, e.g. RX 9070 XT) on **Windows**.

Build: `2.8.4+rocm101torch215cxx11abitrue` — Python 3.12 (cp312), torch 2.15, ROCm 10.1, cxx11 ABI.

## Install

```bash
pip install --no-deps "https://raw.githubusercontent.com/thehybrid1337/flash-attn-rocm-gfx1201-win/main/flash_attn-2.8.4%2Brocm101torch215cxx11abitrue-cp312-cp312-win_amd64.whl"
```

Requires `torch` (2.15 nightly, ROCm 10.1) and `einops` already installed in the target environment.

## Verify

```bash
python -c "import torch; import flash_attn_2_cuda; print(flash_attn_2_cuda.__file__)"
```

A clean load with no Triton fallback warning means the HIP kernels are active.

## Build

`build/build-flash-attn.bat` — loads the VS2022 x64 native tools, resumes/compiles with ninja (`OPT_DIM=32,64,128,256`, `MAX_JOBS=16`), builds the wheel, installs it into `comfyui-rocm\python_env`, and runs the GPU smoke test. Source pipeline: [flash-attn-ck-rocm-gfx120x-build](https://github.com/thehybrid1337/flash-attn-ck-rocm-gfx120x-build) (recipes).

Requires: Python 3.12, VS2022 Enterprise with C++ toolset, ROCm-enabled PyTorch 2.15 / ROCm 10.1, and the source tree at `%USERPROFILE%\fa-ck-gfx1201`.

## Build details

- Source: [Dao-AILab/flash-attention](https://github.com/Dao-AILab/flash-attention) at commit `69e1bcbe77c359c84b3a4589e92a7c076e33a202`
- Inference-only patch: backward pass disabled (`-DFLASHATTENTION_DISABLE_BACKWARD`)
- `OPT_DIM=32,64,128,256`, `MAX_JOBS=16`

## License

BSD-3-Clause — see [LICENSE](LICENSE) (upstream flash-attention).
