extends Reference
# Texture generate da codice.


# Alone luminoso morbido (bianco, trasparente ai bordi), da usare con fusione additiva.
static func make_glow(size: int) -> ImageTexture:
	var img := Image.new()
	img.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size, size) / 2.0
	var r := size / 2.0
	img.lock()
	for y in size:
		for x in size:
			var d := Vector2(x + 0.5, y + 0.5).distance_to(center) / r
			var alpha: float = clamp(1.0 - d, 0.0, 1.0)
			img.set_pixel(x, y, Color(1, 1, 1, alpha * alpha))
	img.unlock()
	var tex := ImageTexture.new()
	tex.create_from_image(img, Texture.FLAG_FILTER)
	return tex
