shader_type canvas_item;

void fragment() {
	vec2 uv = UV;
	float time = TIME;

	float fog = (sin(uv.x * 4.0 + time * 0.5) * sin(uv.y * 6.0 - time * 0.4)) * 0.5 + 0.5;
	float veins = (sin(uv.y * 22.0 + time * 1.6 + sin(uv.x * 9.0 + time * 0.9)) * 0.5 + 0.5);

	vec3 col = vec3(0.04, 0.0, 0.01);
	col += vec3(0.45, 0.02, 0.03) * fog * 0.7;
	col += vec3(0.7, 0.04, 0.06) * veins * 0.28;

	float pulse = 0.5 + 0.5 * sin(time * 0.8);
	col += vec3(0.75, 0.02, 0.04) * pulse * 0.18;

	float vig = smoothstep(1.1, 0.2, length(uv - 0.5) * 1.8);
	col *= mix(0.25, 1.0, vig);

	COLOR = vec4(col, 1.0);
}
