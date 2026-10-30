shader_type canvas_item;
uniform vec4 tint: source_color;

void fragment() {
	COLOR = tint * COLOR;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
