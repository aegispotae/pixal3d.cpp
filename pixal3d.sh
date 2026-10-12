#!/bin/bash
# Pixal3D (pixal3d.cpp, Metal) — 4 pohledy -> texturovany GLB.
# Programy se jmenuji trellis-cli/trellis-server (zdedeno z trellis.cpp); tenhle obal je "Pixal3D".
#
#   ./pixal3d.sh <slozka_se_4_RGBA_pohledy> <vystup.glb> [res 1024|1536] [dalsi argumenty trellis-cli]
#
# Slozka: 01_front.png 02_right.png 03_back.png 04_left.png (RGBA, stejne meritko a vycentrovani).
# POZOR: "02_right" = kamera vpravo od predni = vidi LEVY bok postavy; "04_left" = PRAVY bok
# (src/transforms_json.cpp:241-244). RAM: 1024 ~4,5 GB, 1536 ~6 GB (Marcus 2026-10-12).
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VIEWS="$1"; OUT="$2"; RES="${3:-1536}"; shift $(( $# >= 3 ? 3 : 2 ))
exec "$HERE/build/trellis-cli" --views "$VIEWS" \
    --models "$HERE/../model-cache/pixal3d/pixal3d-q8_0-v1" \
    --mesh-scale 1.0 --res "$RES" --seed 42 --require-gpu "$@" "$OUT"
