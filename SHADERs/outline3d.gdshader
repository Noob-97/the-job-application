shader_type spatial;
render_mode blend_mix, cull_front, unshaded;

uniform vec4 line_color : source_color = vec4(1,0,0,1);
uniform float size : hint_range(1.0, 1.5, 0.01) = 1.05;

void vertex() {
	VERTEX *= size;
}

void fragment() {
	ALBEDO = line_color.rgb;
	ALPHA = line_color.a;
}