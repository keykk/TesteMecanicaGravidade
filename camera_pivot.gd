extends Node3D
@export_group("Properties")

@export var target: CharacterBody3D

@export_group("Zoom")
@export var zoom_minimum = 16
@export var zoom_maximum = 4
@export var zoom_speed = 10

@export_group("Mouse")
@export var mouse_sensitivity : float = 0.1

var camera_rotation:Vector3 = Vector3.ZERO
var previous_camera_rotation_y = 0.0
var zoom = 10

@onready var camera = $camera

const VERTICAL_LIMIT = 60 
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	camera_rotation = rotation_degrees # Initial rotation
	pass


func _physics_process(delta):
	self.position = self.position.lerp(target.position, delta * 4)
	camera.position = camera.position.lerp(Vector3(0, 0, zoom), 8 * delta)
	handle_input(delta)
	global_transform.basis = target.orientation
	update_player_rotation()
	apply_mouse_rotation()
	pass

# Handle input

func handle_input(delta):
	# Rotation
	var input := Vector3.ZERO
	input.y = Input.get_axis("camera_left", "camera_right")
	input.x = Input.get_axis("camera_up", "camera_down")
	
	camera_rotation += input.limit_length(1.0) * 4
	camera_rotation.x = clamp(camera_rotation.x, -VERTICAL_LIMIT, 30)
	
	zoom += Input.get_axis("zoom_in", "zoom_out") * zoom_speed * delta
	zoom = clamp(zoom, zoom_maximum, zoom_minimum)
	
func _unhandled_input(event):
	if event is InputEventMouseButton:
		
		if event.pressed:		
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				zoom -= lerpf(zoom, zoom_speed, 0.1)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				zoom += lerpf(zoom, zoom_speed, 0.1) 
			zoom = clamp(zoom,zoom_maximum, zoom_minimum)
	
	if event is InputEventMouseMotion:
		var mouse_movement = event.relative
		rotate_camera(mouse_movement)

func rotate_camera(delta):
	var input := Vector3.ZERO
	input.x = (delta.y * mouse_sensitivity) * -1
	input.y = (delta.x * mouse_sensitivity) * -1
	
	camera_rotation += input.limit_length(1.0) * 4
	camera_rotation.x = clamp(camera_rotation.x, -VERTICAL_LIMIT, 30)
	
	
func update_player_rotation():
	# Calcular a rotação incremental da câmera 2
	var delta_rotation_y = camera_rotation.y - previous_camera_rotation_y
	previous_camera_rotation_y = camera_rotation.y
	
	# Calcular a rotação horizontal do jogador
	var player_rotation_transform = Transform3D()
	player_rotation_transform.basis = Basis()
	player_rotation_transform.basis = player_rotation_transform.basis.rotated(Vector3(0, 1, 0), deg_to_rad(delta_rotation_y))
	
	# Aplicar a rotação diretamente ao jogador
	target.global_transform.basis = target.global_transform.basis * player_rotation_transform.basis
	

func apply_mouse_rotation():
	var rotation_transform = Transform3D()
	rotation_transform.basis = Basis()
	rotation_transform.basis = rotation_transform.basis.rotated(Vector3(1, 0, 0), deg_to_rad(camera_rotation.x))
	#rotation_transform.basis = rotation_transform.basis.rotated(Vector3(0, 1, 0), deg_to_rad(camera_rotation.y))
	
	# Aplicar a rotação adicional à câmera
	global_transform.basis = global_transform.basis * rotation_transform.basis
