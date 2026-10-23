#!/usr/bin/env python3
"""Pack Stockfish NNUE networks into assets/engine for the app to bundle.

The pieces are NOT committed (assets/engine/*.gz is git-ignored). Every
developer and every release build runs this once before `flutter run/build`.

Each network is split into 32MB pieces and every piece is gzipped. The app
decompresses the pieces in order on first launch (no network needed on the
user's phone) and verifies the result against the hash in the file name.

Usage:
  tools/pack_nnue.py            download both networks, then pack them
  tools/pack_nnue.py a.nnue b.nnue   pack local copies instead
"""
import gzip
import hashlib
import sys
import urllib.request
from pathlib import Path

CHUNK = 32 * 1024 * 1024
OUT = Path(__file__).resolve().parent.parent / "assets" / "engine"
CACHE = Path(__file__).resolve().parent.parent / "assets" / "nnue"
NETWORKS = ["nn-c288c895ea92.nnue", "nn-37f18f62d772.nnue"]  # keep in sync with chess_engine.dart
BASE_URL = "https://data.stockfishchess.org/nn/"


def fetch(name):
    """Return a local path for network `name`, downloading it if needed."""
    CACHE.mkdir(parents=True, exist_ok=True)
    path = CACHE / name
    if not path.exists():
        print("downloading", name)
        urllib.request.urlretrieve(BASE_URL + name, path)
    return path


def main(paths):
    if not paths:
        paths = [fetch(name) for name in NETWORKS]
    OUT.mkdir(parents=True, exist_ok=True)
    for raw in map(Path, paths):
        data = raw.read_bytes()
        digest = hashlib.sha256(data).hexdigest()[:12]
        if raw.name != f"nn-{digest}.nnue":
            sys.exit(f"{raw.name}: contents hash to nn-{digest}.nnue, refusing")
        for old in OUT.glob(f"{raw.name}.*.gz"):
            old.unlink()
        for i in range(0, max(1, len(data)), CHUNK):
            part = OUT / f"{raw.name}.{i // CHUNK}.gz"
            # mtime=0 keeps the output reproducible, so git sees no churn.
            part.write_bytes(gzip.compress(data[i : i + CHUNK], 9, mtime=0))
            print(part.name, part.stat().st_size)


if __name__ == "__main__":
    main(sys.argv[1:])
