extends GridMap

@export
var camera: Camera3D
@export
var marker: Node3D
@export
var character_controller : CharacterController


func _physics_process(_delta) -> void:
	var mapPosition = get_mouse_map_position()
	if mapPosition == null:
		return

	# Gridmap position is the center of a cell. So we need to offset by half the cell height
	# We also add 0.01 to our Y coordinate for the marker, so that there are no z-index clash issues with the cell surface
	marker.global_position = to_global(map_to_local(mapPosition)) + Vector3(0, -(cell_size.y / 2) + 0.001, 0)
	
	
func _unhandled_input(event: InputEvent) -> void:
	if (event is not InputEventMouseButton):
		return
	if (!(event as InputEventMouseButton).pressed):
		return
	var mapPosition = get_mouse_map_position()
	
	# The cell position is in the upper left corner. By adding our cell_size / 2 we're getting our coordinate to the center of the square
	character_controller.target_position = to_global(mapPosition)  + (cell_size / 2)
	

func get_mouse_map_position():
	var mouseWorldPos = get_mouse_world_pos()
	if mouseWorldPos == null:
		return null

	var localPosition: Vector3 = to_local(mouseWorldPos)
	var mapPosition: Vector3i  = local_to_map(localPosition)

	if get_cell_item(mapPosition) == INVALID_CELL_ITEM:
		# This escape clause handles when our ray collides with the side of a cube. This will generally be from a square that's empty, colliding with the side of a wall.
		return null

	# Add 1 vertical square to our mapPosition.
	# This is because the raycast is colliding with the floor, which is technically one level lower than the square we're interested in.
	mapPosition += Vector3i(0, 1, 0)
	return mapPosition

func get_mouse_world_pos():
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var mousePos: Vector2                = get_viewport().get_mouse_position()

	var origin: Vector3                    = camera.project_ray_origin(mousePos)
	var end: Vector3                       = origin + (camera.project_ray_normal(mousePos) * 5000)
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(origin, end)
	query.collision_mask = 1
	# TODO configure a gridmap=only collision mask, so that we can easily select tiles even when they have other things in them!

	var result: Dictionary = space.intersect_ray(query)
	if result.is_empty():
		return null

	if result.collider != self:
		return null
		
	return result.position
