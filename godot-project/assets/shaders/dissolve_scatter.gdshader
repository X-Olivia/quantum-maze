shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform sampler2D noise_texture;
uniform vec2 scatter_direction = vec2(1.0, -0.5);
uniform float scatter_strength = 0.3;
uniform float rotation_strength = 0.1;

void fragment() {
    vec2 noise_uv = UV;
    float noise = texture(noise_texture, noise_uv).r;
    float angle = noise * 6.28318;
    vec2 random_dir = vec2(cos(angle), sin(angle));
    
    vec2 displacement = mix(vec2(0.0), 
                          scatter_direction + random_dir * rotation_strength,
                          progress * noise);
    
    vec4 color = texture(TEXTURE, UV - displacement * scatter_strength * progress);
    
    float dissolve_threshold = progress * 1.2;
    
    if (noise < dissolve_threshold) {
        discard;
    }
    
    float edge_width = 0.05;
    if (noise < dissolve_threshold + edge_width) {
        vec3 edge_color = vec3(1.0, 0.5, 0.0); 
        float edge_intensity = (dissolve_threshold + edge_width - noise) / edge_width;
        color.rgb = mix(color.rgb, edge_color, edge_intensity * 0.6);
    }
    
    color.a *= smoothstep(1.0, 0.0, progress * 1.5);
    
    COLOR = color;
} 