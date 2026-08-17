extends Node

## Вырви глаз: радужный СДВГ-оверлей поверх экрана + басс бустед пердящий эффект
## на весь звук (эффекты аудиошины Master: бас-буст EQ + lowpass + понижение тона).

const RAINBOW_LAYER := 1
const OVERLAY_ALPHA := 0.07
const MASTER_GAIN_DB := 12.0
const BASS_BAND_DB: Array[float] = [2.0, 2.0, 1.5, 1.0, 0.5, 0.0, -0.5, -1.0, -1.5, -2.0]

var _overlay_material: ShaderMaterial
var _time := 0.0


func _ready() -> void:
	_setup_rainbow_overlay()
	_setup_fart_audio()


func _process(delta: float) -> void:
	_time += delta
	if _overlay_material:
		_overlay_material.set_shader_parameter("time", _time)


func _setup_rainbow_overlay() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "RainbowLayer"
	canvas.layer = RAINBOW_LAYER
	add_child(canvas)

	var rect := ColorRect.new()
	rect.name = "RainbowOverlay"
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.color = Color(1.0, 1.0, 1.0, OVERLAY_ALPHA)

	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
render_mode blend_add;

uniform float time : hint_range(0.0, 100.0) = 0.0;

vec3 hsv2rgb(vec3 c) {
	vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void fragment() {
	vec2 uv = UV;
	vec3 col = vec3(0.0);

	// 1. Очень слабая общая радужная подложка
	float hue0 = fract(time * 0.04 + uv.x * 0.2 + uv.y * 0.15);
	col += hsv2rgb(vec3(hue0, 1.0, 1.0)) * 0.25;

	// 2. Бегущие диагональные полосы, поочерёдно включаются
	float band_on = step(0.6, 0.5 + 0.5 * sin(time * 0.5));
	float b1 = exp(-abs(fract(uv.x + uv.y - time * 0.35) - 0.5) * 14.0);
	float b2 = exp(-abs(fract(uv.y - uv.x + time * 0.22) - 0.5) * 18.0);
	col += hsv2rgb(vec3(fract(time * 0.07 + 0.33), 1.0, 1.0)) * b1 * 0.35 * band_on;
	col += hsv2rgb(vec3(fract(time * 0.09 + 0.66), 1.0, 1.0)) * b2 * 0.3 * (1.0 - band_on);

	// 3. Блуждающее по экрану мягкое радужное пятно
	vec2 center = vec2(0.5 + 0.35 * sin(time * 0.18), 0.5 + 0.35 * cos(time * 0.23));
	float glow = exp(-distance(uv, center) * 3.5);
	col += hsv2rgb(vec3(fract(time * 0.11), 1.0, 1.0)) * glow * 0.4;

	// 4. Редкие короткие вспышки
	float pulse = step(0.985, fract(time * 0.12)) * step(0.5, sin(time * 90.0));
	col += hsv2rgb(vec3(fract(time * 0.3), 1.0, 1.0)) * pulse * 0.8;

	float vig = 1.0 + 0.2 * pow(distance(uv, vec2(0.5)), 2.0);
	COLOR = vec4(col * vig, 1.0);
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	rect.material = material
	canvas.add_child(rect)
	_overlay_material = material


func _setup_fart_audio() -> void:
	var master := AudioServer.get_bus_index("Master")
	if master < 0:
		return
	# 1. Бас-буст: сильно поднимаем низкие частоты, режем верхи
	var eq := AudioEffectEQ10.new()
	for i in BASS_BAND_DB.size():
		eq.set_band_gain_db(i, BASS_BAND_DB[i])
	AudioServer.add_bus_effect(master, eq)
	# 2. Низкочастотный фильтр — глухой "пердящий" звук
	var low_pass := AudioEffectLowPassFilter.new()
	low_pass.cutoff_hz = 600.0
	low_pass.resonance = 2.0
	AudioServer.add_bus_effect(master, low_pass)
	# 3. Понижение тона — басовитее и "пердящее"
	var pitch := AudioEffectPitchShift.new()
	pitch.pitch_scale = 0.8
	AudioServer.add_bus_effect(master, pitch)
	# 4. Сильное усиление громкости всего звука
	var amplify := AudioEffectAmplify.new()
	amplify.volume_db = MASTER_GAIN_DB
	AudioServer.add_bus_effect(master, amplify)
