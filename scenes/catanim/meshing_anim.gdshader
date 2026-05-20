shader_type spatial;

uniform float repeat = 30.0;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	ALBEDO = vec3(1.0, 0.0, 0.0);
	ALPHA = step(fract(UV.y * repeat), 0.5);
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
