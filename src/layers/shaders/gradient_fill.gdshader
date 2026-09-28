shader_type canvas_item;
render_mode blend_mix;

#include "res://src/layers/shaders/gradient_fill.gdshaderinc"

void fragment() {
	COLOR = gradient_color();
}
