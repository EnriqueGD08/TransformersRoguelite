# cel_character.gd
# Herramienta de desarrollo: esqueleto COMÚN de los personajes en estilo cel.
# SRP: sabe dónde va cada pieza y cómo se articula; las formas las pone cada diseño D.
# OCP: un personaje nuevo es un script nuevo con sus piezas, sin tocar este archivo.
#
# Un diseño D define: SKINS, THIGH, SHIN, HIP_Y, HIP_HALF, SHOULDER_X, SHOULDER_Y, NECK,
# NEAR_FOOT, FAR_FOOT, SHADOW_W, HALF_STRIDE, LIFT, WALK_CENTER, VEHICLE_RECOIL (y EXTRA_Y si
# necesita más altura) y las
# funciones head, torso, back, pelvis, thigh, shin, foot, shoulder, upper_arm, fist_arm,
# gun, vehicle(D, skin, pose, k) y morph(D, skin, t, k).

extends RefCounted

const R := preload("res://tools/art2/vector_rig.gd")


## Lienzo común. Su centro (x=150, y=112) es el centro del cuerpo: así el origen del nodo
## es el del personaje y girarlo al mirar a la izquierda no lo descuadra.
static func canvas(D, skin: String) -> RefCounted:
	var p: Dictionary = D.SKINS[skin]
	# Un diseño puede pedir lienzo más alto (EXTRA_Y arriba y abajo): el centro no se mueve.
	var extra: int = D.get_script_constant_map().get("EXTRA_Y", 0)
	var r = R.new(400, 240 + extra * 2)
	r.left_margin = 50
	r.top_margin = 16 + extra
	r._defs["e_glow"] = ('<radialGradient id="e_glow"><stop offset="0" stop-color="#ffffff"/><stop offset="0.3" stop-color="%s"/>'
		+ '<stop offset="1" stop-color="%s" stop-opacity="0"/></radialGradient>') % [R.hex(p.energy), R.hex(p.energy)]
	return r


## Oscurece la paleta y apaga los ojos (al morir).
static func _adjusted_palette(p: Dictionary, pose: Dictionary) -> Dictionary:
	var dim: float = pose.get("dim", 0.0)
	if dim <= 0.0 and not pose.get("dead", false):
		return p
	var out := {}
	for key in p:
		out[key] = p[key].darkened(dim * 0.45)
	if pose.get("dead", false):
		out["eye"] = Color("3a2c2c")
		out["energy"] = p.energy.darkened(0.7)
	return out


## Paleta oscurecida para la pierna de detrás: separa las dos piernas al cruzarse.
static func _far_palette(p: Dictionary) -> Dictionary:
	var out := {}
	for key in p:
		out[key] = p[key].darkened(0.28)
	return out


## foot_deg: inclinación del pie (+ = punta abajo al despegar, - = punta arriba al apoyar).
static func _leg(D, skin: String, p: Dictionary, hip: Vector2, foot: Vector2, foot_deg: float = 0.0) -> String:
	var a: Array = R.ik(hip, foot, D.THIGH, D.SHIN, -1.0)
	var ankle := R.circle(0, D.SHIN, 9.0, R.hex(p.dark_s), 2.4)
	var lower: String = ankle + D.shin(skin, p) + R.joint(Vector2(0, D.SHIN), -a[0] - a[1] + foot_deg, D.foot(skin, p))
	var knee := R.circle(0, D.THIGH, 11.0, R.hex(p.dark_s), 2.4)
	return R.joint(hip, a[0], D.thigh(skin, p) + knee + R.joint(Vector2(0, D.THIGH), a[1], lower))


## y: distancia desde el codo a la que aparece (por defecto, la boca del cañón).
static func _muzzle_flash(p: Dictionary, k: float, y: float = 80.0) -> String:
	if k <= 0.01:
		return ""
	return R.joint(Vector2(0, y - 80.0), 0.0, _flash_shape(p, k))


static func _flash_shape(p: Dictionary, k: float) -> String:
	var e: Color = p.energy
	var f := R.circle(0, 88, 34.0 * k, "url(#e_glow)", 0.0, 1.0)
	f += R.shape(R.path(R.v([-10 * k,80, 0,80 + 54 * k, 10 * k,80])), R.hex(e.lightened(0.35)), 0.0)
	f += R.shape(R.path(R.v([-26 * k,84, 0,78, 26 * k,84, 0,92])), R.hex(e.lightened(0.35)), 0.0)
	f += R.circle(0, 84, 9.0 * k, "#ffffff")
	return f


## Media luna de energía entre dos ángulos del brazo.
## trail = [desde, hasta, opacidad, radio (opcional, alcance del arma)].
static func _swing_trail(p: Dictionary, shoulder: Vector2, trail: Array) -> String:
	var radius: float = trail[3] if trail.size() > 3 else 124.0
	var outer := PackedVector2Array()
	var inner := PackedVector2Array()
	for i in 13:
		var deg: float = lerpf(trail[0], trail[1], float(i) / 12.0)
		var d := Vector2(0, 1).rotated(deg_to_rad(deg))
		# Fina en la cola y gruesa junto al arma.
		outer.append(shoulder + d * radius)
		inner.append(shoulder + d * lerpf(radius * 0.93, radius * 0.47, float(i) / 12.0))
	inner.reverse()
	outer.append_array(inner)
	return R.faded(trail[2], R.shape(R.path(outer), R.hex(p.energy.lightened(0.25)), 0.0))


# pose: bob, sway, crouch, torso (grados), head (grados), near_foot, far_foot, near_deg, far_deg,
#       gun_sh, gun_el (brazo-arma), fist_sh, fist_el, charge, flash, trail, fist_trail, thrust, ground_ring, fist_front, fist_flash, dim, dead, no_shadow

static func robot(D, skin: String, pose: Dictionary = {}, k: float = 1.0) -> Image:
	var r = canvas(D, skin)
	r.add(robot_svg(D, skin, pose))
	return r.render_scaled(k)


static func robot_svg(D, skin: String, pose: Dictionary) -> String:
	var p: Dictionary = _adjusted_palette(D.SKINS[skin], pose)
	var flash_y: float = D.get_script_constant_map().get("FLASH_Y", 80.0)
	var out := ""
	var hip := Vector2(150.0 + float(pose.get("sway", 0.0)), D.HIP_Y + float(pose.get("bob", 0.0)) + float(pose.get("crouch", 0.0)))
	var waist := hip + Vector2(0, -8)
	var tilt: float = pose.get("torso", 0.0)

	if not pose.get("no_shadow", false):
		out += R.ellipse(150, 224, D.SHADOW_W, 7, "#000000", 0.3)

	# Alas o piezas de la espalda: detrás de todo.
	out += R.joint(waist, tilt, D.back(skin, p))
	# Pierna de detrás (más oscura), pierna de delante y la pelvis ENCIMA,
	# para que el arranque de los muslos quede oculto al moverse.
	if pose.has("thrust"):
		out += _foot_flames(p, [pose.get("far_foot", D.FAR_FOOT), pose.get("near_foot", D.NEAR_FOOT)], pose.thrust)
	out += _leg(D, skin, _far_palette(p), hip + Vector2(D.HIP_HALF, 2), pose.get("far_foot", D.FAR_FOOT), pose.get("far_deg", 0.0))
	out += _leg(D, skin, p, hip + Vector2(-D.HIP_HALF, 2), pose.get("near_foot", D.NEAR_FOOT), pose.get("near_deg", 0.0))
	out += R.joint(hip, 0.0, D.pelvis(skin, p))

	var sh_r: Vector2 = waist + Vector2(D.SHOULDER_X, D.SHOULDER_Y).rotated(deg_to_rad(tilt))
	var sh_l: Vector2 = waist + Vector2(-D.SHOULDER_X, D.SHOULDER_Y).rotated(deg_to_rad(tilt))

	# Brazo libre
	var fist_flash: String = _muzzle_flash(p, pose.get("fist_flash", 0.0), flash_y)
	var fist: String = D.upper_arm(p) + R.joint(Vector2(0, 28), pose.get("fist_el", 8.0), fist_flash + D.fist_arm(skin, p))
	var fist_in_front: bool = pose.get("fist_front", false)
	if not fist_in_front:
		out += R.joint(sh_l, pose.get("fist_sh", 8.0), fist)

	# Torso y cabeza
	var head: String = R.joint(D.NECK, pose.get("head", 0.0), D.head(skin, p))
	var neck := R.cel(R.v([-9,-82, 9,-82, 10,-70, -10,-70]), p.dark, p.dark_s, 2.4)
	out += R.joint(waist, tilt, neck + D.torso(skin, p) + head)
	if fist_in_front:
		out += R.joint(sh_l, pose.get("fist_sh", 8.0), fist)
	out += R.joint(sh_l, 0.0, D.shoulder(skin, p, -1.0))

	# Estela del golpe: se dibuja detrás del brazo y sigue su recorrido.
	if pose.has("trail"):
		out += _swing_trail(p, sh_r, pose.trail)
	if pose.has("fist_trail"):
		out += _swing_trail(p, sh_l, pose.fist_trail)

	# Brazo-arma: encima de todo para que se lea al disparar
	var gun_fore: String = R.joint(Vector2(0, 28), pose.get("gun_el", -14.0),
		_muzzle_flash(p, pose.get("flash", 0.0), flash_y) + D.gun(skin, p, pose.get("charge", 0.0)))
	out += R.joint(sh_r, pose.get("gun_sh", -14.0), D.upper_arm(p) + gun_fore)
	out += R.joint(sh_r, 0.0, D.shoulder(skin, p, 1.0))
	if pose.has("ground_ring"):
		out += _ground_ring(p, pose.ground_ring)
	return out


## Propulsores bajo los pies para los que vuelan. t: fuerza de 0 a 1.
static func _foot_flames(p: Dictionary, feet: Array, t: float) -> String:
	var out := ""
	for f in feet:
		var a: Vector2 = f + Vector2(4, 16)
		var l: float = 16.0 + 22.0 * t
		out += R.circle(a.x, a.y + 6.0, 10.0 + 6.0 * t, "url(#e_glow)", 0.0, 0.6)
		out += R.shape(R.path(R.v([a.x - 7.0, a.y, a.x, a.y + l, a.x + 7.0, a.y])), R.hex(p.energy), 0.0)
		out += R.shape(R.path(R.v([a.x - 3.5, a.y, a.x, a.y + l * 0.6, a.x + 3.5, a.y])), "#ffffff", 0.0)
	return out


## Onda de choque en el suelo delante del personaje. t de 0 a 1: crece y se apaga.
static func _ground_ring(p: Dictionary, t: float) -> String:
	var pts := PackedVector2Array()
	var rx: float = 30.0 + 70.0 * t
	for i in 25:
		var ang: float = float(i) / 24.0 * TAU
		pts.append(Vector2(214.0 + cos(ang) * rx, 222.0 + sin(ang) * rx * 0.22))
	var dust := R.ellipse(214.0, 220.0, rx * 0.8, rx * 0.16, R.hex(Color("8f8a7e")), 0.35 * (1.0 - t))
	return dust + R.faded(1.0 - t, R.accent(pts, p.energy.lightened(0.2), 4.0))


## Explosión (t de 0 a 1): bola de fuego que crece y se deshace en humo.
static func explosion(c: Vector2, t: float) -> String:
	if t <= 0.0 or t >= 1.0:
		return ""
	var grow: float = sin(minf(t * 1.6, 1.0) * PI * 0.5)
	var fade: float = 1.0 - smooth((t - 0.45) / 0.55)
	var r: float = 20.0 + 46.0 * grow
	var e := R.circle(c.x, c.y, r * 1.25, "#5a5a60", 0.0, 0.35 * fade)
	e += R.circle(c.x, c.y, r, "#e8452c", 0.0, 0.85 * fade)
	e += R.circle(c.x - r * 0.1, c.y - r * 0.08, r * 0.74, "#ff9a2e", 0.0, 0.9 * fade)
	e += R.circle(c.x - r * 0.15, c.y - r * 0.12, r * 0.45, "#ffe27a", 0.0, fade)
	e += R.circle(c.x - r * 0.18, c.y - r * 0.15, r * 0.2, "#ffffff", 0.0, fade * (1.0 - t))
	return e


## Insignia autobot, para pecho, hombros y puertas.
static func autobot_insignia(c: Vector2, k: float, col: Color) -> String:
	var pts := R.v([-8,-9, -3,-6, 3,-6, 8,-9, 8,1, 5,8, 0,10, -5,8, -8,1])
	var out := PackedVector2Array()
	for q in pts:
		out.append(c + q * k)
	return R.shape(R.path(out), R.hex(col), 1.4)


## Cristal con reflejo (pts: cuatro esquinas). Requiere p.glass en la paleta.
static func window(pts: PackedVector2Array, p: Dictionary) -> String:
	var shine := PackedVector2Array()
	var c: Vector2 = (pts[0] + pts[2]) * 0.5
	for q in pts:
		shine.append(c + (q - c) * Vector2(0.28, 0.82) + Vector2(-5, 0))
	return R.cel(pts, p.glass, p.glass.darkened(0.3), 2.2) + R.flat(R.path(shine), "#ffffff", 0.45)


## Rueda: tread (0 a 1) la hace girar con el vehículo en marcha.
static func wheel(x: float, y: float, tread: float, hub: Color, radius: float = 18.0) -> String:
	var w := R.circle(x, y, radius, "#20232a", 2.8)
	w += R.circle(x, y, radius * 0.53, R.hex(hub), 2.0)
	for i in 5:
		var ang: float = float(i) * TAU / 5.0 + tread * TAU
		w += R.circle(x + cos(ang) * radius * 0.3, y + sin(ang) * radius * 0.3, 1.5, "#3a3e47")
	return w


## Rayos de energía de la transformación, alrededor de un centro.
static func energy_arcs(r, p: Dictionary, center: Vector2, t: float) -> void:
	var bolt: float = sin(clampf(t, 0.0, 1.0) * PI)
	if bolt <= 0.05:
		return
	r.add(R.circle(center.x, center.y, 95.0, "url(#e_glow)", 0.0, bolt * 0.32))
	for i in 6:
		var ang: float = float(i) * TAU / 6.0 + t * 7.0
		var pts := R.v([center.x + cos(ang) * 30.0, center.y + sin(ang) * 24.0,
			center.x + cos(ang + 0.3) * 58.0, center.y + sin(ang + 0.3) * 40.0,
			center.x + cos(ang + 0.1) * 82.0, center.y + sin(ang + 0.1) * 58.0])
		r.add(R.faded(bolt, R.accent(pts, p.energy.lightened(0.4), 2.2)))


## Vehículo de ruedas. q trae las piezas {low, top, wheels} y, opcional, over (por delante
## de las ruedas: la horquilla de una moto).
## o: center_x y shadow_w (sombra), front (punto de impacto de la embestida).
static func ground_vehicle(D, skin: String, pose: Dictionary, k: float, q: Dictionary, o: Dictionary) -> Image:
	var r = canvas(D, skin)
	var p: Dictionary = D.SKINS[skin]
	var bob: float = pose.get("bob", 0.0)
	# Su golpe es una embestida: va hacia delante, no atrás.
	var lunge: float = pose.get("recoil", 0.0)
	r.add(R.ellipse(o.center_x + lunge, 224, o.shadow_w, 6, "#000000", 0.3))
	if pose.has("lines"):
		var t: float = pose.lines
		for i in 4:
			var y: float = 110.0 + i * 26.0
			var x: float = -46.0 + fposmod(t * 40.0 + i * 13.0, 40.0)
			r.add(R.faded(0.32, R.accent(R.v([x, y, x + 46.0, y]), Color.WHITE, 2.0)))
	r.add(R.joint(Vector2(lunge, bob), 0.0, q.top + q.low))
	r.add(R.joint(Vector2(lunge, 0), 0.0, q.wheels))
	r.add(R.joint(Vector2(lunge, bob), 0.0, q.get("over", "")))
	var flash: float = pose.get("flash", 0.0)
	if flash > 0.01:
		var f: Vector2 = o.front + Vector2(lunge, 0)
		r.add(R.circle(f.x, f.y, 46.0 * flash, "url(#e_glow)", 0.0, 1.0))
		r.add(R.faded(flash, R.accent(R.v([f.x, f.y - 36.0, f.x + 14.0, f.y, f.x, f.y + 36.0]), p.energy.lightened(0.3), 4.0)))
	return r.render_scaled(k)


## Robot → vehículo de ruedas (t de 0 a 1): se agacha y se tumba hacia delante, las ruedas
## y la parte baja aparecen debajo y la parte alta se cierra por encima.
## o: center_x, shadow_w, crouch, pivot_y (giro del robot), base_y (ruedas), top_y.
static func fold_into_vehicle(D, skin: String, t: float, k: float, q: Dictionary, o: Dictionary) -> Image:
	var p: Dictionary = D.SKINS[skin]
	var r = canvas(D, skin)
	var fold: float = smooth(t / 0.55)
	var base: float = smooth((t - 0.25) / 0.4)
	var top: float = smooth((t - 0.45) / 0.45)
	r.add(R.ellipse(lerpf(150.0, o.center_x, base), 224, lerpf(D.SHADOW_W, o.shadow_w, base), lerpf(7.0, 6.0, base), "#000000", 0.3))
	if base > 0.0:
		r.add(R.scaled(Vector2(o.center_x, o.base_y), lerpf(0.5, 1.0, base), base, q.wheels))
	var robot_op: float = 1.0 - smooth((t - 0.58) / 0.22)
	if robot_op > 0.0:
		var figure: String = robot_svg(D, skin, {
			"no_shadow": true,
			"crouch": fold * float(o.crouch),
			"near_foot": D.NEAR_FOOT.lerp(Vector2(140, 212), fold),
			"far_foot": D.FAR_FOOT.lerp(Vector2(160, 212), fold),
			"gun_sh": lerpf(-16.0, -6.0, fold),
			"gun_el": lerpf(-12.0, -2.0, fold),
			"fist_sh": lerpf(8.0, 3.0, fold),
			"fist_el": lerpf(8.0, 2.0, fold),
			"head": fold * -30.0,
			"charge": 0.2,
		})
		var rot: String = R.rotated(Vector2(150, o.pivot_y), fold * 66.0, figure)
		r.add(R.faded(robot_op, R.joint(Vector2(fold * 30.0, 0), 0.0, rot)))
	if base > 0.0:
		r.add(R.faded(smooth(base * 2.0), R.scaled(Vector2(o.center_x, o.base_y - 16.0), lerpf(0.6, 1.0, base), base, q.low)))
	if top > 0.0:
		r.add(R.joint(Vector2(0, (1.0 - top) * -22.0), 0.0, R.faded(smooth(top * 2.0), R.scaled(Vector2(o.center_x - 10.0, o.top_y), lerpf(0.7, 1.0, top), top, q.top))))
		r.add(R.faded(smooth(top * 2.0), q.wheels + q.get("over", "")))
	energy_arcs(r, p, Vector2(170, 150), t)
	return r.render_scaled(k)


static func smooth(t: float) -> float:
	t = clampf(t, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)
