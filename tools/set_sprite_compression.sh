#!/bin/bash
# set_sprite_compression.sh
# Herramienta de desarrollo: pone la importación con pérdida (WebP lossy) a los fotogramas de
# personajes, enemigos y jefes. Reduce el peso de la exportación web (de ~68 MB a ~27 MB) sin
# cambiar el aspecto apreciable del arte. Los efectos (fx) se dejan sin pérdida: pesan poco y
# sus brillos son delicados.
#
# Hay que ejecutarlo cada vez que se regeneran fotogramas nuevos (los archivos nuevos nacen
# sin pérdida), y después reimportar:
#   tools/set_sprite_compression.sh && godot --headless --import
#
# Uso (desde la raíz del proyecto): tools/set_sprite_compression.sh [lossy|lossless]

cd "$(dirname "$0")/.."
MODE=1
[ "$1" = "lossless" ] && MODE=0
count=0
for dir in assets/sprites/*/; do
	[ "$(basename "$dir")" = "fx" ] && continue
	while IFS= read -r f; do
		sed -i '' "s/^compress\/mode=.*/compress\/mode=$MODE/" "$f"
		count=$((count + 1))
	done < <(find "$dir" -name "*.png.import")
done
echo "Modo de compresión $MODE aplicado a $count archivos."
