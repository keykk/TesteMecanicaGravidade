extends CharacterBody3D
var input_map = {
	"move_left": [KEY_LEFT, KEY_A],
	"move_right": [KEY_RIGHT, KEY_D],
	"move_forward": [KEY_UP, KEY_W],
	"move_back": [KEY_DOWN, KEY_S],
	"jump": [KEY_SPACE],
	"zoom_in": [MOUSE_BUTTON_WHEEL_UP],
	"zoom_out": [MOUSE_BUTTON_WHEEL_DOWN],
	"camera_left":[KEY_J],
	"camera_right":[KEY_L],
	"camera_up":[KEY_I],
	"camera_down":[KEY_K],
	"attack_1":[MOUSE_BUTTON_LEFT]
}
@export_subgroup("Properties")
@export var movement_speed: int = 250
@export var jump_strength: int = 10

@export var planet_path : NodePath

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: Vector3
var gravity_strength: float = 7
var gravity_velocity: Vector3 = Vector3.ZERO

#jump
var jump_single: bool = true
var jump_double: bool = true
var jump_deceleration: float = 10.0
var is_jumping: bool = false

#direction
var input_direction: Vector2 = Vector2.ZERO
var forward_dir: Vector3
var right_dir: Vector3
var move_dir: Vector3 = Vector3.ZERO


#orientation
var up_dir: Vector3
var current_forward: Vector3
var orientation: Basis
var planet_direction: Vector3 = Vector3.ZERO

func _ready():
	load_input_map()
	
func _physics_process(delta):
	# Add the gravity
	handle_controls(delta)
	apply_gravity(delta)
	handle_orientation(delta)
	
	velocity += gravity_velocity
	up_direction = -gravity.normalized()
	
	move_and_slide()
	
	
func apply_gravity(delta) -> void:
	var sphere_node = get_node_or_null(planet_path)
	if sphere_node:
		var dir_to_planet_center: Vector3 = sphere_node.global_transform.origin - global_transform.origin
		gravity = dir_to_planet_center.normalized() * gravity_strength
		gravity_velocity += gravity * delta
		#
	# Taking jump into account
	if is_jumping and gravity_velocity.dot(-gravity.normalized()) > 0:
		gravity_velocity += gravity.normalized() * jump_deceleration * delta  # Upward deceleration to get a smooth jump
	else:
		is_jumping = false
		gravity_velocity += gravity * delta
#
	if is_on_floor():
		gravity_velocity = gravity_velocity.lerp(Vector3.ZERO, 10 * delta)
		jump_single = true
		jump_double = true
		
func handle_controls(delta) -> void:
	input_direction = Vector2.ZERO
	input_direction.y = Input.get_axis("move_right", "move_left")
	input_direction.x = Input.get_axis("move_back", "move_forward")
	
	input_direction = input_direction.normalized()

	right_dir = -transform.basis.x
	forward_dir = -transform.basis.z

	move_dir = (forward_dir * input_direction.x + right_dir * input_direction.y).normalized()
	
	velocity = move_dir * movement_speed * delta
	
	if Input.is_action_just_pressed("jump"):
		if jump_single:
			jump_single = false
			jump_action()
		elif jump_double:
			jump_double = false
			jump_action()
	

func handle_orientation(delta) -> void:
	# Step 1: Align the player with the planet
	up_dir = -gravity.normalized()
	current_forward = global_transform.basis.z # This might cause the resetting while leaving keys

	# Ensure move_dir is orthogonal to up_dir
	move_dir = (move_dir - up_dir * move_dir.dot(up_dir)).normalized()

	# Calculate a forward direction. If the current forward direction 
	# is almost parallel to up_dir, choose a different reference axis for stability.
	if abs(current_forward.dot(up_dir)) > 0.98:  # nearly parallel
		current_forward = global_transform.basis.x  # Use the side vector as a reference

	# Make sure the new forward direction is orthogonal to up_dir
	forward_dir = (current_forward - up_dir * current_forward.dot(up_dir)).normalized()

	# Calculate the right direction based on the new forward and up directions
	right_dir = up_dir.cross(forward_dir).normalized()

	# Build the orientation matrix
	orientation = Basis(right_dir, up_dir, forward_dir)
	global_transform.basis = orientation
	
func jump() -> void:
	
	jump_action()
	
	scale = Vector3(0.5, 1.5, 0.5)
	
	jump_single = false;
	jump_double = true;

func jump_action() -> void:
	if is_on_floor() or jump_double:
		scale = Vector3(0.5, 1.5, 0.5)
		gravity_velocity = -gravity.normalized() * jump_strength
		is_jumping = true
	
func load_input_map():
	#vincular mapa
	for action in input_map.keys():
		var keys = input_map[action]
		for key in keys:
			var tecla = InputEventKey.new()
			tecla.keycode = key
			
			var input_mouse_button = InputEventMouseButton.new()
			
			#adicionaa ação
			if not InputMap.has_action(action):
				InputMap.add_action(action)
				
			if key == 1 || key == 2:
				input_mouse_button.pressed = true
				input_mouse_button.button_index = key
				InputMap.action_add_event(action, input_mouse_button)
				
				pass
			else:
				InputMap.action_add_event(action, tecla)	
	#print(str(input_map))

func clear_input_map():
	# desvincular antigo
	for action in input_map.keys():
		var keys = input_map[action]
		for key in keys:
			var tecla = InputEventKey.new()
			tecla.keycode = key
			
			var input_mouse_button = InputEventMouseButton.new()
			
			if key == 1 || key == 2:
				input_mouse_button.pressed = true
				input_mouse_button.button_index = key
				InputMap.action_erase_event(action, input_mouse_button)	
				
				pass
			else:
				InputMap.action_erase_event(action, tecla)	

func get_projected_position_on_planet() -> Vector3:
	var sphere_node: Node = get_node_or_null(planet_path)
	if sphere_node:
		var normalized_dir = planet_direction.normalized()
		var planet_radius = sphere_node.scale.x * 0.5  # Assuming the planet is a perfect sphere with diameter = scale.x
		return sphere_node.global_transform.origin + normalized_dir * planet_radius
	return Vector3.ZERO
