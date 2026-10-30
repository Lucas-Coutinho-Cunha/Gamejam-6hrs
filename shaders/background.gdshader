shader_type canvas_item;
// Background that shifts from a deep evil red to light blue as `progress` goes 0 -> 1.

uniform vec4 hell_top : source_color = vec4(0.55, 0.04, 0.04, 1.0);
uniform vec4 hell_bottom : source_color = vec4(0.18, 0.0, 0.02, 1.0);
uniform vec4 sky_top : source_color = vec4(0.78, 0.93, 1.0, 1.0);
uniform vec4 sky_bottom : source_color = vec4(0.45, 0.75, 0.95, 1.0);
uniform float progress : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	float t = smoothstep(0.0, 1.0, progress);

	vec4 hell = mix(hell_top, hell_bottom, UV.y);
	vec4 sky = mix(sky_top, sky_bottom, UV.y);
	vec4 color = mix(hell, sky, t);

	// Slow, ominous red pulse that fades out as the sky takes over.
	color.r += 0.04 * sin(TIME * 1.5) * (1.0 - t);

	COLOR = color;
}
