// Synthwave sky: vertical gradient + scanline sun sitting on the horizon.
shader_type sky;

uniform vec3 zenith_color : source_color = vec3(0.02, 0.0, 0.12);
uniform vec3 horizon_color : source_color = vec3(0.55, 0.02, 0.45);
uniform vec3 ground_color : source_color = vec3(0.01, 0.0, 0.04);
uniform vec3 sun_top : source_color = vec3(1.0, 0.85, 0.2);
uniform vec3 sun_bottom : source_color = vec3(1.0, 0.1, 0.45);
uniform vec3 sun_dir = vec3(0.0, 0.12, -1.0);
uniform float sun_radius = 0.35;
uniform float band_freq = 60.0;

void sky() {
	vec3 dir = normalize(EYEDIR);

	// Sky gradient (above horizon) and ground fade (below).
	vec3 base;
	if (dir.y >= 0.0) {
		base = mix(horizon_color, zenith_color, pow(clamp(dir.y, 0.0, 1.0), 0.45));
	} else {
		base = mix(horizon_color, ground_color, clamp(-dir.y * 3.0, 0.0, 1.0));
	}

	// Sun disc.
	vec3 sd = normalize(sun_dir);
	float d = distance(dir, sd);
	float disc = smoothstep(sun_radius, sun_radius * 0.92, d);

	// Vertical gradient across the sun.
	float t = clamp((dir.y - (sd.y - sun_radius)) / (2.0 * sun_radius), 0.0, 1.0);
	vec3 sun_col = mix(sun_bottom, sun_top, t);

	// Scanline bands: cut horizontal gaps, denser toward the bottom of the sun.
	float band = step(0.35, fract(dir.y * band_freq));
	float lower = smoothstep(sd.y + sun_radius * 0.4, sd.y - sun_radius, dir.y);
	disc *= mix(1.0, band, lower);

	// Soft halo glow around the sun.
	float halo = smoothstep(sun_radius * 2.6, sun_radius, d) * 0.5;

	vec3 col = mix(base, sun_col, disc);
	col += sun_bottom * halo * (1.0 - disc);
	COLOR = col;
}
