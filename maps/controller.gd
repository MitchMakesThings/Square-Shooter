extends GridMap

@export
var camera: Camera3D
@export
var marker: Node3D
@export
var character_controller : CharacterController

var navMap : AStar3D = AStar3D.new()

func _ready():
	calculate_nav()

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
	if mapPosition == null:
		return
	
	var characterLocalPosition: Vector3 = to_local(character_controller.global_position)
	var characterMapPosition: Vector3i = local_to_map(characterLocalPosition)
	
	var targetId: int = navMap.get_closest_point(mapPosition)
	var characterId: int = navMap.get_closest_point(characterMapPosition)
	
	var path: PackedVector3Array = navMap.get_point_path(characterId, targetId)
	if len(path) == 0:
		print('No path')
		return
	
	# The cell position is in the upper left corner. By adding our cell_size / 2 we're getting our coordinate to the center of the square
	# We're excluding the y, as we want our guy to stand on the floor!
	var offset: Vector3 = Vector3(cell_size.x, 0, cell_size.z) / 2
	var world_path: Array[Variant] = []
	for pathPos in path:
		world_path.append(to_global(map_to_local(pathPos)) - Vector3(0, cell_size.y / 2, 0))
	
	character_controller.movement_path = world_path
	

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
	
func calculate_nav():
	var i = 0
	for cell in get_used_cells():
		var cell_above = cell + Vector3i(0, 1, 0)
		if get_cell_item(cell_above) != INVALID_CELL_ITEM:
			continue
		navMap.add_point(i, cell_above)
		i += 1
		
	var surroundingCells: Array[Variant] = [
		Vector3i(-1, 0, 1),
		Vector3i(0, 0, 1),
		Vector3i(1, 0, 1),
		Vector3i(-1, 0, 0),
		Vector3i(1, 0, 0),
		Vector3i(-1, 0, -1),
		Vector3i(0, 0, -1),
		Vector3i(1, 0, -1),
	]
	var allCells: Array[Variant] = []
	for cell in surroundingCells:
		allCells.append(cell + Vector3i(0, 1, 0))
		allCells.append(cell + Vector3i(0, -1, 0))
		allCells.append(cell)
		
	for pointId : int in navMap.get_point_ids():
		var pos: Vector3i = Vector3i(navMap.get_point_position(pointId))
		for surroundingCell in allCells:
			var cellToTest = pos + surroundingCell
			# Make sure the square isn't a wall
			if get_cell_item(cellToTest) != INVALID_CELL_ITEM:
				continue
			# And that there is something to stand on underneath it!
			if get_cell_item(cellToTest + Vector3i(0, -1, 0)) == INVALID_CELL_ITEM:
				continue	
			var cellToTestNavId = navMap.get_closest_point(cellToTest)
			navMap.connect_points(pointId, cellToTestNavId, true)
