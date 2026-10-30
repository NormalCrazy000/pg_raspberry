extends Reference
# Texture generate da codice (placeholder finché non ci sono asset grafici).


static func make_disc(size: int) -> ImageTexture:
	var img := Image.new()
	img.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size, size) / 2.0
	var r := size / 2.0
	img.lock()
	for y in size:
		for x in size:
			var d := Vector2(x + 0.5, y + 0.5).distance_to(center)
			var alpha: float = clamp(r - d, 0.0, 1.0)
			var shade := 1.0 - 0.35 * (d / r)
			img.set_pixel(x, y, Color(shade, shade, shade, alpha))
	img.unlock()
	return _to_texture(img)


static func make_rounded_rect(size: Vector2, corner: float) -> ImageTexture:
	var w := int(size.x)
	var h := int(size.y)
	var img := Image.new()
	img.create(w, h, false, Image.FORMAT_RGBA8)
	var inner := Rect2(corner, corner, w - corner * 2.0, h - corner * 2.0)
	img.lock()
	for y in h:
		for x in w:
			var p := Vector2(x + 0.5, y + 0.5)
			var nearest := Vector2(clamp(p.x, inner.position.x, inner.end.x), clamp(p.y, inner.position.y, inner.end.y))
			var alpha: float = clamp(corner - p.distance_to(nearest), 0.0, 1.0)
			var shade := 1.0 - 0.3 * abs(p.y - h / 2.0) / (h / 2.0)
			img.set_pixel(x, y, Color(shade, shade, shade, alpha))
	img.unlock()
	return _to_texture(img)


static func _to_texture(img: Image) -> ImageTexture:
	var tex := ImageTexture.new()
	tex.create_from_image(img, Texture.FLAG_FILTER)
	return tex
