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


# Paperella di gomma vista di lato: corpo giallo, becco arancione, occhio.
static func make_duck(size: int) -> ImageTexture:
	var img := Image.new()
	img.create(size, size, false, Image.FORMAT_RGBA8)
	var s := size / 32.0
	var body_center := Vector2(15, 17) * s
	var head_center := Vector2(19, 11) * s
	var beak_center := Vector2(26.5, 12.5) * s
	var eye := Vector2(21, 9.5) * s
	img.lock()
	for y in size:
		for x in size:
			var p := Vector2(x + 0.5, y + 0.5)
			var color := Color(0, 0, 0, 0)
			# corpo: ellisse schiacciata
			var b := (p - body_center) / Vector2(14, 11) / s
			if b.length() <= 1.0:
				color = Color(1.0, 0.82, 0.15)
			if p.distance_to(head_center) <= 7.5 * s:
				color = Color(1.0, 0.86, 0.2)
			var k := (p - beak_center) / Vector2(4.5, 2.5) / s
			if k.length() <= 1.0:
				color = Color(1.0, 0.5, 0.1)
			if p.distance_to(eye) <= 1.6 * s:
				color = Color(0.1, 0.1, 0.1)
			img.set_pixel(x, y, color)
	img.unlock()
	return _to_texture(img)


static func _to_texture(img: Image) -> ImageTexture:
	var tex := ImageTexture.new()
	tex.create_from_image(img, Texture.FLAG_FILTER)
	return tex
