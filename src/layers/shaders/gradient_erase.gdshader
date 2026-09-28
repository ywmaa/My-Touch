shader_type canvas_item;
render_mode blend_sub;

#include "res://src/layers/shaders/gradient_fill.gdshaderinc"

void fragment() {
	// Erase strength comes from the colors' alpha. blend_sub removes alpha * alpha,
	// so output sqrt to remove exactly the requested amount, and keep rgb untouched.
	COLOR = vec4(0.0, 0.0, 0.0, sqrt(gradient_color().a));
}
