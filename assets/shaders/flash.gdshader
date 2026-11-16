shader_type canvas_item;
// Hit flash: renders the sprite's silhouette in solid white.
void fragment() {
	COLOR = vec4(1.0, 1.0, 1.0, texture(TEXTURE, UV).a);
}
