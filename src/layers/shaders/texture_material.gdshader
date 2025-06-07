shader_type canvas_item;
uniform vec3 texture_color;
void fragment() {
	COLOR = vec4(texture_color, COLOR.a);
}
