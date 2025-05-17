shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, specular_schlick_ggx;

uniform sampler2D albedo_texture : source_color;
uniform vec3 original_color1 : source_color = vec3(1.0, 0.0, 0.0);
uniform vec3 target_color1 : source_color = vec3(0.0, 1.0, 0.0);
uniform vec3 original_color2 : source_color = vec3(0.0, 0.0, 1.0);
uniform vec3 target_color2 : source_color = vec3(1.0, 1.0, 0.0);
uniform vec3 original_color3 : source_color = vec3(0.0, 0.0, 1.0);
uniform vec3 target_color3 : source_color = vec3(1.0, 1.0, 0.0);
uniform vec3 original_color4 : source_color = vec3(0.0, 0.0, 1.0);
uniform vec3 target_color4 : source_color = vec3(1.0, 1.0, 0.0);
uniform float color_threshold : hint_range(0.01, 0.3) = 0.05;

void fragment() {
    // Get the texture color
    vec4 tex_color = texture(albedo_texture, UV);
    
    // We'll use this for our final color
    vec4 final_color = tex_color;
    
    // Check distances
    float dist1 = distance(tex_color.rgb, original_color1);
    float dist2 = distance(tex_color.rgb, original_color2);
	float dist3 = distance(tex_color.rgb, original_color3);
	float dist4 = distance(tex_color.rgb, original_color4);
    
    // Replace colors based on threshold
    if (dist1 < color_threshold) {
        final_color.rgb = target_color1;
    } else if (dist2 < color_threshold) {
        final_color.rgb = target_color2;
    } else if (dist3 < color_threshold) {
		final_color.rgb = target_color3;
	} else if (dist4 < color_threshold) {
		final_color.rgb = target_color4;
    }
    // Apply the color
    ALBEDO = final_color.rgb;
}