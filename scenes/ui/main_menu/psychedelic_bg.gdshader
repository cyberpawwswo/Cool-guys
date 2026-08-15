shader_type canvas_item;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x),
		u.y
	);
}

void fragment() {
	float time = TIME;
	vec2 uv = UV;

	float n1 = noise(uv * 4.0 + vec2(time * 0.15, -time * 0.1));
	float n2 = noise(uv * 6.0 - vec2(time * 0.1, time * 0.2));
	float fog = n1 * n2;

	float veins = noise(uv * 9.0 + vec2(time * 0.08, time * 0.15) + n1 * 2.0);

	float pulse = 0.5 + 0.5 * sin(time * 0.6);
	pulse *= 0.5 + 0.5 * sin(time * 0.23 + 1.7);

	vec3 paper = vec3(0.93);
	vec3 ink = vec3(0.05);
	float coverage = 0.15 + fog * 0.5;
	coverage += veins * 0.35 * (0.6 + pulse * 0.8);
	vec3 col = mix(paper, ink, coverage);

	col *= 0.85 + pulse * 0.3;

	float vig = smoothstep(1.1, 0.2, length(uv - 0.5) * 1.8);
	col *= mix(0.55, 1.0, vig);

	float grain = hash(uv * 500.0 + 0.37);
	col = mix(col, col * (0.92 + grain * 0.16), 0.3);

	COLOR = vec4(col, 1.0);
}
