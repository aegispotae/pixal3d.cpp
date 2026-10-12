# About this fork

This is a personal fork of **[raven38/pixal3d.cpp](https://github.com/raven38/pixal3d.cpp)** by raven38
(MIT), which itself is a fork of **[pwilkin/trellis.cpp](https://github.com/pwilkin/trellis.cpp)**
by Piotr Wilkin (MIT). All the image→3D work — the GGML/Metal TRELLIS.2 and Pixal3D pipelines, the
server and the desktop app — is theirs; see [`NOTICE`](NOTICE) and [`PIXAL3D.md`](PIXAL3D.md).
The models are [TencentARC Pixal3D](https://github.com/TencentARC/Pixal3D) and
[microsoft/TRELLIS.2](https://github.com/microsoft/TRELLIS.2).

Branch `local-pixal3d` adds only small local conveniences, used on Apple Silicon (macOS, Metal):

- Programs renamed to **`pixal3d-cli` / `pixal3d-server`** and the desktop app to **Pixal3D Studio**
  (upstream: trellis-cli / trellis-server / Trellis Studio; config in `~/Library/Application Support/pixal3d-studio/`),
  so they are not confused with a separate TRELLIS.2 tool on the same machine. `README.md` is rewritten
  for this build; the original is `UPSTREAM_README.md`. It builds and runs on macOS arm64 from source
  (`cd app && npm ci && npm exec -- tauri build --bundles app`).
- `pixal3d.sh` — a wrapper for the canonical 4-view rig
  (`01_front 02_right 03_back 04_left`, `--mesh-scale 1.0`, default `--res 1536`).
  Note: in the canonical rig "right (azim 90)" is the camera on +X, i.e. it sees the **character's
  left side** (`src/transforms_json.cpp:241-244`).

Measured on an M5 Max (64 GB): 4-view Pixal3D, res 1024 — 146 s, ~4.5 GB peak memory;
res 1536 — 421 s, ~6 GB.
