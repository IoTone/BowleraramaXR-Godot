// Neon wireframe grid floor. World-space lines so the grid stays stable as it
// scrolls toward the horizon. Emission drives the WorldEnvironment glow.
shader_type spatial;
render_mode unshaded, cull_disabled;

uniform vec3 grid_color : source_color = vec3(1.0, 0.15, 0.9);
uniform vec3 floor_color : source_color = vec3(0.02, 0.0, 0.06);
uniform float cell = 1.0;            // metres per cell
uniform float line_width = 1.4;      // line thickness in pixels
uniform float scroll_speed = 1.2;    // cells per second toward viewer
uniform float emission_strength = 3.0;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

// Anti-aliased grid mask: 1.0 on a line, 0.0 in the cell interior.
float grid_mask(vec2 p) {
	vec2 g = abs(fract(p - 0.5) - 0.5) / fwidth(p);
	float line = min(g.x, g.y) / line_width;
	return 1.0 - min(line, 1.0);
}

void fragment() {
	vec2 p = world_pos.xz / cell;
	p.y += TIME * scroll_speed;
	float m = grid_mask(p);
	ALBEDO = mix(floor_color, grid_color, m);
	EMISSION = grid_color * m * emission_strength;
}
