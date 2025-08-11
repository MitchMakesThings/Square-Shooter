class_name CharacterController extends CharacterBody3D

@onready
var target_position : Vector3 = global_position

func _physics_process(delta):
	if ((global_position - target_position).length() < .1):
		return
	velocity = (target_position - global_position).normalized() * 300 * delta
	move_and_slide()
	
