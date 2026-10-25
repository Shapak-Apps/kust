#!/usr/bin/env python3
"""Serves tools/pieces/textured.html and saves the pieces it paints.

    python3 tools/pieces/serve.py        # from the project root
    open http://127.0.0.1:8767/textured.html in a browser

The page draws each textured set on a canvas and posts every piece back
here; they land in assets/pieces/<set>/<piece>.webp.
"""

import http.server
import re
from pathlib import Path

HERE = Path(__file__).resolve().parent
ASSETS = HERE.parent.parent / "assets" / "pieces"
NAME = re.compile(r"^/save/([a-z]+)/([wb][KQRBNP])\.webp$")


class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(HERE), **kwargs)

    def do_POST(self):
        match = NAME.match(self.path)
        if not match:
            self.send_error(404)
            return
        folder = ASSETS / match.group(1)
        folder.mkdir(parents=True, exist_ok=True)
        size = int(self.headers["Content-Length"])
        (folder / f"{match.group(2)}.webp").write_bytes(self.rfile.read(size))
        self.send_response(204)
        self.end_headers()

    def log_message(self, *args):
        pass


if __name__ == "__main__":
    http.server.ThreadingHTTPServer(("127.0.0.1", 8767), Handler).serve_forever()
