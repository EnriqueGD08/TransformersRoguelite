# Transformers Roguelite

Videojuego **roguelite por oleadas** (al estilo Brotato) basado en los Transformers, hecho con **Godot 4.6** y GDScript. Elige un Autobot o Decepticon, sobrevive a 20 oleadas, transfórmate, mejora tu personaje y derrota a los jefes.

## Características

- **6 personajes jugables** (Optimus Prime, Bumblebee, Megatron, Starscream, Arcee y Shockwave), cada uno con su arma, su transformación y **3 aspectos** (Clásico G1, Transformers Prime y Película).
- **20 oleadas** con enemigos variados y **4 jefes**.
- **Árbol de habilidades** por personaje y **tienda** entre oleadas (el energon es la moneda).
- **Controles táctiles** (dos joysticks: mover y apuntar) y de teclado/ratón; se puede jugar en móvil desde el navegador.
- **Guardado** de la partida al empezar cada oleada, menú de pausa y pantallas de victoria y derrota.
- Todo el arte (estilo cel vectorial) y el audio se **generan por código** (`tools/`), sin recursos externos.

## Controles

| Acción | Teclado y ratón | Móvil |
|---|---|---|
| Mover | WASD o flechas | Joystick izquierdo |
| Apuntar | Ratón | Joystick derecho |
| Atacar | Clic izquierdo o J | Con el joystick derecho |
| Transformarse | Espacio | Botón en pantalla |
| Cambiar de arma (si el personaje tiene dos) | Q | Botón en pantalla |
| Pausa | Esc o P | Botón de pausa |

## Cómo ejecutarlo

1. Instala [Godot 4.6](https://godotengine.org/download).
2. Abre `project.godot` y pulsa Ejecutar (F5).

### Versión web

```bash
tools/export_web.sh              # exporta a build/web/
python3 tools/serve_web.py       # sirve en http://localhost:8765
python3 tools/serve_web.py https # para probarlo desde el móvil (misma wifi)
tools/publish_web.sh             # publica en GitHub Pages (rama gh-pages)
```

Necesita las plantillas de exportación de Godot 4.6 y el preset "Web" (sin hilos, para que funcione en cualquier alojamiento).

## Arquitectura

Pensada para respetar los principios **SOLID**:

- Un archivo, una responsabilidad.
- Los datos (personajes, armas, oleadas, tienda, habilidades) viven en recursos `.tres`, no en el código.
- Los sistemas se comunican por un bus de eventos (`EventBus`), sin conocerse entre sí.

```
scenes/      Escenas (jugadores, enemigos, interfaz, efectos)
scripts/     Código por responsabilidad (characters, enemies, weapons, systems, ui)
resources/   Datos en .tres
autoloads/   Servicios globales (EventBus, GameState, Settings...)
tools/       Generadores de arte y audio, exportación web y pruebas
```

## Pruebas

Scripts en `tools/` que se lanzan con Godot (`godot --headless --path . -s tools/smoke_test.gd`): humo, tienda, guardado, pausa, victoria, derrota, audio y controles táctiles.

## Autor

**Enrique Gómez Díaz** · [enriquegd2004@gmail.com](mailto:enriquegd2004@gmail.com) · [GitHub](https://github.com/EnriqueGD08)
