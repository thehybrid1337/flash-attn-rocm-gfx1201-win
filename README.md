# ROCm gfx1201 wheels for Windows

Prebuilt wheels with native ROCm/HIP kernels for AMD **gfx1201** (RX 9000 series, e.g. RX 9070 XT) on **Windows**, Python 3.12 (cp312).

## FlashAttention 2.8.4

Build: `2.8.4+rocm101torch215cxx11abitrue` — torch 2.15, ROCm 10.1, cxx11 ABI.

```bash
pip install --no-deps "https://raw.githubusercontent.com/thehybrid1337/flash-attn-rocm-gfx1201-win/main/flash_attn-2.8.4%2Brocm101torch215cxx11abitrue-cp312-cp312-win_amd64.whl"
```

Requires `torch` (2.15 nightly, ROCm 10.1) and `einops` already installed.

Verify:

```bash
python -c "import flash_attn_2_cuda; print(flash_attn_2_cuda.__file__)"
```

A clean load with no Triton fallback warning means the HIP kernels are active.

## SageAttention 2.2.0

Native compiled kernels (`_qattn_gfx12_native`, `_fused`) for gfx1201, torch 2.15 / ROCm 10.1.

```bash
pip install --no-deps "https://raw.githubusercontent.com/thehybrid1337/flash-attn-rocm-gfx1201-win/main/sageattention-2.2.0-cp312-cp312-win_amd64.whl"
```

Verify:

```bash
python -c "import sageattention; print(sageattention.__file__)"
```

## Build details (FlashAttention)

- Source: [Dao-AILab/flash-attention](https://github.com/Dao-AILab/flash-attention) at commit `69e1bcbe77c359c84b3a4589e92a7c076e33a202`
- Build pipeline: [flash-attn-ck-rocm-gfx120x-build](https://github.com/thehybrid1337/flash-attn-ck-rocm-gfx120x-build) (recipes)
- Inference-only patch: backward pass disabled (`-DFLASHATTENTION_DISABLE_BACKWARD`)
- `OPT_DIM=32,64,128,256`, `MAX_JOBS=16`

## Build scripts

How both wheels were built, so anyone can reproduce them:

- `build/build-flash-attn.bat` — FlashAttention 2.8.4 (CK backend, gfx1201): loads the VS2022 x64 native tools, resumes/compiles with ninja (`OPT_DIM=32,64,128,256`, `MAX_JOBS=16`), builds the wheel, installs it into `comfyui-rocm\python_env`, and runs the GPU smoke test. Source pipeline: [flash-attn-ck-rocm-gfx120x-build](https://github.com/thehybrid1337/flash-attn-ck-rocm-gfx120x-build) (recipes).
- `build/build-sageattention.bat` — SageAttention 2.2.0 (gfx12 native kernels): loads the VS2022 x64 native tools, then `python setup.py bdist_wheel` in the SageAttention source tree.

Requires: Python 3.12, VS2022 Enterprise with C++ toolset, ROCm-enabled PyTorch (2.15 nightly, ROCm 10.1) in the target env, and the matching source trees (`%USERPROFILE%\fa-ck-gfx1201` for FA, `C:\sagebuild\SageAttention` for Sage).

## License

BSD-3-Clause — see [LICENSE](LICENSE) (upstream flash-attention).
