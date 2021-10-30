shader_type canvas_item;

uniform vec2 water_dir = vec2(0,-1);
uniform vec4 wave_color : hint_color = vec4(1,1,1,1);
uniform float cur_line = 0.0;

uniform sampler2D line_tex;

void fragment() {
	vec4 col = texture(TEXTURE, UV);

	float narrowness = 30.0;
	float dist_to_line = 1.0 - narrowness*abs(UV.x - cur_line);
	if(abs(water_dir.x) <= 0.03) { dist_to_line = 1.0 - narrowness*abs(UV.y - cur_line); }
	
	dist_to_line = smoothstep(0.0, 1.0, dist_to_line);
	
	if(dist_to_line > 0.0) {
		vec4 line = texture(line_tex, UV);
	}
	
	vec4 new_col = mix(col, wave_color, dist_to_line);

	COLOR = new_col * col.a;
}