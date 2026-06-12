# event_bus.gd
# Bus de señales global. Autoload registrado como "EventBus" en project.godot.
# DIP: los sistemas se comunican a través de este bus sin conocerse entre sí.
# SRP: única responsabilidad es centralizar las señales globales del juego.
#
# USO:
#   Emitir:   EventBus.enemy_died.emit(enemy)
#   Escuchar: EventBus.enemy_died.connect(_on_enemy_died)
#
# IMPORTANTE: las señales locales (entre nodo padre e hijo) siguen usando
# señales normales de Godot. Este bus solo gestiona comunicación entre
# sistemas que no tienen relación directa en el árbol de nodos.

extends Node

# ── Personaje ─────────────────────────────────────────────────────────────────

## Emitida por BaseCharacter cuando el HP llega a 0.
signal character_died(character: Node)

## Emitida por BaseCharacter cuando se activa la transformación.
signal transform_activated(character: Node)

## Emitida por BaseCharacter cuando se desactiva la transformación.
signal transform_deactivated(character: Node)

## Emitida por el componente de transformación cuando el cooldown termina.
signal transform_cooldown_ready(character: Node)

## Emitida por Arcee al cambiar de arma activa.
## [param weapon_type] "melee" o "ranged".
signal weapon_swapped(weapon_type: String)

# ── Enemigos ──────────────────────────────────────────────────────────────────

## Emitida por BaseEnemy al morir.
signal enemy_died(enemy: Node)

## Emitida por EnemySpawner cuando no quedan enemigos vivos.
signal all_enemies_dead()

## Emitida por BossEnemy al aparecer en escena.
signal boss_spawned(boss: Node)

## Emitida por BossEnemy al cambiar de fase.
signal boss_phase_changed(boss: Node, phase: int)

## Emitida por BossEnemy cuando su HP cambia (para la barra de HP del HUD).
signal boss_hp_changed(boss: Node, current_hp: float, max_hp: float)

## Emitida por BossEnemy al morir.
signal boss_defeated(boss: Node)

# ── Oleadas ───────────────────────────────────────────────────────────────────

## Emitida por WaveManager al iniciar una oleada.
signal wave_started(wave_number: int, total_waves: int)

## Emitida por WaveManager al completar una oleada.
signal wave_completed(wave_number: int)

## Emitida por WaveManager al completar todas las oleadas.
signal all_waves_completed()

## Emitida por WaveManager cuando el juego termina por muerte del jugador.
signal game_over()

# ── Economía ──────────────────────────────────────────────────────────────────

## Emitida por BaseEnemy al morir para generar el drop de energon.
## [param position] Posición del drop. [param amount] Cantidad de energon.
signal energon_dropped(position: Vector2, amount: int)

## Emitida por EnergonManager cuando el jugador recoge energon.
signal energon_collected(amount: int, total: int)

## Emitida por BaseEnemy al morir para conceder XP al árbol de habilidades.
signal xp_earned(amount: int)

# ── Árbol de habilidades ──────────────────────────────────────────────────────

## Emitida por SkillTreeManager al desbloquear un nodo.
signal skill_unlocked(skill_id: String)

## Emitida por SkillTreeManager cuando cambian los puntos disponibles.
signal skill_points_changed(available: int)

# ── Jefe y árbol de habilidades ───────────────────────────────────────────────

## Emitida por WaveManager al terminar una oleada para abrir el árbol.
signal skill_tree_opened()

## Emitida por la UI del árbol al cerrarse para continuar la siguiente oleada.
signal skill_tree_closed()

# ── Audio ─────────────────────────────────────────────────────────────────────

## Emitida por cualquier sistema para solicitar un efecto de sonido.
## AudioManager escucha esta señal.
signal play_sfx(sfx_id: String)

## Emitida por cualquier sistema para solicitar música.
signal play_music(track_id: String)

## Emitida para detener la música con fade opcional.
signal stop_music(fade_duration: float)

# ── HUD ───────────────────────────────────────────────────────────────────────

## Emitida por BaseCharacter cuando cambia su HP.
signal player_hp_changed(current: float, maximum: float)

## Emitida por CooldownManager con el progreso del cooldown de transformación.
signal transform_cooldown_updated(remaining: float, total: float)

## Emitida por EnergonManager cuando cambia el energon del jugador.
signal player_energon_changed(amount: int)

# ── Guardado ──────────────────────────────────────────────────────────────────

## Emitida cuando el juego debe guardarse (fin de oleada, menú, etc.).
signal save_requested()

## Emitida cuando el juego debe cargarse (inicio de sesión).
signal load_requested()
