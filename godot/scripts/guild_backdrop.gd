extends ColorRect

# Quiet still counterpart of the reference's home gradient. No motion or pointer capture.
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
void fragment() {
    float diagonal = UV.x + UV.y * 0.36;
    float teal = exp(-pow((diagonal - 0.84) / 0.17, 2.0));
    float brass = exp(-pow((diagonal - 1.06) / 0.23, 2.0));
    vec3 base = vec3(0.025, 0.044, 0.058);
    COLOR = vec4(base + teal * vec3(0.07, 0.16, 0.15) + brass * vec3(0.13, 0.12, 0.07), 1.0);
}
"""
	var shader_material := ShaderMaterial.new()
	shader_material.shader = shader
	material = shader_material
