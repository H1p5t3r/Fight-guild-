shader_type canvas_item;
render_mode unshaded;

uniform bool silhouette = false;
uniform vec4 ink : source_color = vec4(0.035, 0.035, 0.047, 1.0);
uniform vec4 accent : source_color = vec4(0.839, 0.459, 0.439, 1.0);
uniform vec4 paper : source_color = vec4(1.0, 0.969, 0.914, 1.0);
varying vec4 tint;

void vertex() {
    tint = COLOR;
}

void fragment() {
    vec4 source = texture(TEXTURE, UV);
    float light = dot(source.rgb, vec3(0.299, 0.587, 0.114));
    vec3 print_color = mix(ink.rgb, accent.rgb, smoothstep(0.25, 0.29, light));
    print_color = mix(print_color, paper.rgb, smoothstep(0.56, 0.60, light));
    COLOR = vec4(silhouette ? ink.rgb : print_color, source.a) * tint;
}
