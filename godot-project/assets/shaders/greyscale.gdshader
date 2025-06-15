shader_type canvas_item;

void fragment() {
    vec4 color = texture(TEXTURE, UV);
    float grey = dot(color.rgb, vec3(0.3, 0.59, 0.11));
    COLOR = vec4(vec3(grey), color.a);
}