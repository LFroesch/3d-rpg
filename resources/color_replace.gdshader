shader_type spatial;

uniform vec4 original_color : source_color = vec4(0.5, 0.5, 0.5, 1.0); // The grey color
uniform vec4 replacement_color : source_color = vec4(0.0, 0.5, 0.0, 1.0); // Green
uniform float color_tolerance : hint_range(0.0, 1.0) = 0.1; // How much variation in grey to accept
uniform sampler2D albedo_texture : source_color;

void fragment() {
    vec4 texture_color = texture(albedo_texture, UV);
    
    // Calculate color difference
    float color_difference = distance(texture_color.rgb, original_color.rgb);
    
    // If the color is close to the original color (grey), replace it
    if (color_difference < color_tolerance) {
        // Mix between original and replacement color based on how close it is
        float blend_factor = 1.0 - (color_difference / color_tolerance);
        ALBEDO = mix(texture_color.rgb, replacement_color.rgb, blend_factor);
    } else {
        // Keep original color for non-grey parts (like the red plume)
        ALBEDO = texture_color.rgb;
    }
}