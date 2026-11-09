# serve_web.py
# Herramienta de desarrollo: sirve build/web/ en http://localhost:8765 SIN caché, para que
# el navegador cargue siempre la última exportación (con la caché normal puede enseñar una
# versión antigua del juego).
# Uso: python3 tools/serve_web.py

import http.server
import os


class NoCacheHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Cache-Control", "no-store, max-age=0")
        super().end_headers()


os.chdir(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "build", "web"))
print("Sirviendo en http://localhost:8765  (Ctrl+C para parar)")
http.server.ThreadingHTTPServer(("0.0.0.0", 8765), NoCacheHandler).serve_forever()
