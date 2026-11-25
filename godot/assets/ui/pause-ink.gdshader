shader_type canvas_item;
render_mode unshaded;
uniform float opacity = 1.0;
varying float source_alpha;
void vertex() { source_alpha = COLOR.a; }
void fragment() {
    COLOR = vec4(0.018, 0.018, 0.024, texture(TEXTURE, UV).a * opacity * source_alpha);
}
