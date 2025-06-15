shader_type canvas_item;
uniform vec3 color = vec3(1.0,1.0,1.0);
uniform int OCTAVES = 4;
uniform float speed = 0.5;
uniform float density = 1;
uniform float min_opacity = 0.0;
float rand(vec2 coord){
	return fract(sin(dot(coord, vec2(56,78))*1000.0)*1000.0);
}

float noise(vec2 coord){
	vec2 i = floor(coord);
	vec2 f = fract(coord);

	float a = rand(i);
	float b = rand(i + vec2(1.0,0.0));
	float c = rand(i + vec2(0.0,1.0));
	float d = rand(i + vec2(1.0,1.0));

	vec2 cubic = f*f*(3.0-2.0*f);
	return mix(a,b,cubic.x)+(c-a)*cubic.y*(1.0-cubic.x)+(d-b)*cubic.x*cubic.y;
}

float fbm(vec2 coord){
	float value = 0.0;
	float scale = 0.5;

	for(int i = 0; i < OCTAVES; i++){
		value += noise(coord) * scale;
		coord *= 2.0;
		scale *= 0.5;
	}

	return value;
}

void fragment() {
	vec2 coord = UV * 50.0;

	float noise1 = fbm(coord + vec2(TIME * speed, TIME * speed * 0.5));
	float noise2 = fbm(coord + vec2(-TIME * speed * 0.7, TIME * speed * 0.3) + noise1 * 0.2);

	float final_noise = mix(noise1, noise2, 0.5);

	final_noise = clamp(final_noise * density, min_opacity, 1.0);

	COLOR = vec4(color, final_noise);
}
