extends Reference
# Carica un livello JSON ed espande i pattern in una lista di pioli.
#
# Formato: { "name", "balls", "targets", "pegs": [ <elemento>, ... ] }
# Ogni elemento ha "shape" ("round" di default, oppure "rect") e un "pattern":
#   single: "at": [x, y], "rotation": gradi
#   line:   "from": [x, y], "to": [x, y], "count"  (i pioli rect seguono la linea)
#   arc:    "center": [x, y], "radius", "start", "end" (gradi, 0 = destra, 90 = giù), "count"
#   grid:   "rect": [x, y, w, h], "rows", "cols", "staggered": bool


static func load_level(path: String) -> Dictionary:
	var file := File.new()
	if file.open(path, File.READ) != OK:
		push_error("Livello non trovato: %s" % path)
		return {}
	var parsed := JSON.parse(file.get_as_text())
	file.close()
	if parsed.error != OK:
		push_error("%s:%d %s" % [path, parsed.error_line, parsed.error_string])
		return {}
	var data: Dictionary = parsed.result
	var pegs := []
	for item in data.get("pegs", []):
		pegs += _expand(item)
	return {
		"name": data.get("name", ""),
		"balls": int(data.get("balls", 10)),
		"targets": int(data.get("targets", 10)),
		"pegs": pegs,
	}


static func _expand(item: Dictionary) -> Array:
	var shape: String = item.get("shape", "round")
	var pattern: String = item.get("pattern", "single")
	var out := []
	match pattern:
		"single":
			out.append(_peg(shape, _vec(item["at"]), deg2rad(item.get("rotation", 0.0))))
		"line":
			var from := _vec(item["from"])
			var to := _vec(item["to"])
			var count := int(item["count"])
			for i in count:
				var t: float = 0.5 if count == 1 else float(i) / (count - 1)
				out.append(_peg(shape, from.linear_interpolate(to, t), (to - from).angle()))
		"arc":
			var center := _vec(item["center"])
			var radius := float(item["radius"])
			var start := deg2rad(item["start"])
			var end := deg2rad(item["end"])
			var count := int(item["count"])
			for i in count:
				var t: float = 0.5 if count == 1 else float(i) / (count - 1)
				var angle: float = lerp(start, end, t)
				out.append(_peg(shape, center + Vector2(cos(angle), sin(angle)) * radius, angle + PI / 2.0))
		"grid":
			var rect := Rect2(item["rect"][0], item["rect"][1], item["rect"][2], item["rect"][3])
			var rows := int(item["rows"])
			var cols := int(item["cols"])
			var staggered: bool = item.get("staggered", false)
			var step := Vector2(rect.size.x / max(1, cols - 1), rect.size.y / max(1, rows - 1))
			for r in rows:
				var shifted: bool = staggered and r % 2 == 1
				for c in (cols - 1 if shifted else cols):
					var offset: float = step.x / 2.0 if shifted else 0.0
					out.append(_peg(shape, rect.position + Vector2(c * step.x + offset, r * step.y), 0.0))
		_:
			push_error("Pattern sconosciuto: %s" % pattern)
	return out


static func _peg(shape: String, position: Vector2, rotation: float) -> Dictionary:
	return {"shape": shape, "position": position, "rotation": rotation}


static func _vec(a: Array) -> Vector2:
	return Vector2(a[0], a[1])
