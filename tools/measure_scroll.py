# measure_scroll.py
# Herramienta de desarrollo: mide cuántos píxeles se desplaza el suelo entre fotogramas
# consecutivos de una grabación (carpeta con f*.png) y resume si el avance es pareja.
# Uso: python3 tools/measure_scroll.py <carpeta>
import sys, glob
import numpy as np
from PIL import Image

files = sorted(glob.glob(sys.argv[1] + "/f*.png"))[-90:]
# Solo una franja del suelo, lejos del HUD, del jugador y de los botones.
def strip(path):
    im = np.asarray(Image.open(path).convert("L"), dtype=np.float32)
    s = im[560:700, 300:1000]
    return s - s.mean()

def shift(a, b):
    # Correlación de fase en horizontal: desplazamiento (subpíxel) entre dos franjas.
    A = np.fft.rfft(a.mean(axis=0)); B = np.fft.rfft(b.mean(axis=0))
    r = np.fft.irfft(A * np.conj(B) / (np.abs(A * np.conj(B)) + 1e-6))
    k = int(np.argmax(r)); n = len(r)
    y0, y1, y2 = r[(k - 1) % n], r[k], r[(k + 1) % n]
    d = (y0 - y2) / (2 * (y0 - 2 * y1 + y2) + 1e-9)
    k = k + d
    return k - n if k > n / 2 else k

s = [strip(f) for f in files]
d = [abs(shift(s[i], s[i + 1])) for i in range(len(s) - 1)]
d = np.array(d)
print("fotogramas: %d ; desplazamiento medio %.2f px ; mín %.2f ; máx %.2f ; desviación %.2f px" % (len(d), d.mean(), d.min(), d.max(), d.std()))
print("primeros 12:", " ".join("%.1f" % x for x in d[:12]))
print("fotogramas casi parados (< 1 px): %d de %d" % ((d < 1.0).sum(), len(d)))
