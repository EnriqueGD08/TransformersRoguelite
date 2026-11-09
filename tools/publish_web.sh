#!/bin/bash
# publish_web.sh
# Herramienta de desarrollo: exporta el juego a web y lo publica en la rama "gh-pages" del
# repositorio, que GitHub Pages sirve como página web.
#
# Por qué una rama aparte y con commit nuevo cada vez: la exportación pesa ~66 MB (motor +
# datos). Si se guardara en "main", cada publicación añadiría esos MB al historial para
# siempre. En "gh-pages" se sobrescribe la rama entera (push forzado) y el historial no crece.
# El código del juego (rama main) no se toca.
#
# Antes de la primera vez, en GitHub: Settings > Pages > Source: "Deploy from a branch"
# > Branch: gh-pages / (root). La web quedará en https://<usuario>.github.io/<repositorio>/
#
# Uso (desde la raíz del proyecto):  tools/publish_web.sh
# Pide confirmación antes de subir nada.

set -e
cd "$(dirname "$0")/.."

REMOTE="$(git remote get-url origin)"
echo "Se exportará el juego y se publicará en la rama gh-pages de:"
echo "  $REMOTE"
echo "ATENCIÓN: se sobrescribe la rama gh-pages entera (push forzado). main no se toca."
read -r -p "¿Continuar? (escribe 'si'): " answer
[ "$answer" = "si" ] || { echo "Cancelado."; exit 1; }

tools/export_web.sh

# Carpeta temporal con solo la exportación (más .nojekyll para que GitHub Pages no procese nada).
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
cp -R build/web/. "$tmp"/
touch "$tmp/.nojekyll"
cd "$tmp"
git init -q -b gh-pages
git add -A
git commit -q -m "Despliegue web $(date +%Y-%m-%d)"
git push --force "$REMOTE" gh-pages
echo "Publicado. Puede tardar un par de minutos en verse en GitHub Pages."
