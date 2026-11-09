#!/bin/bash
# export_web.sh
# Herramienta de desarrollo: exporta el juego a web en build/web/ y, opcionalmente,
# lo sirve en local para probarlo en el navegador.
#
# Uso (desde la raíz del proyecto):
#   tools/export_web.sh          # solo exporta
#   tools/export_web.sh serve    # exporta y abre http://localhost:8765
#
# Requiere las plantillas de exportación de Godot 4.6.2 (Editor > Administrar plantillas
# de exportación) y el preset "Web" de export_presets.cfg (variante sin hilos, para que
# funcione en cualquier alojamiento sin cabeceras especiales).

set -e
cd "$(dirname "$0")/.."
GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"

mkdir -p build/web
"$GODOT" --headless --path . --export-release "Web" build/web/index.html
du -sh build/web

if [ "$1" = "serve" ]; then
	python3 tools/serve_web.py ${HTTPS:+https}
fi
