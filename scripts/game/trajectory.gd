extends Reference
# Simula il volo di una paperella (gravità e rimbalzi) con le query di fisica.
# Usato dall'anteprima della mira (Test coverage) e dalla CPU.

const BALL_RADIUS := 7.0
const BOUNCE := 0.55
const DT := 1.0 / 60.0


# Restituisce {"points": posizioni globali, "hits": corpi toccati in ordine (senza ripetizioni)}.
# Si ferma dopo `max_bounces` rimbalzi, `max_steps` passi o sotto la y `bottom`.
static func simulate(space: Physics2DDirectSpaceState, from: Vector2, velocity: Vector2,
		max_bounces: int, max_steps: int, bottom: float) -> Dictionary:
	var shape := CircleShape2D.new()
	shape.radius = BALL_RADIUS
	var query := Physics2DShapeQueryParameters.new()
	query.set_shape(shape)
	var gravity := Vector2(0, ProjectSettings.get_setting("physics/2d/default_gravity"))
	var points := PoolVector2Array()
	var hits := []
	var pos := from
	var bounces := 0
	for _step in max_steps:
		velocity += gravity * DT
		var motion := velocity * DT
		query.transform = Transform2D(0.0, pos)
		query.motion = motion
		var cast := space.cast_motion(query)
		if cast.size() == 2 and cast[1] < 1.0:
			pos += motion * cast[0]
			query.transform = Transform2D(0.0, pos + motion * (cast[1] - cast[0]))
			query.motion = Vector2.ZERO
			var info := space.get_rest_info(query)
			if info.empty():
				break
			velocity = velocity.bounce(info.normal) * BOUNCE
			var collider := instance_from_id(info.collider_id)
			if collider and not collider in hits:
				hits.append(collider)
			bounces += 1
			if bounces > max_bounces:
				points.append(pos)
				break
		else:
			pos += motion
		points.append(pos)
		if pos.y > bottom:
			break
	return {"points": points, "hits": hits}
