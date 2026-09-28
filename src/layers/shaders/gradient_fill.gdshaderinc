// Shared by gradient_fill.gdshader (draw) and gradient_erase.gdshader (erase).
// Points are in the layer's local space (canvas pixels).
uniform vec2 start_point;
uniform vec2 end_point;
uniform vec4 start_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 end_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform int shape = 0; // 0 linear, 1 radial, 2 reflected

varying vec2 local_pos;

void vertex() {
	local_pos = VERTEX;
}

float gradient_offset() {
	vec2 dir = end_point - start_point;
	float len_sq = max(dot(dir, dir), 0.000001);
	float t;
	if (shape == 1) {
		t = length(local_pos - start_point) / sqrt(len_sq);
	} else {
		t = dot(local_pos - start_point, dir) / len_sq;
		if (shape == 2) {
			t = abs(t);
		}
	}
	return clamp(t, 0.0, 1.0);
}

vec4 gradient_color() {
	return mix(start_color, end_color, gradient_offset());
}
