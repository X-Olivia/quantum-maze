shader_type canvas_item;

uniform vec4 outline_color = vec4(1.0, 1.0, 0.0, 1.0); // Yellow outline
uniform float outline_thickness = 2.0;

void fragment() {
    vec4 base_color = texture(TEXTURE, UV);
    float threshold = 0.1; // Helps detect edges more clearly
    float alpha = base_color.a;

    // Check surrounding pixels for any color
    alpha += texture(TEXTURE, UV + vec2(outline_thickness * TEXTURE_PIXEL_SIZE.x, 0.0)).a;
    alpha += texture(TEXTURE, UV - vec2(outline_thickness * TEXTURE_PIXEL_SIZE.x, 0.0)).a;
    alpha += texture(TEXTURE, UV + vec2(0.0, outline_thickness * TEXTURE_PIXEL_SIZE.y)).a;
    alpha += texture(TEXTURE, UV - vec2(0.0, outline_thickness * TEXTURE_PIXEL_SIZE.y)).a;

    // If this pixel is transparent but near a non-transparent pixel, draw outline
    if (base_color.a < threshold && alpha > threshold) {
        COLOR = outline_color;
    } else {
        COLOR = base_color;
    }
}
