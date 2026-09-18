# models

A self-contained collection of [GGUF](https://github.com/ggml-org/llama.cpp) language
models for use with [llama.cpp](https://github.com/ggml-org/llama.cpp). Each model lives
in its own subfolder and is downloaded on demand. `models-preset.ini` holds the
llama-server configuration that references each model's `model.gguf`.

## Running llama.cpp in router mode

In llama.cpp, router mode allows you to launch a single llama-server instance that dynamically hosts, loads, and unloads multiple LLMs on demand (similar to how Ollama manages models). To trigger router mode, you must omit the standard single-model flags (--model or -m) and instead pass the --models-dir flag to point to your local GGUF directory.

To serve these models, point llama.cpp at this directory and its preset file:

- `--models-dir` — the directory this project lives in (the folder containing the model
  subfolders and this `README.md`).
- `--models-preset` — the `models-preset.ini` file within this project.

```bash
llama-server \
  --models-dir ${HOME}/models \
  --models-preset ${HOME}/models/models-preset.ini
```

## Folder structure

```
models/
├── Makefile              # downloads any missing models
├── models-preset.ini     # llama-server preset; points at each */model.gguf
├── .gitignore            # ignores */*.gguf (models are not committed)
├── gpt-oss-20b/
│   ├── model.url         # source of truth for the download (hf:// URL)
│   └── model.gguf        # downloaded model (git-ignored)
├── llava-7b/
│   ├── model.url
│   └── model.gguf
├── qwen2.5-coder-14b/
│   ├── model.url
│   └── model.gguf
└── qwen3.8-27b/
    ├── model.url
    └── model.gguf
```

Every model subfolder follows the same two-file convention:

- `model.url` — a single line containing the download URL for the model.
- `model.gguf` — the downloaded model weights. This is the file that
  `models-preset.ini` loads, and it is excluded from version control
  (see `.gitignore`).

## The `model.url` file

`model.url` is the **single source of truth** for how a model is obtained. The Makefile
reads it, derives the output filename from it, and builds the download command — there
is no other place the URL is stored. Each `model.gguf` is expected to be the exact file
named by that URL.

**The URL must be a Hugging Face URL.** It must use the `hf://` scheme and point at a
file hosted on **huggingface.co**, in the form:

```
hf://<namespace>/<repo>/<filename>.gguf
```

for example:

```
hf://unsloth/gpt-oss-20b-GGUF/gpt-oss-20b-Q4_K_M.gguf
```

The Makefile passes this URL straight to the `hf` CLI, which only understands
`hf://` references to files on huggingface.co. A non-Hugging-Face URL (a plain
`https://` link to an arbitrary host, a local path, etc.) will not work — keep the URL
in the `hf://<namespace>/<repo>/<filename>` form so the `hf` tool can resolve and
download it.

## Using the Makefile

The Makefile requires the Hugging Face Hub CLI to be installed and on your `PATH`
(`hf`, from `huggingface_hub`).

| Command | Effect |
| --- | --- |
| `make` or `make all` | Download every model whose `model.gguf` is missing. |
| `make gpt-oss-20b/model.gguf` | Download a single model by target. |
| `make -j4` | Download missing models in parallel (4 at a time). |
| `make clean` | Remove all `model.gguf` files (they can be re-downloaded). |

Behavior notes:

- **Idempotent.** Each `*/model.gguf` is only fetched when absent. Re-running `make`
  once a model is present does nothing, so it is safe to run repeatedly.
- **Automatic rename.** The `hf` CLI saves the file under its original name (the last
  segment of the URL). The Makefile then renames it to `model.gguf` so it matches the
  paths referenced by `models-preset.ini`.
- **Adding a model.** Create a new subfolder, drop in a `model.url` containing its
  `hf://` Hugging Face URL, and run `make`. The model is downloaded into that folder
  and stored as `model.gguf`.

## Container deployment

This directory is intended to be a **bind-mounted volume** for a llama.cpp server
running from a container. Mount the host directory at `/models` inside the container
so the models (and `models-preset.ini`) are visible to the server:

```bash
docker run -v ${HOME}/models:/models ...
```

The mount point `/models` matches the paths referenced by `models-preset.ini`
(e.g. `/models/gpt-oss-20b/model.gguf`), so the server resolves each model correctly
once the volume is attached.
