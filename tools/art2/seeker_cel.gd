# seeker_cel.gd
# Seeker en estilo cel: los cazas decepticon que comparten cuerpo con Starscream.
# Como en la serie original, son el mismo molde con otros colores (aquí, el azul de
# Thundercracker), así que reutiliza las piezas de la skin G1 de Starscream.
# Es un enemigo volador: una sola apariencia ("base") y sin transformación.
# OCP/DIP: no copia formas; delega en starscream_cel.gd y solo aporta su paleta.

extends RefCounted

const S := preload("res://tools/art2/starscream_cel.gd")

const SKINS := {
	"base": {"armor": Color("4f82d2"), "armor_s": Color("33599b"), "second": Color("d8dde4"), "second_s": Color("a3acb8"),
		"dark": Color("27396e"), "dark_s": Color("1a274e"), "joint": Color("6a6f79"), "accent": Color("f0b429"),
		"eye": Color("ff3b30"), "energy": Color("ffd36b")},
}

## Molde de Starscream que se reutiliza.
const MOLD := "g1"

const THIGH := S.THIGH
const SHIN := S.SHIN
const HIP_Y := S.HIP_Y
const HIP_HALF := S.HIP_HALF
const SHOULDER_X := S.SHOULDER_X
const SHOULDER_Y := S.SHOULDER_Y
const NECK := S.NECK
const NEAR_FOOT := S.NEAR_FOOT
const FAR_FOOT := S.FAR_FOOT
const SHADOW_W := S.SHADOW_W
const HALF_STRIDE := S.HALF_STRIDE
const LIFT := S.LIFT
const WALK_CENTER := S.WALK_CENTER
const VEHICLE_RECOIL := 0.0
const VEHICLE_HOVER := 0.0


static func back(_skin: String, p: Dictionary) -> String: return S.back(MOLD, p)
static func head(_skin: String, p: Dictionary) -> String: return S.head(MOLD, p)
static func torso(_skin: String, p: Dictionary) -> String: return S.torso(MOLD, p)
static func pelvis(_skin: String, p: Dictionary) -> String: return S.pelvis(MOLD, p)
static func thigh(_skin: String, p: Dictionary) -> String: return S.thigh(MOLD, p)
static func shin(_skin: String, p: Dictionary) -> String: return S.shin(MOLD, p)
static func foot(_skin: String, p: Dictionary) -> String: return S.foot(MOLD, p)
static func shoulder(_skin: String, p: Dictionary, s: float) -> String: return S.shoulder(MOLD, p, s)
static func upper_arm(p: Dictionary) -> String: return S.upper_arm(p)
static func fist_arm(_skin: String, p: Dictionary) -> String: return S.fist_arm(MOLD, p)
static func gun(_skin: String, p: Dictionary, charge: float) -> String: return S.gun(MOLD, p, charge)
