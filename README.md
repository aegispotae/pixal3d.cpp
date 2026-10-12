# Pixal3D for macOS (Apple Silicon)

Local image → 3D generation on a Mac: **four views of a character or object → one textured GLB**,
running the [TencentARC Pixal3D](https://github.com/TencentARC/Pixal3D) model natively on Metal, with
no Python and no CUDA at runtime.

> **Credit.** This is a personal fork of **[raven38/pixal3d.cpp](https://github.com/raven38/pixal3d.cpp)**
> (MIT), itself a fork of **[pwilkin/trellis.cpp](https://github.com/pwilkin/trellis.cpp)** by Piotr
> Wilkin (MIT). The whole C++/GGML pipeline, the server and the desktop app are their work — see
> [`NOTICE`](NOTICE), [`PIXAL3D.md`](PIXAL3D.md) and the original documentation in
> [`UPSTREAM_README.md`](UPSTREAM_README.md). Models: TencentARC Pixal3D (MIT) and
> [microsoft/TRELLIS.2](https://github.com/microsoft/TRELLIS.2) (MIT); the DINOv3 encoder has its own license.

What this fork changes (branch `local-pixal3d`, see [`FORK.md`](FORK.md)):

| upstream name | in this fork |
|---|---|
| `trellis-cli` | **`pixal3d-cli`** |
| `trellis-server` | **`pixal3d-server`** |
| Trellis Studio (desktop app) | **Pixal3D Studio** |
| config / logs in `…/trellis-studio/` | `~/Library/Application Support/pixal3d-studio/` |
| — | `pixal3d.sh` wrapper for the 4-view workflow |

The same binaries can still run Microsoft **TRELLIS.2** (single image, or 2–8 images without camera
poses) — that is the model's name, not the program's. The upstream docs in `UPSTREAM_README.md` and
`docs/` keep the old `trellis-*` program names.

## 1. Build

Requirements: Apple Silicon Mac, Xcode command line tools, Homebrew `cmake` and `ninja`.

```bash
git clone -b local-pixal3d https://github.com/aegispotae/pixal3d.cpp && cd pixal3d.cpp
git submodule update --init --depth 1 thirdparty/ggml      # pinned pwilkin/ggml commit
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release          # Metal backend is automatic on macOS
cmake --build build -j
# -> build/pixal3d-cli, build/pixal3d-server
```

## 2. Download the weights (Pixal3D multiview, q8_0, ~7.6 GB)

File list and SHA-256 hashes: `models/pixal3d-q8_0-v1/pixal3d-models.json`. The files are on Hugging Face
in `raven38/pixal3d-q8_0-v1` (pinned revision below). This downloads them to `~/models/pixal3d-q8_0-v1`
and verifies every hash:

```bash
python3 - <<'EOF'
import json, subprocess, hashlib, pathlib
dst = pathlib.Path.home() / "models/pixal3d-q8_0-v1"; dst.mkdir(parents=True, exist_ok=True)
m = json.load(open("models/pixal3d-q8_0-v1/pixal3d-models.json"))
base = "https://huggingface.co/raven38/pixal3d-q8_0-v1/resolve/1f82a6b7e0b64de4fe7c96c66db7977fc61a1203"
for f in m["files"]:
    out = dst / f["name"]
    if not (out.exists() and out.stat().st_size == f["size_bytes"]):
        subprocess.run(["curl", "-L", "--fail", "-o", str(out), f"{base}/{f['name']}"], check=True)
    ok = hashlib.sha256(out.read_bytes()).hexdigest() == f["sha256"]
    print(f["name"], "OK" if ok else "SHA MISMATCH")
EOF
cp models/pixal3d-q8_0-v1/pixal3d-models.json ~/models/pixal3d-q8_0-v1/
```

## 3. Prepare the four views

Four pre-matted **RGBA** PNGs of the same subject (transparent background, same scale, centered,
square, e.g. 1024×1024), in one folder, named so they sort in this order:

| file | camera | must show |
|---|---|---|
| `01_front.png` | azimuth 0 | the front |
| `02_right.png` | azimuth 90 (camera on +X) | the subject's **left** side |
| `03_back.png` | azimuth 180 | the back |
| `04_left.png` | azimuth 270 (camera on −X) | the subject's **right** side |

"right/left" name the **camera position**, not the body side (`src/transforms_json.cpp:241-244`) — the
most common mistake. No `transforms.json` is needed (canonical 4-view rig); the mesh scale is `1.0`.
Keep the four views consistent: anything that differs between them (an extra pocket, a different
strap) becomes a lump in the mesh.

## 4. Generate — command line

```bash
./pixal3d.sh path/to/views out.glb 1536
```

`pixal3d.sh` expects the weights in `../model-cache/pixal3d/pixal3d-q8_0-v1` next to the repo; edit its
`--models` path for another location, or call the CLI directly:

```bash
./build/pixal3d-cli --views path/to/views --models ~/models/pixal3d-q8_0-v1 \
    --mesh-scale 1.0 --res 1536 --seed 42 --require-gpu out.glb
```

- `--res 1024` or `1536` (512 is not available for 4 views). Measured on an M5 Max (64 GB), 4 views:
  **1024 — 146 s, ~4.5 GB peak memory; 1536 — 421 s, ~6 GB.** 1536 gives clearly better faces and
  small hard-surface details.
- Output: textured GLB (PBR, 4096 atlas, WebP) plus a `.ply`.
- `--atlas 2048` for a smaller texture; `--seed N` for another variant.
- `--dump-post FILE` saves the raw mesh before post-processing; `build/post-replay FILE out.glb [--no-remesh
  --band N --faces N --atlas N]` then re-runs only the post-process in seconds.

**Known traits of the output**

- The post-process (narrow-band UDF dual contouring, as in the reference TRELLIS.2 pipeline) builds a
  closed offset surface around the generated mesh. Around a closed body this yields **two shells about
  2 mm apart** (outer and inner). Rendering is fine; decimating it directly fails because the shells
  collapse into each other. Remove the inner shell first, or experiment with `--band` / `post-replay --no-remesh`.
- Very small details (badges, lettering, buckles) may break up; add them separately afterwards.
- The origin is at the mesh center, not at the feet.

## 5. Generate — desktop app (Pixal3D Studio)

Upstream does not ship a notarized macOS app; build it locally (Rust via `rustup`, Node 20+):

```bash
cd app
npm ci
npm exec -- tauri build --bundles app
open "src-tauri/target/release/bundle/macos/Pixal3D Studio.app"
```

The app starts and supervises `pixal3d-server`. Configure it in Settings, or create
`~/Library/Application Support/pixal3d-studio/config.json`:

```json
{
  "serverBin": "/ABSOLUTE/PATH/pixal3d.cpp/build/pixal3d-server",
  "modelsDir": "/ABSOLUTE/PATH/models/pixal3d-q8_0-v1",
  "modelsDirSv": "",
  "backend": "metal",
  "host": "127.0.0.1",
  "port": 7864,
  "outputDir": "/ABSOLUTE/PATH/output"
}
```

In the app choose **Pixal3D multiview**, add the four views in the order of the table above, mesh scale
`1.0`, resolution 1024 or 1536. Pick a free port (the upstream default 8080 is often taken). Logs:
`~/Library/Application Support/pixal3d-studio/logs/`. The gallery is stored in the app (IndexedDB).

Check the server without the app:

```bash
./build/pixal3d-server --models ~/models/pixal3d-q8_0-v1 --host 127.0.0.1 --port 7864 &
curl http://127.0.0.1:7864/capabilities      # expect "mv":{"configured":true,...}
```

## License

MIT, as upstream — see [`LICENSE`](LICENSE) and [`NOTICE`](NOTICE). Model weights carry their own licenses.
