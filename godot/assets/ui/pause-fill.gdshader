shader_type canvas_item;
render_mode unshaded;

uniform vec4 guild : source_color;
uniform vec4 source_tint : source_color = vec4(1.0);
uniform float amount : hint_range(0.0, 1.0) = 1.0;
// 0: unarmed/effect, 1: authored weapon regions, 2: legacy metal fallback,
// 3: detached weapon. Region coordinates are atlas pixels, never screen space.
uniform int weapon_mode = 0;
uniform vec2 atlas_size = vec2(1.0);
uniform vec4 region = vec4(0.0, 0.0, 1.0, 1.0);
uniform vec2 points[96];
uniform int ends[12];
uniform vec4 bounds[12];
uniform int polygon_count = 0;
uniform vec4 protected_head = vec4(0.0);
uniform vec4 protected_body = vec4(0.0);

bool in_rect(vec2 p, vec4 r) {
    return p.x >= r.x && p.y >= r.y && p.x <= r.z && p.y <= r.w;
}

bool neutral_metal(vec4 sample_color) {
    float high = max(sample_color.r, max(sample_color.g, sample_color.b));
    float low = min(sample_color.r, min(sample_color.g, sample_color.b));
    return sample_color.a > 0.6 && high > 0.26 && (high - low) < 0.11;
}

bool weapon_pixel(vec2 p, bool legacy_metal) {
    if (weapon_mode == 3) return true;
    if (weapon_mode == 0) return false;
    if (weapon_mode == 2) {
        // Old flattened sheets have no material matte. Keep the protected body
        // and head colored; only exposed neutral metal is eligible for paper.
        return legacy_metal && !in_rect(p, protected_head) && !in_rect(p, protected_body);
    }
    int start = 0;
    for (int n = 0; n < 12; n++) {
        if (n >= polygon_count) break;
        int end = ends[n];
        if (!in_rect(p, bounds[n])) { start = end; continue; }
        bool inside = false;
        int j = end - 1;
        for (int i = 0; i < 96; i++) {
            if (i < start) continue;
            if (i >= end) break;
            vec2 a = points[i];
            vec2 b = points[j];
            if ((a.y > p.y) != (b.y > p.y)) {
                if (p.x < (b.x - a.x) * (p.y - a.y) / (b.y - a.y) + a.x) inside = !inside;
            }
            j = i;
        }
        if (inside) return true;
        start = end;
    }
    return false;
}

void fragment() {
    vec4 source = texture(TEXTURE, UV);
    if (source.a < 0.001) {
        COLOR = vec4(0.0);
    } else {
        vec2 p = UV * atlas_size - region.xy;
        bool metal = false;
        if (weapon_mode == 2 && neutral_metal(source)) {
            // Reject isolated pale antialiasing pixels around boots/clothing.
            vec2 d = vec2(2.5) / atlas_size;
            int neighbors = int(neutral_metal(texture(TEXTURE, UV + vec2(d.x, 0.0))))
                + int(neutral_metal(texture(TEXTURE, UV - vec2(d.x, 0.0))))
                + int(neutral_metal(texture(TEXTURE, UV + vec2(0.0, d.y))))
                + int(neutral_metal(texture(TEXTURE, UV - vec2(0.0, d.y))));
            metal = neighbors >= 3;
        }
        vec3 fill = weapon_pixel(p, metal) ? vec3(1.0) : guild.rgb;
        COLOR = vec4(mix(source.rgb * source_tint.rgb, fill, amount), source.a * source_tint.a);
    }
}
