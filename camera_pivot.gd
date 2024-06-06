extends Node3D
@export_group("Properties")

@export var target: CharacterBody3D

@export_group("Zoom")
@export var zoom_minimum = 16
@export var zoom_maximum = 4
@export var zoom_speed = 10

@export_group("Rotation")
@export var rotation_speed = 120
@export var min_rotation_x = -80
@export var max_rotation_x = -10

@export_group("Mouse")
@export var mouse_sensitivity : float = 0.1

var camera_rotation:Vector3
var target_rotation:Vector3
var zoom = 10
var is_right_mouse_button_pressed = false
var last_mouse_position = Vector2()
var input := Vector3.ZERO
var input_target := Vector3.ZERO
@onready var planet = $"../planet1"

@onready var camera = $camera

var smoothing: float = 10
var last_position: float = 0.0
var player
const VERTICAL_LIMIT = 60 
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	camera_rotation = rotation_degrees # Initial rotation
	player = target
	pass


func _physics_process(delta):
	self.position = self.position.lerp(target.position, delta * 4)
	
	camera.position = camera.position.lerp(Vector3(0, 0, zoom), 8 * delta)
	handle_input(delta)
	global_transform.basis = target.orientation
	update_camera(delta)
	pass

# Handle input

func handle_input(delta):
	# Rotation
	input.y = Input.get_axis("camera_left", "camera_right")
	input.x = Input.get_axis("camera_up", "camera_down")
	
	#camera_rotation += input.limit_length(1.0) * rotation_speed * delta
	#camera_rotation.x = clamp(camera_rotation.x, min_rotation_x, max_rotation_x)
	# Zooming
	
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
		#
		#var input := Vector3.ZERO
		#input.x = (mouse_movement.y * mouse_sensitivity) * -1
		#input.y = (mouse_movement.x * mouse_sensitivity) * -1
	#
		#camera_rotation += input.limit_length(1.0) * 4
		
		#
		#print(mouse_movement)
		#var current_mouse_position = event.position
		#var delta = current_mouse_position - last_mouse_position
		#last_mouse_position = current_mouse_position
		rotate_camera(mouse_movement)

func rotate_camera(delta):
	input.x = (delta.y * mouse_sensitivity) * -1
	input_target.y = (delta.x * mouse_sensitivity) * -1
	
	camera_rotation += input.limit_length(1.0) * 4
	target_rotation += input_target.limit_length(1.0) * 1
	target_rotation.y = clamp(target_rotation.y, -10, 10)
	camera_rotation.x = clamp(camera_rotation.x, -VERTICAL_LIMIT, 30)
	update_player_rotation()


func update_player_rotation():
	# Pegar a base atual do jogador
	
	var player_transform = player.global_transform
	
	# Criar uma nova base para rotação horizontal
	var rotation_transform = Transform3D()
	rotation_transform.basis = Basis()
	rotation_transform.basis = rotation_transform.basis.rotated(Vector3(0, 1, 0), deg_to_rad(target_rotation.y))
	
	# Aplicar a rotação horizontal ao jogador mantendo a orientação vertical
	player_transform.basis = rotation_transform.basis * player_transform.basis
	
	# Atualizar a transformação global do jogador
	player.global_transform = player_transform
	apply_mouse_rotation_target()
	
		
#func update_player_rotation():
	## Calcular a nova direção do jogador após a rotação horizontal da câmera
	#var new_player_forward = player.global_transform.basis.z.rotated(Vector3(0, 1, 0), deg_to_rad(camera_rotation.y))
	#
	## Calcular a rotação necessária para a nova direção do jogador
	#var look_rotation = Basis(new_player_forward, Vector3(0, 1, 0)).get_rotation_quat()
	#
	## Aplicar a nova rotação ao jogador
	#player.global_transform.basis = Basis(look_rotation)
	
func update_camera(delta):
	## Posição do jogador e do planeta
	#var player_position = player.global_transform.origin
	#var planet_position = planet.global_transform.origin
	#
	## Vetor da direção do planeta para o jogador
	#var to_player = (player_position - planet_position).normalized()
	#
	## Calcular a nova orientação da câmera
	#var target_orientation = Transform3D()
	#target_orientation.origin = global_transform.origin  # Manter a posição da câmera
	#target_orientation.basis = Basis()  # Resetar a base
	#
	## Definir o eixo "up" da câmera como o vetor de direção do planeta para o jogador
	#target_orientation.basis.y = to_player
	#
	## Definir o eixo "forward" da câmera como a direção que o jogador está olhando
	#target_orientation.basis.z = (player.global_transform.basis.z).normalized()
	#
	## Corrigir o eixo "x" com um produto vetorial para manter a ortogonalidade
	#target_orientation.basis.x = target_orientation.basis.y.cross(target_orientation.basis.z).normalized()
	#
	## Recalcular o eixo "z" para garantir a ortogonalidade
	#target_orientation.basis.z = target_orientation.basis.x.cross(target_orientation.basis.y).normalized()
	#
	## Interpolar suavemente a rotação da câmera
	#global_transform.basis = global_transform.basis.slerp(target_orientation.basis, 0.18)
	
	apply_mouse_rotation()
	
func apply_mouse_rotation():
	var rotation_transform = Transform3D()
	rotation_transform.basis = Basis()
	rotation_transform.basis = rotation_transform.basis.rotated(Vector3(1, 0, 0), deg_to_rad(camera_rotation.x))
	rotation_transform.basis = rotation_transform.basis.rotated(Vector3(0, 1, 0), deg_to_rad(camera_rotation.y))
	
	# Aplicar a rotação adicional à câmera
	global_transform.basis = global_transform.basis * rotation_transform.basis
	
func apply_mouse_rotation_target():
	var rotation_transform = Transform3D()
	rotation_transform.basis = Basis()
	#rotation_transform.basis = rotation_transform.basis.rotated(Vector3(1, 0, 0), deg_to_rad(target_rotation.x))
	rotation_transform.basis = rotation_transform.basis.rotated(Vector3(0, 1, 0), deg_to_rad(target_rotation.y))
	
	# Aplicar a rotação adicional à câmera
	target.global_transform.basis = global_transform.basis * rotation_transform.basis	
