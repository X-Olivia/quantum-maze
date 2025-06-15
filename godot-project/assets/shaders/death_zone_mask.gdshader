shader_type canvas_item;

uniform float radius : hint_range(0.0, 1.0) = 1.0;
uniform vec2 center = vec2(0.5, 0.5);

void fragment() {
    // 计算当前像素到中心的距离
    vec2 diff = UV - center;
    float dist = length(diff);
    
    // 如果距离大于radius，则显示背景（透明）
    if (dist > radius) {
        discard;
    }
} 