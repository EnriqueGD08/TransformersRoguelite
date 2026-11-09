# serve_web.py
# Herramienta de desarrollo: sirve build/web/ SIN caché, para que el navegador cargue siempre
# la última exportación (con la caché normal puede enseñar una versión antigua del juego).
#
# Uso:
#   python3 tools/serve_web.py          # http://localhost:8765 (solo este ordenador)
#   python3 tools/serve_web.py https    # https://<IP-del-Mac>:8765 (para probar en el móvil)
#
# Por qué HTTPS: Godot en web exige "contexto seguro" (HTTPS o localhost). Desde el móvil
# la dirección es la IP del Mac, así que hace falta HTTPS. Se crea un certificado autofirmado
# en build/cert/ (el navegador avisará de que no es de confianza: hay que aceptarlo una vez).

import http.server
import os
import socket
import ssl
import subprocess
import sys

PORT = 8765
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")


class NoCacheHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Cache-Control", "no-store, max-age=0")
        super().end_headers()


def local_ip() -> str:
    # Truco habitual: "conectar" un socket UDP no envía nada, pero revela la IP de salida.
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(("10.255.255.255", 1))
        return s.getsockname()[0]
    except OSError:
        return "127.0.0.1"
    finally:
        s.close()


def make_cert(ip: str) -> tuple:
    folder = os.path.abspath(os.path.join(ROOT, "build", "cert"))
    os.makedirs(folder, exist_ok=True)
    cert, key = os.path.join(folder, "cert.pem"), os.path.join(folder, "key.pem")
    stamp = os.path.join(folder, "ip.txt")
    if not (os.path.exists(cert) and os.path.exists(stamp) and open(stamp).read() == ip):
        subprocess.run(["openssl", "req", "-x509", "-newkey", "rsa:2048", "-nodes", "-days", "30",
            "-keyout", key, "-out", cert, "-subj", "/CN=" + ip,
            "-addext", "subjectAltName=IP:" + ip + ",DNS:localhost"], check=True, capture_output=True)
        open(stamp, "w").write(ip)
    return cert, key


os.chdir(os.path.join(ROOT, "build", "web"))
server = http.server.ThreadingHTTPServer(("0.0.0.0", PORT), NoCacheHandler)
if "https" in sys.argv:
    ip = local_ip()
    cert, key = make_cert(ip)
    context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    context.load_cert_chain(cert, key)
    server.socket = context.wrap_socket(server.socket, server_side=True)
    print("Sirviendo en https://%s:%d  (Ctrl+C para parar)" % (ip, PORT))
else:
    print("Sirviendo en http://localhost:%d  (Ctrl+C para parar)" % PORT)
server.serve_forever()
