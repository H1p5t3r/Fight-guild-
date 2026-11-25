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
uniform float rip_front = -0.12;
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
	float aspect = panel_pixels.x / panel_pixels.y;
	float grain = fiber_noise(x, 73.0) * 0.009 + fiber_noise(x, 211.0) * 0.003;
	float seam = 0.565 - x * 0.13 + fiber_noise(x, 19.0) * 0.019 + grain;
	float spread = 0.162 + 0.012 * sin(x * 3.141593);
	// These two cut edges never separate or change height. A strip is removed
	// from the frozen image; all pixels above/below it keep their original UVs.
	float top = seam - spread;
	float bottom = seam + spread + fiber_noise(x + 0.43, 113.0) * 0.007;
	float band_distance = max(top - point.y, point.y - bottom);
	float along = clamp((point.y - top) / (bottom - top), 0.0, 1.0);
	float ragged_front = (0.5 - along) * 0.045
		+ fiber_noise(along, 23.0) * 0.025 + fiber_noise(along, 79.0) * 0.009;
	float edge_x = (reduced_motion ? 1.12 : rip_front) + ragged_front;
	float front_distance = (point.x - edge_x) * aspect;
	float cut_distance = max(band_distance, front_distance);
	float hole = 1.0 - smoothstep(-pixel, pixel, cut_distance);
	vec4 untouched = texture(frozen_scene, SCREEN_UV);
	vec3 beneath = portrait_at(point);
	float depth = 1.0 - smoothstep(0.0, 12.0 * pixel, -cut_distance);
	beneath = mix(beneath, ink.rgb, depth * 0.72);
	vec3 composite = mix(untouched.rgb, beneath, hole);
	float rim_width = pixel * (1.4 + hash(floor(x * 397.0)) * 2.0);
	float rim = 1.0 - smoothstep(rim_width, rim_width + pixel, abs(cut_distance));
	composite = mix(composite, paper.rgb, rim);

	if (!reduced_motion) {
		// Only the extracted strip curls. Its printed front carries the original
		// match image, then turns over to show paper backing at the rolled lip.
		// The same fold unrolls on the reverse trip as the original pixels return.
		float curl_width = 0.075;
		float curl_u = (edge_x - point.x) / curl_width;
		float curl = step(0.0, curl_u) * (1.0 - step(1.0, curl_u))
			* (1.0 - smoothstep(-pixel, pixel, band_distance));
		float u = clamp(curl_u, 0.0, 1.0);
		vec2 span = vec2(dFdx(SCREEN_UV.x) / max(dFdx(UV.x), 0.000001),
			dFdy(SCREEN_UV.y) / max(dFdy(UV.y), 0.000001));
		vec2 screen_origin = SCREEN_UV - UV * span;
		float printed_x = edge_x + sin(u * 3.141593) * curl_width * 0.65;
		vec2 printed_uv = vec2(direction < 0.0 ? 1.0 - printed_x : printed_x, UV.y);
		vec2 sample_uv = clamp(screen_origin + printed_uv * span,
			screen_origin + SCREEN_PIXEL_SIZE * 0.5,
			screen_origin + span - SCREEN_PIXEL_SIZE * 0.5);
		vec3 printed = texture(frozen_scene, sample_uv).rgb * (1.0 - sin(u * 3.141593) * 0.42);
		vec3 backing = mix(paper.rgb, ink.rgb, 0.10 + pow(1.0 - u, 2.0) * 0.38);
		backing *= 0.96 + fiber_noise(point.y, 239.0) * 0.06;
		vec3 folded = mix(printed, backing, smoothstep(0.40, 0.54, u));
		float curl_shadow = (1.0 - smoothstep(1.0, 1.20, curl_u)) * step(1.0, curl_u) * hole;
		composite = mix(composite, ink.rgb, curl_shadow * 0.45);
		composite = mix(composite, folded, curl);
		// Short horizontal fibers reconnect at the reverse-moving seal, rather
		// than bridging a vertically shrinking gap between two screen halves.
		float row = floor(along * 43.0);
		float stitch = 1.0 - smoothstep(0.035, 0.095,
			abs(fract(along * 43.0 + u * 0.28) - 0.5));
		float fibers = stitch * step(0.32, hash(row + 87.0))
			* smoothstep(0.85, 1.0, curl_u) * (1.0 - smoothstep(1.0, 1.28, curl_u))
			* step(0.001, knit_close) * hole;
		composite = mix(composite, paper.rgb, fibers * 0.85);
	}
	// Every untouched/restored pixel is sampled in place. Reduced Motion fades
	// the stationary cut-out instead of moving the rip or the paper fold.
	COLOR = vec4(mix(untouched.rgb, composite, reduced_motion ? opacity : 1.0), untouched.a);
}
