extends CharacterBody3D

@export var speed: float = 4.5
@export var acceleration: float = 10.0
@export var friction: float = 8.0
@export var mouse_sensitivity: float = 0.0025
@export var min_pitch: float = -1.3
@export var max_pitch: float = 1.3

@export var bob_frequency: float = 10.0
@export var bob_amplitude: float = 0.04
@export var bob_vertical: float = 0.06

var pitch: float = -0.5
var yaw: float = 0.0
var bob_time: float = 0.0
var camera_base_position: Vector3

@onready var camera: Camera3D = $Camera3D
@onready var flashlight: SpotLight3D = $Camera3D/SpotLight3D

func _ready() -> void:
    _build_collision_shape()
    camera_base_position = camera.position
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
    update_look()

func _build_collision_shape() -> void:
    var collision := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.35
    capsule.height = 1.2
    collision.shape = capsule
    add_child(collision)

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        yaw -= event.relative.x * mouse_sensitivity
        pitch -= event.relative.y * mouse_sensitivity
        pitch = clamp(pitch, min_pitch, max_pitch)
        update_look()

    elif event is InputEventKey and event.is_pressed() and event.keycode == KEY_ESCAPE:
        Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed() and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
        Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta: float) -> void:
    var input_dir := Vector2.ZERO
    if Input.is_key_pressed(KEY_W):
        input_dir.y += 1
    if Input.is_key_pressed(KEY_S):
        input_dir.y -= 1
    if Input.is_key_pressed(KEY_A):
        input_dir.x -= 1
    if Input.is_key_pressed(KEY_D):
        input_dir.x += 1

    if input_dir.length_squared() > 0.0:
        input_dir = input_dir.normalized()

    var camera_basis := camera.global_transform.basis
    var forward: Vector3 = -camera_basis.z
    var right: Vector3 = camera_basis.x
    var move_dir: Vector3 = (forward * input_dir.y + right * input_dir.x)
    move_dir.y = 0.0

    if move_dir.length_squared() > 0.0:
        move_dir = move_dir.normalized()
        velocity.x = move_dir.x * speed
        velocity.z = move_dir.z * speed
    else:
        velocity.x = move_toward(velocity.x, 0.0, friction)
        velocity.z = move_toward(velocity.z, 0.0, friction)

    velocity.y = 0.0
    move_and_slide()

    var move_speed := Vector2(velocity.x, velocity.z).length()
    if move_speed > 0.1:
        bob_time += delta * bob_frequency * (move_speed / speed)
    else:
        bob_time = lerp(bob_time, 0.0, delta * 10.0)

    var bob_offset := Vector3.ZERO
    if move_speed > 0.1:
        bob_offset.x = sin(bob_time) * bob_amplitude
        bob_offset.y = abs(sin(bob_time * 0.5)) * bob_vertical
    camera.position = camera_base_position + bob_offset

func update_look() -> void:
    rotation.y = yaw
    camera.rotation.x = pitch
    camera.rotation.y = 0.0
    camera.rotation.z = 0.0
    flashlight.rotation.x = 0.0
    flashlight.rotation.y = 0.0
