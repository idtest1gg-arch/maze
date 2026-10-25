extends CharacterBody3D

@export var speed: float = 4.5
@export var acceleration: float = 10.0
@export var friction: float = 8.0
@export var mouse_sensitivity: float = 0.0025
@export var min_pitch: float = -1.3
@export var max_pitch: float = 1.3

var pitch: float = -0.5
var yaw: float = 0.0

@onready var camera: Camera3D = $Camera3D
@onready var flashlight: SpotLight3D = $Camera3D/SpotLight3D

func _ready() -> void:
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
    update_look()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        yaw -= event.relative.x * mouse_sensitivity
        pitch -= event.relative.y * mouse_sensitivity
        pitch = clamp(pitch, min_pitch, max_pitch)
        update_look()

    if event is InputEventKey and event.is_pressed() and event.keycode == KEY_ESCAPE:
        Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed() and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
        Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta: float) -> void:
    var input_dir := Vector2.ZERO
    if Input.is_key_pressed(KEY_W):
        input_dir.y -= 1
    if Input.is_key_pressed(KEY_S):
        input_dir.y += 1
    if Input.is_key_pressed(KEY_A):
        input_dir.x -= 1
    if Input.is_key_pressed(KEY_D):
        input_dir.x += 1

    input_dir = input_dir.normalized()

    var basis := Basis()
    basis = Basis(Vector3.UP, yaw)
    var move_dir := Vector3.ZERO
    move_dir = basis.x * input_dir.x + basis.z * input_dir.y
    move_dir = move_dir.normalized()

    if move_dir.length_squared() > 0.0:
        velocity.x = move_dir.x * speed
        velocity.z = move_dir.z * speed
        velocity.y = 0.0
    else:
        velocity.x = move_toward(velocity.x, 0.0, friction)
        velocity.z = move_toward(velocity.z, 0.0, friction)

    move_and_slide()
    camera.rotation.x = pitch
    flashlight.rotation.x = 0.0
    flashlight.rotation.y = 0.0

func update_look() -> void:
    rotation.y = yaw
    camera.rotation.x = pitch
    camera.rotation.y = 0.0
    camera.rotation.z = 0.0
