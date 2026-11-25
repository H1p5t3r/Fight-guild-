shader_type canvas_item;
render_mode unshaded;

// BackBufferCopy supplies this frame's arena before the cut-in, never feedback.
// No TIME: seeking a saved presentation tick produces the same tear.
uniform sampler2D frozen_scene : hint_screen_texture, filter_linear, repeat_disable;
uniform sampler2D face_atlas : source_color, filter_linear, repeat_disable;
uniform vec4 face_region = vec4(0.0, 0.0, 1.0, 1.0);
uniform vec4 face_box = vec4(0.16, 0.0, 0.68, 1.0);
uniform vec4 guild : source_color = vec4(0.863, 0.078, 0.235, 1.0);
uniform vec4 ink : source_color = vec4(0.031, 0.035, 0.051, 1.0);
uniform vec4 paper : source_color = vec4(1.0, 0.969, 0.910, 1.0);
uniform vec2 panel_pixels = vec2(1280.0, 720.0);
uniform float tear_open = 0.0;
uniform float knit_close = 0.0;
uniform float opacity = 1.0;
uniform float direction = 1.0;
uniform bool reduced_motion = false;

float hash(float n) {
	return fract(sin(n * 127.1 + 13.7) * 43758.5453);
}

float fiber_noise(float x, float frequency) {
	float cell = floor(x * frequency);
	return mix(hash(cell), hash(cell + 1.0), fract(x * frequency)) - 0.5;
}

vec3 portrait_at(vec2 point) {
	// Fixed artwork coordinates: the opening reveals rather than squashes a face.
	vec2 face_uv = (point - face_box.xy) / face_box.zw;
	float inside = step(0.0, face_uv.x) * step(face_uv.x, 1.0)
		* step(0.0, face_uv.y) * step(face_uv.y, 1.0);
	vec2 texel = 0.5 / vec2(textureSize(face_atlas, 0));
	vec2 sample_uv = clamp(face_region.xy + face_uv * face_region.zw,
		face_region.xy + texel, face_region.xy + face_region.zw - texel);
	vec4 face = texture(face_atlas, sample_uv);
	float streak = step(0.87, hash(floor((point.y + point.x * 0.12) * 130.0)))
		* (1.0 - smoothstep(0.02, 0.24, min(point.x, 1.0 - point.x)));
	vec3 field = mix(guild.rgb, ink.rgb, streak * 0.48);
	return mix(field, face.rgb, face.a * inside);
}

void fragment() {
	vec2 point = vec2(direction < 0.0 ? 1.0 - UV.x : UV.x, UV.y);
	float x = point.x;
	float pixel = 1.0 / panel_pixels.y;
	float grain = fiber_noise(x, 73.0) * 0.009 + fiber_noise(x, 211.0) * 0.003;
	float seam = 0.565 - x * 0.13 + fiber_noise(x, 19.0) * 0.019 + grain;
	float spread = 0.162 + 0.012 * sin(x * 3.141593);
	float opened = smoothstep(x * 0.57, x * 0.57 + 0.43, tear_open);
	float joined = smoothstep(x * 0.72, x * 0.72 + 0.28, knit_close);
	float peel = opened * (1.0 - joined);
	if (reduced_motion) { peel = 1.0; }
	float gap = spread * peel;
	float top = seam - gap;
	float bottom = seam + gap;
	float outside = abs(point.y - seam) - gap;
	vec2 source_uv = UV;

	// Pin the outer screen edges. Pixels near the rip bow away with their
	// frozen fighter/stage artwork attached to the two pieces of screen.
	if (!reduced_motion && gap > 0.0) {
		if (point.y < top) {
			float bend = clamp(point.y / max(top, 0.01), 0.0, 1.0);
			source_uv.y += gap * bend * bend;
		} else if (point.y > bottom) {
			float bend = clamp((1.0 - point.y) / max(1.0 - bottom, 0.01), 0.0, 1.0);
			source_uv.y -= gap * bend * bend;
		}
	}
	// Infer the actual arena rectangle in any nested layout or viewport scale.
	// Only the face/tear direction mirrors; the stage itself always stays upright.
	vec2 span = vec2(dFdx(SCREEN_UV.x) / max(dFdx(UV.x), 0.000001),
		dFdy(SCREEN_UV.y) / max(dFdy(UV.y), 0.000001));
	vec2 screen_origin = SCREEN_UV - UV * span;
	vec2 screen_sample = clamp(screen_origin + source_uv * span,
		screen_origin + SCREEN_PIXEL_SIZE * 0.5,
		screen_origin + span - SCREEN_PIXEL_SIZE * 0.5);
	vec4 untouched = texture(frozen_scene, SCREEN_UV);
	vec3 surface = texture(frozen_scene, screen_sample).rgb;
	float weight = reduced_motion ? 1.0 : peel;
	surface *= 1.0 - 0.22 * weight;
	vec3 beneath = portrait_at(point);
	float rim_width = pixel * (1.6 + hash(floor(x * 397.0)) * 2.2);
	float depth = 1.0 - smoothstep(0.0, 12.0 * pixel, -outside);
	beneath = mix(beneath, ink.rgb, depth * 0.72);
	vec3 composite = mix(surface, beneath, 1.0 - smoothstep(-pixel, pixel, outside));
	// Uneven white fibers, a folded lip and a deep inner shadow convey thickness.
	float lip = (1.0 - smoothstep(0.0, 8.0 * pixel, outside)) * step(0.0, outside);
	composite = mix(composite, paper.rgb, lip * weight * 0.30);
	float rim = 1.0 - smoothstep(rim_width, rim_width + pixel, abs(outside));
	composite = mix(composite, paper.rgb, rim * smoothstep(0.0, 2.5 * pixel, gap));

	if (!reduced_motion) {
		// Staggered fibers reach from both lips as the rejoin front passes. They
		// meet across the remaining gap, then disappear into the sealed image.
		float cell = floor(x * 67.0);
		float along = clamp((point.y - top) / max(2.0 * gap, pixel), 0.0, 1.0);
		float strand_x = 0.5 + sin(along * 6.283185 + hash(cell) * 5.0) * 0.18;
		float strand = 1.0 - smoothstep(0.035, 0.080, abs(fract(x * 67.0) - strand_x));
		float reach = smoothstep(0.02, 0.65, joined) * 0.58;
		float tips = max(1.0 - step(reach, along), step(1.0 - reach, along));
		float knitting = smoothstep(0.03, 0.23, joined) * (1.0 - smoothstep(0.82, 1.0, joined));
		float fiber = strand * tips * knitting * step(0.20, hash(cell + 87.0))
			* (1.0 - step(0.0, outside)) * smoothstep(0.0, pixel * 5.0, gap);
		composite = mix(composite, paper.rgb, fiber * 0.9);
	}
	// Closed columns are the unmodified original pixels, including the last frame.
	float coverage = reduced_motion ? opacity : smoothstep(0.0, pixel, gap);
	COLOR = vec4(mix(untouched.rgb, composite, coverage), untouched.a);
}
