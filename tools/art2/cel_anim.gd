# cel_anim.gd
# Herramienta de desarrollo: animaciones COMUNES a todos los personajes en estilo cel.
# Cada fotograma se calcula con curvas suaves, a 24 fotogramas por segundo.
# SRP: solo decide el movimiento; las formas las pone el diseño D.

extends RefCounted

const C := preload("res://tools/art2/cel_character.gd")
const R := preload("res://tools/art2/vector_rig.gd")

const FPS := 24.0

## Fotograma del disparo en que sale el proyectil: FIRE_FRAME / FPS = 0,25 s
## (es el windup_seconds de las armas a distancia).
const FIRE_FRAME := 6.0

## Fotograma del golpe en que el arma pasa por delante: STRIKE_FRAME / FPS = 0,17 s
## (es el windup_seconds de las armas cuerpo a cuerpo).
const STRIKE_FRAME := 4.0

const GROUND := 212.0


static func _ease(t: float) -> float:
	t = clampf(t, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)


## Sale rápido y frena: para retrocesos y golpes.
static func _ease_out(t: float) -> float:
	t = clampf(t, 0.0, 1.0)
	return 1.0 - pow(1.0 - t, 3.0)


## Reposo: respira. 32 fotogramas (1,3 s). La cabeza y el brazo van con retraso.
static func idle(D, skin: String, k: float = 1.0) -> Array:
	var out: Array = []
	for i in 32:
		var t: float = float(i) / 32.0 * TAU
		out.append(C.robot(D, skin, {
			"bob": sin(t) * 2.0,
			"torso": sin(t) * 0.6,
			"head": sin(t - 0.8) * 1.2,
			"gun_sh": -16.0 + sin(t - 0.5) * 1.8,
			"gun_el": -12.0 + sin(t - 1.0) * 1.8,
			"fist_sh": 7.0 - sin(t - 0.5) * 1.6,
			"fist_el": 8.0 - sin(t - 1.0) * 2.0,
			"charge": 0.25 + 0.12 * sin(t * 2.0),
		}, k))
	return out


## Trayectoria de un pie en un ciclo (u de 0 a 1), relativa al centro de la zancada.
## Apoyo (58 %): el pie queda FIJO en el mundo, así que retrocede a velocidad constante
## respecto al cuerpo. Balanceo (42 %): se levanta y avanza. Al apoyar entra de talón
## (punta arriba) y al despegar sale de punta (talón arriba).
static func foot_track(u: float, half_stride: float, lift: float) -> Dictionary:
	const STANCE := 0.58
	u = fposmod(u, 1.0)
	var x: float
	var y: float = 0.0
	var deg: float = 0.0
	if u < STANCE:
		var s: float = u / STANCE
		x = lerpf(half_stride, -half_stride, s)
		if s < 0.15:
			deg = lerpf(-14.0, 0.0, _ease(s / 0.15))        # talón → planta
		elif s > 0.7:
			deg = lerpf(0.0, 22.0, _ease((s - 0.7) / 0.3))  # planta → punta
			y = -sin(deg_to_rad(deg)) * 20.0                # el tobillo sube al girar sobre la punta
	else:
		var s: float = (u - STANCE) / (1.0 - STANCE)
		x = lerpf(-half_stride, half_stride, _ease(s))
		y = -sin(deg_to_rad(22.0)) * 20.0 * (1.0 - s) - sin(PI * pow(s, 0.8)) * lift
		deg = lerpf(22.0, -14.0, _ease(s))
	return {"x": x, "y": y, "deg": deg}


static func _walk_legs(D, u: float, pose: Dictionary) -> void:
	var a: Dictionary = foot_track(u, D.HALF_STRIDE, D.LIFT)
	var b: Dictionary = foot_track(u + 0.5, D.HALF_STRIDE, D.LIFT)
	pose["near_foot"] = Vector2(D.WALK_CENTER - 4.0 + a.x, GROUND + a.y)
	pose["far_foot"] = Vector2(D.WALK_CENTER + 8.0 + b.x, GROUND + b.y)
	pose["near_deg"] = a.deg
	pose["far_deg"] = b.deg
	pose["crouch"] = 3.0


## Caminar: 16 fotogramas (0,67 s por ciclo). El cuerpo baja cuando los dos pies tocan el
## suelo y sube cuando una pierna pasa junto a la otra.
static func walk(D, skin: String, k: float = 1.0) -> Array:
	var out: Array = []
	for i in 16:
		var u: float = float(i) / 16.0
		var ph: float = u * TAU
		var pose := {
			"bob": cos(ph * 2.0) * 2.5,
			"sway": sin(ph * 2.0) * 1.0,
			"torso": 4.0 + cos(ph) * 1.6,
			"head": -cos(ph) * 1.2,
			# Los brazos van al revés que la pierna de su lado, con un poco de retraso.
			"gun_sh": -24.0 + cos(ph - 0.4) * 9.0,
			"gun_el": -16.0 + cos(ph - 0.9) * 5.0,
			"fist_sh": 6.0 - cos(ph - 0.4) * 16.0,
			"fist_el": 12.0 - cos(ph - 0.9) * 8.0,
			"charge": 0.25,
		}
		_walk_legs(D, u, pose)
		out.append(C.robot(D, skin, pose, k))
	return out


## Disparo: 20 fotogramas. Sube el brazo, retroceso seco en FIRE_FRAME y vuelve suave.
## walking: las piernas siguen el ciclo de caminar (para disparar en movimiento).
## extra: claves de pose que se añaden a cada fotograma (p. ej. piernas colgando al volar).
static func fire(D, skin: String, k: float = 1.0, walking: bool = false, extra: Dictionary = {}) -> Array:
	var out: Array = []
	for i in 20:
		var f: float = float(i)
		var raise: float = _ease(f / 5.0)
		var kick: float = 0.0
		var flash: float = 0.0
		if f >= FIRE_FRAME:
			kick = _ease_out((f - FIRE_FRAME) / 2.0) * (1.0 - _ease((f - 8.0) / 8.0))
			flash = maxf(1.0 - (f - FIRE_FRAME) / 4.0, 0.0)
		var back: float = _ease((f - 14.0) / 6.0)
		var aim: float = raise * (1.0 - back)
		var pose := {
			"bob": aim * 1.5 + kick * 1.5,
			"sway": -kick * 5.0,
			"torso": -kick * 5.0 + aim * 2.0,
			"head": -kick * 3.0,
			"gun_sh": lerpf(-16.0, -72.0, aim) + kick * -14.0,
			"gun_el": lerpf(-12.0, -18.0, aim) + kick * 12.0,
			"fist_sh": 7.0 + kick * 8.0,
			"fist_el": 8.0 + aim * 6.0,
			"charge": (0.25 + raise * 0.75) * (1.0 - clampf((f - FIRE_FRAME) / 2.0, 0.0, 1.0)) + back * 0.25,
			"flash": flash,
		}
		if walking:
			var u: float = f / 16.0
			var ph: float = u * TAU
			_walk_legs(D, u, pose)
			pose["bob"] = cos(ph * 2.0) * 2.5 + kick * 1.5
			pose["torso"] = 4.0 + cos(ph) * 1.6 - kick * 5.0
		pose.merge(extra)
		out.append(C.robot(D, skin, pose, k))
	return out


## Golpe cuerpo a cuerpo: 14 fotogramas (0,58 s). Sube el arma sobre la cabeza, la baja de
## golpe con una estela y recupera. walking: las piernas siguen el ciclo de caminar.
## Un diseño puede limitar cuánto sube el arma (SWING_TOP) y el alcance de la estela
## (TRAIL_RADIUS); ring dibuja una onda en el suelo al golpear.
static func swing(D, skin: String, k: float = 1.0, walking: bool = false, ring: bool = false) -> Array:
	var consts: Dictionary = D.get_script_constant_map()
	const READY_DEG := -28.0
	var TOP_DEG: float = consts.get("SWING_TOP", -165.0)
	const END_DEG := -22.0
	var TRAIL_FROM: float = maxf(-140.0, TOP_DEG)  # más arriba se saldría del lienzo
	var trail_radius: float = consts.get("TRAIL_RADIUS", 124.0)
	var out: Array = []
	for i in 14:
		var f: float = float(i)
		var deg: float
		if f <= STRIKE_FRAME - 1.0:
			deg = lerpf(READY_DEG, TOP_DEG, _ease(f / (STRIKE_FRAME - 1.0)))
		elif f <= STRIKE_FRAME + 1.0:
			deg = lerpf(TOP_DEG, END_DEG, _ease_out((f - STRIKE_FRAME + 1.0) / 2.0))
		else:
			deg = lerpf(END_DEG, READY_DEG, _ease((f - STRIKE_FRAME - 1.0) / 8.0))
		var up: float = inverse_lerp(READY_DEG, TOP_DEG, deg)
		var impact: float = maxf(1.0 - absf(f - STRIKE_FRAME - 1.0) / 4.0, 0.0) if f >= STRIKE_FRAME else 0.0
		# El codo se dobla arriba y se estira al bajar; el brazo entero sigue el ángulo total.
		var el: float = lerpf(-12.0, -35.0, up)
		var pose := {
			"bob": up * -2.0 + impact * 2.5,
			"sway": up * -4.0 + impact * 7.0,
			"torso": up * -8.0 + impact * 9.0,
			"head": impact * 4.0,
			"crouch": impact * 5.0,
			"gun_sh": deg - el,
			"gun_el": el,
			"fist_sh": 7.0 + up * 16.0 - impact * 14.0,
			"fist_el": 8.0 + up * 10.0,
			"charge": 0.25 + up * 0.5 + impact * 0.5,
		}
		if f >= STRIKE_FRAME and f <= STRIKE_FRAME + 4.0:
			var fade: float = 1.0 - (f - STRIKE_FRAME) / 5.0
			pose["trail"] = [TRAIL_FROM, maxf(deg, TRAIL_FROM), fade * 0.8, trail_radius]
		if ring and f >= STRIKE_FRAME + 1.0:
			pose["ground_ring"] = (f - STRIKE_FRAME - 1.0) / 8.0
		if walking:
			var u: float = f / 14.0
			var ph: float = u * TAU
			_walk_legs(D, u, pose)
			pose["bob"] = cos(ph * 2.0) * 2.5 + impact * 1.5
		out.append(C.robot(D, skin, pose, k))
	return out


## Directo: 7 fotogramas (0,29 s), más rápido que cualquier otro ataque.
## mano: "derecha" lanza el brazo principal; "izquierda" cruza el otro por delante del pecho.
static func punch(D, skin: String, k: float = 1.0, hand: String = "derecha", walking: bool = false) -> Array:
	var out: Array = []
	for i in 7:
		var f: float = float(i)
		var load: float = sin(clampf(f / 2.0, 0.0, 1.0) * PI)                      # echa el brazo atrás
		var out_t: float = _ease_out((f - 1.0) / 1.0) * (1.0 - _ease((f - 3.0) / 4.0))  # sale y vuelve
		var flash: float = maxf(1.0 - (f - 2.0) / 2.0, 0.0) if f >= 2.0 else 0.0
		var pose := {
			"bob": out_t * 2.0,
			"sway": -load * 4.0 + out_t * 8.0,
			"torso": -load * 5.0 + out_t * 10.0,
			"head": -out_t * 4.0,
			"charge": 0.25 + out_t * 0.6,
		}
		if hand == "derecha":
			pose["gun_sh"] = lerpf(-16.0 + load * 26.0, -86.0, out_t)
			pose["gun_el"] = lerpf(-12.0 - load * 50.0, -6.0, out_t)
			pose["fist_sh"] = 7.0 + out_t * 14.0
			pose["fist_el"] = 8.0 + out_t * 30.0
			pose["flash"] = flash * 0.75
		else:
			pose["fist_front"] = true
			pose["fist_sh"] = lerpf(7.0 + load * 14.0, -84.0, out_t)
			pose["fist_el"] = lerpf(8.0 - load * 40.0, -6.0, out_t)
			pose["gun_sh"] = -16.0 + out_t * 34.0
			pose["gun_el"] = -12.0 - out_t * 40.0
			pose["fist_flash"] = flash * 0.75
			pose["sway"] = -load * 4.0 + out_t * 12.0
		if walking:
			_walk_legs(D, f / 7.0, pose)
		out.append(C.robot(D, skin, pose, k))
	return out


## Remate: gancho ascendente de 11 fotogramas (0,46 s), con estela y salto corto.
static func uppercut(D, skin: String, k: float = 1.0, walking: bool = false) -> Array:
	const TRAIL_FROM := -35.0
	const TRAIL_TO := -165.0
	var out: Array = []
	for i in 11:
		var f: float = float(i)
		var load: float = _ease(f / 2.0) * (1.0 - _ease((f - 2.0) / 1.0))
		var rise: float = _ease_out((f - 2.0) / 2.0) * (1.0 - _ease((f - 5.0) / 6.0))
		var deg: float = lerpf(10.0 * load - 28.0, TRAIL_TO, rise)
		var el: float = lerpf(-12.0 - load * 70.0, -22.0, rise)
		var pose := {
			"crouch": load * 12.0 - rise * 6.0,
			"sway": rise * 6.0,
			"torso": -load * 4.0 + load * 10.0 - rise * 10.0,
			"head": -rise * 10.0,
			"gun_sh": deg - el,
			"gun_el": el,
			"fist_sh": 7.0 + rise * 20.0,
			"fist_el": 8.0 + rise * 34.0,
			"charge": 0.4 + rise * 0.6,
			"flash": maxf(1.0 - absf(f - 4.0) / 3.0, 0.0),
		}
		if f >= 3.0 and f <= 7.0:
			pose["trail"] = [TRAIL_FROM, deg, (1.0 - (f - 3.0) / 5.0) * 0.8, 78.0]
		if walking:
			_walk_legs(D, f / 11.0, pose)
		out.append(C.robot(D, skin, pose, k))
	return out


## Tajo doble en X: 8 fotogramas (0,33 s). Abre los dos brazos y los cruza hacia abajo.
static func cross_slash(D, skin: String, k: float = 1.0, walking: bool = false) -> Array:
	const TOP := -130.0
	const END := -24.0
	var out: Array = []
	for i in 8:
		var f: float = float(i)
		var deg: float
		if f <= 1.0:
			deg = lerpf(-28.0, TOP, _ease(f))
		elif f <= 3.0:
			deg = lerpf(TOP, END, _ease_out((f - 1.0) / 2.0))
		else:
			deg = lerpf(END, -28.0, _ease((f - 3.0) / 4.0))
		var up: float = inverse_lerp(-28.0, TOP, deg)
		var impact: float = maxf(1.0 - absf(f - 3.0) / 3.0, 0.0) if f >= 2.0 else 0.0
		var pose := {
			"fist_front": true,
			"bob": impact * 2.0,
			"sway": up * -3.0 + impact * 6.0,
			"torso": up * -7.0 + impact * 9.0,
			"crouch": impact * 4.0,
			"head": impact * 3.0,
			"gun_sh": deg + 12.0,
			"gun_el": -12.0,
			"fist_sh": deg + 22.0,
			"fist_el": -22.0,
			"charge": 0.3 + up * 0.3 + impact * 0.5,
		}
		if f >= 2.0 and f <= 5.0:
			var fade: float = 1.0 - (f - 2.0) / 4.0
			pose["trail"] = [TOP, deg if f <= 3.0 else END, fade * 0.75, 112.0]
			pose["fist_trail"] = [TOP, deg if f <= 3.0 else END, fade * 0.75, 112.0]
		if walking:
			_walk_legs(D, f / 8.0, pose)
		out.append(C.robot(D, skin, pose, k))
	return out


## Doble disparo: 7 fotogramas (0,29 s). Las dos manos al frente, fogonazo y retroceso.
static func dual_fire(D, skin: String, k: float = 1.0, walking: bool = false) -> Array:
	var out: Array = []
	for i in 7:
		var f: float = float(i)
		var raise: float = _ease(f / 2.0) * (1.0 - _ease((f - 4.0) / 3.0))
		var kick: float = maxf(1.0 - (f - 2.0) / 2.0, 0.0) if f >= 2.0 else 0.0
		var pose := {
			"fist_front": true,
			"bob": kick * 1.5,
			"sway": -kick * 4.0,
			"torso": raise * 2.0 - kick * 4.0,
			"head": -kick * 2.0,
			"gun_sh": lerpf(-16.0, -78.0, raise) - kick * 8.0,
			"gun_el": lerpf(-12.0, -10.0, raise) + kick * 8.0,
			"fist_sh": lerpf(7.0, -74.0, raise) - kick * 8.0,
			"fist_el": lerpf(8.0, -12.0, raise) + kick * 8.0,
			"charge": 0.2 + raise * 0.4,
			"flash": kick * 0.6,
			"fist_flash": kick * 0.6,
		}
		if walking:
			_walk_legs(D, f / 7.0, pose)
		out.append(C.robot(D, skin, pose, k))
	return out


# ── Enemigos ──────────────────────────────────────────────────────────────────

## Pose de vuelo: cuerpo en el aire, piernas colgando y propulsores encendidos.
## u: fase (0 a 1), speed: 0 parado, 1 avanzando (se inclina y empuja más).
static func _hover_pose(D, u: float, speed: float) -> Dictionary:
	const LIFT_UP := 12.0  # más alto se salen las alas por arriba del lienzo
	var ph: float = u * TAU
	var bob: float = sin(ph) * 3.0
	var hip_y: float = D.HIP_Y - LIFT_UP + bob
	var swing: float = sin(ph + 0.6) * (2.0 + speed * 3.0)
	var reach: float = D.THIGH + D.SHIN - 18.0  # rodillas algo dobladas
	return {
		"crouch": -LIFT_UP,
		"bob": bob,
		"torso": speed * 10.0 + sin(ph) * 1.0,
		"head": -speed * 6.0,
		"near_foot": Vector2(150.0 - D.HIP_HALF - 10.0 - speed * 12.0 + swing, hip_y + 2.0 + reach),
		"far_foot": Vector2(150.0 + D.HIP_HALF - 4.0 - speed * 12.0 - swing, hip_y + reach - 2.0),
		"near_deg": 30.0 + speed * 10.0,
		"far_deg": 34.0 + speed * 10.0,
		"thrust": 0.5 + speed * 0.4 + sin(ph * 3.0) * 0.1,
	}


## Vuelo: 24 fotogramas. speed 0 = suspendido en el aire; 1 = avanzando.
static func hover(D, skin: String, k: float = 1.0, speed: float = 0.0) -> Array:
	var out: Array = []
	for i in 24:
		var u: float = float(i) / 24.0
		var pose := _hover_pose(D, u, speed)
		pose["gun_sh"] = -18.0 + sin(u * TAU - 0.5) * 2.0 - speed * 10.0
		pose["gun_el"] = -14.0
		pose["fist_sh"] = 10.0 + speed * 14.0
		pose["fist_el"] = 10.0
		pose["charge"] = 0.3
		out.append(C.robot(D, skin, pose, k))
	return out


## Muerte de enemigo: 18 fotogramas. Encaja el golpe, se oscurece y revienta en una
## explosión que lo hace desaparecer (el juego lo borra al terminar).
## flying: en vez de arrodillarse, se inclina y cae.
static func enemy_death(D, skin: String, k: float = 1.0, flying: bool = false) -> Array:
	var out: Array = []
	for i in 18:
		var f: float = float(i)
		var hit: float = sin(clampf(f / 5.0, 0.0, 1.0) * PI)
		var sag: float = _ease(f / 9.0)
		var pose: Dictionary = _hover_pose(D, 0.0, 0.0) if flying else {}
		pose.merge({
			"no_shadow": true,
			"sway": -hit * 6.0,
			"torso": -hit * 8.0 + sag * 14.0,
			"head": -hit * 8.0 + sag * 20.0,
			"crouch": float(pose.get("crouch", 0.0)) + (sag * 10.0 if flying else sag * 26.0),
			"gun_sh": lerpf(-16.0, -2.0, sag) - hit * 24.0,
			"gun_el": lerpf(-12.0, 4.0, sag),
			"fist_sh": lerpf(8.0, 0.0, sag) + hit * 20.0,
			"fist_el": 8.0,
			"dim": sag,
			"dead": f >= 6.0,
			"charge": 0.0,
		}, true)
		if flying:
			pose.erase("thrust")
		var r = C.canvas(D, skin)
		var vanish: float = 1.0 - _ease((f - 8.0) / 4.0)
		r.add(R.ellipse(150, 224, D.SHADOW_W, 7, "#000000", 0.3 * vanish))
		var body: String = C.robot_svg(D, skin, pose)
		if flying:
			body = R.rotated(Vector2(150, 120), sag * 28.0, body)
		if vanish > 0.0:
			r.add(R.faded(vanish, body))
		r.add(C.explosion(Vector2(150, 120), (f - 7.0) / 11.0))
		out.append(r.render_scaled(k))
	return out


## Rugido de la segunda fase de un jefe: 24 fotogramas (1 s). Se encoge, abre los brazos
## hacia arriba con la cabeza atrás y suelta una onda de energía; luego vuelve a la guardia.
static func roar(D, skin: String, k: float = 1.0) -> Array:
	var out: Array = []
	for i in 24:
		var f: float = float(i)
		var gather: float = _ease(f / 5.0) * (1.0 - _ease((f - 5.0) / 3.0))
		var open: float = _ease((f - 5.0) / 3.0) * (1.0 - _ease((f - 16.0) / 8.0))
		var shake: float = sin(f * 2.7) * 2.0 * open
		var pose := {
			"crouch": gather * 12.0 - open * 4.0,
			"sway": shake,
			"torso": gather * 8.0 - open * 10.0,
			"head": gather * 10.0 - open * 22.0,
			"gun_sh": lerpf(-16.0, -132.0, open) + gather * 20.0,  # más arriba se sale del lienzo
			"gun_el": lerpf(-12.0, -20.0, open),
			"fist_sh": lerpf(8.0, 104.0, open) - gather * 16.0,
			"fist_el": lerpf(8.0, 20.0, open),
			"charge": 0.3 + open * 0.7,
		}
		var r = C.canvas(D, skin)
		var p: Dictionary = D.SKINS[skin]
		if open > 0.01:
			var t: float = clampf((f - 6.0) / 12.0, 0.0, 1.0)
			r.add(R.circle(150, 110, 60.0 + 70.0 * t, "url(#e_glow)", 0.0, 0.55 * open * (1.0 - t * 0.6)))
		r.add(C.robot_svg(D, skin, pose))
		if open > 0.01:
			C.energy_arcs(r, p, Vector2(150, 100), clampf((f - 5.0) / 14.0, 0.0, 1.0))
		out.append(r.render_scaled(k))
	return out


## Animaciones de un jefe. attack: "punch", "smash" (mazazo con onda) o "fire".
static func boss_set(D, skin: String, k: float, attack: String) -> Dictionary:
	var hit: Array
	match attack:
		"punch":
			hit = uppercut(D, skin, k)
		"smash":
			hit = swing(D, skin, k, false, true)
		_:
			hit = fire(D, skin, k)
	return {
		"idle": idle(D, skin, k),
		"walk": walk(D, skin, k),
		"attack": hit,
		"phase2_intro": roar(D, skin, k),
		"death": enemy_death(D, skin, k),
	}


## Animaciones de un enemigo de cuerpo a cuerpo. ring: el golpe hace temblar el suelo.
static func enemy_melee(D, skin: String, k: float, ring: bool = false) -> Dictionary:
	return {
		"idle": idle(D, skin, k),
		"walk": walk(D, skin, k),
		"attack": swing(D, skin, k, false, ring),
		"death": enemy_death(D, skin, k),
	}


## Animaciones de un enemigo volador que dispara.
static func enemy_flyer(D, skin: String, k: float) -> Dictionary:
	return {
		"idle": hover(D, skin, k, 0.0),
		"walk": hover(D, skin, k, 1.0),
		"attack": fire(D, skin, k, false, _hover_pose(D, 0.0, 0.0)),
		"death": enemy_death(D, skin, k, true),
	}


## Vehículo parado: 16 fotogramas.
static func vehicle_idle(D, skin: String, k: float = 1.0) -> Array:
	var out: Array = []
	for i in 16:
		var t: float = float(i) / 16.0 * TAU
		out.append(D.vehicle(D, skin, {"bob": sin(t * 2.0) * 0.6 + sin(t) * D.VEHICLE_HOVER, "charge": 0.45 + 0.3 * sin(t),
			"boost": 0.45 + 0.15 * sin(t * 2.0)}, k))
	return out


## Vehículo en marcha: 12 fotogramas; el bucle no salta.
static func vehicle_drive(D, skin: String, k: float = 1.0) -> Array:
	var out: Array = []
	for i in 12:
		var t: float = float(i) / 12.0
		out.append(D.vehicle(D, skin, {"tread": t, "bob": sin(t * TAU * 2.0) * 0.8 + sin(t * TAU) * D.VEHICLE_HOVER,
			"charge": 0.35 + 0.2 * sin(t * TAU), "boost": 0.9 + 0.1 * sin(t * TAU * 3.0), "lines": t}, k))
	return out


## Disparo del vehículo: 16 fotogramas.
static func vehicle_fire(D, skin: String, k: float = 1.0) -> Array:
	var out: Array = []
	for i in 16:
		var f: float = float(i)
		var kick: float = _ease_out(f / 2.0) * (1.0 - _ease((f - 2.0) / 12.0))
		out.append(D.vehicle(D, skin, {"recoil": kick * D.VEHICLE_RECOIL, "bob": kick * 2.0, "flash": maxf(1.0 - f / 4.0, 0.0),
			"charge": clampf((f - 6.0) / 10.0, 0.0, 0.35), "boost": 0.6}, k))
	return out


## Transformación: 20 fotogramas. El juego la reproduce al revés para volver a robot.
static func transform(D, skin: String, k: float = 1.0) -> Array:
	var out: Array = []
	for i in 20:
		out.append(D.morph(D, skin, float(i) / 19.0, k))
	return out


## Muerte: 24 fotogramas. Encaja el golpe, le fallan las rodillas, cae de golpe con un
## pequeño rebote y se queda arrodillado, apagado.
static func death(D, skin: String, k: float = 1.0) -> Array:
	var out: Array = []
	for i in 24:
		var f: float = float(i)
		var hit: float = sin(clampf(f / 6.0, 0.0, 1.0) * PI)
		var drop: float = pow(clampf((f - 5.0) / 8.0, 0.0, 1.0), 2.0)             # acelera como una caída
		var bounce: float = sin(clampf((f - 13.0) / 6.0, 0.0, 1.0) * PI) * 5.0
		var slump: float = _ease((f - 8.0) / 10.0)
		out.append(C.robot(D, skin, {
			"crouch": drop * 58.0 - bounce,
			"bob": hit * 2.0,
			"sway": -hit * 7.0,
			"torso": -hit * 9.0 + slump * 16.0,
			"head": -hit * 8.0 + slump * 26.0,
			"near_foot": D.NEAR_FOOT + Vector2(-slump * 14.0, 0),
			"far_foot": D.FAR_FOOT + Vector2(slump * 12.0, 0),
			"gun_sh": lerpf(-16.0, -4.0, slump) - hit * 26.0,
			"gun_el": lerpf(-12.0, 4.0, slump),
			"fist_sh": lerpf(8.0, -2.0, slump) + hit * 22.0,
			"fist_el": lerpf(8.0, 2.0, slump),
			"dead": f >= 9.0,
			"dim": slump,
			"charge": maxf(0.3 - f * 0.04, 0.0),
		}, k))
	return out


## Todas las animaciones de un personaje cuerpo a cuerpo.
static func all_melee(D, skin: String, k: float) -> Dictionary:
	var anims: Dictionary = all(D, skin, k)
	anims["attack"] = swing(D, skin, k)
	anims["walk_attack"] = swing(D, skin, k, true)
	return anims


## Todas las animaciones de un personaje de puñetazos: combo de dos directos y remate.
static func all_puncher(D, skin: String, k: float) -> Dictionary:
	var anims: Dictionary = all(D, skin, k)
	anims["attack"] = punch(D, skin, k, "derecha")
	anims["walk_attack"] = punch(D, skin, k, "derecha", true)
	anims["attack_cross"] = punch(D, skin, k, "izquierda")
	anims["walk_attack_cross"] = punch(D, skin, k, "izquierda", true)
	anims["attack_finisher"] = uppercut(D, skin, k)
	anims["walk_attack_finisher"] = uppercut(D, skin, k, true)
	return anims


## Todas las animaciones de un personaje con dos juegos de armas: D lleva las de cuerpo a
## cuerpo y D_ranged las de distancia (con sus propios reposo y caminar).
static func all_hybrid(D, D_ranged, skin: String, k: float) -> Dictionary:
	var anims: Dictionary = all(D, skin, k)
	anims["attack"] = cross_slash(D, skin, k)
	anims["walk_attack"] = cross_slash(D, skin, k, true)
	anims["ranged_idle"] = idle(D_ranged, skin, k)
	anims["ranged_walk"] = walk(D_ranged, skin, k)
	anims["ranged_attack"] = dual_fire(D_ranged, skin, k)
	anims["ranged_walk_attack"] = dual_fire(D_ranged, skin, k, true)
	return anims


## Como all(), para quien se transforma en una torreta inmóvil: sin marcha ni disparo propio.
static func all_turret(D, skin: String, k: float) -> Dictionary:
	var anims: Dictionary = all(D, skin, k)
	anims.erase("transform_walk")
	anims.erase("transform_attack")
	return anims


## Todas las animaciones de un personaje a distancia, con los nombres que usa el juego.
static func all(D, skin: String, k: float) -> Dictionary:
	return {
		"idle": idle(D, skin, k),
		"walk": walk(D, skin, k),
		"attack": fire(D, skin, k),
		"walk_attack": fire(D, skin, k, true),
		"transform_activate": transform(D, skin, k),
		"transform_idle": vehicle_idle(D, skin, k),
		"transform_walk": vehicle_drive(D, skin, k),
		"transform_attack": vehicle_fire(D, skin, k),
		"death": death(D, skin, k),
	}
