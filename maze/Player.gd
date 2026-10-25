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
@export var free_fly_speed: float = 8.0

var pitch: float = -0.5
var yaw: float = 0.0
var bob_time: float = 0.0
var camera_base_position: Vector3
var free_camera: bool = false
var step_timer: float = 0.0
var step_interval: float = 0.45
var current_step_volume: float = -8.0

@onready var camera: Camera3D = $Camera3D
@onready var flashlight: SpotLight3D = $Camera3D/SpotLight3D
@onready var footstep_audio: AudioStreamPlayer3D = $AudioStreamPlayer3D

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
    if event is InputEventKey and event.is_pressed() and event.keycode == KEY_F4:
        free_camera = not free_camera
        Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
        return

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
    apply_camera_bob(delta)

    if free_camera:
        update_free_camera(delta)
        return

    update_walk_movement(delta)

func update_walk_movement(delta: float) -> void:
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

    var forward: Vector3 = -camera.global_transform.basis.z
    var right: Vector3 = camera.global_transform.basis.x
    var move_dir: Vector3 = (forward * input_dir.y + right * input_dir.x)
    move_dir.y = 0.0

    if move_dir.length_squared() > 0.0:
        move_dir = move_dir.normalized()
        velocity.x = move_dir.x * speed
        velocity.z = move_dir.z * speed
        play_step_sound(delta)
    else:
        velocity.x = move_toward(velocity.x, 0.0, friction)
        velocity.z = move_toward(velocity.z, 0.0, friction)
        step_timer = 0.0

    velocity.y = 0.0
    move_and_slide()

func update_free_camera(delta: float) -> void:
    var move_vec := Vector3.ZERO
    if Input.is_key_pressed(KEY_W):
        move_vec -= transform.basis.z
    if Input.is_key_pressed(KEY_S):
        move_vec += transform.basis.z
    if Input.is_key_pressed(KEY_A):
        move_vec -= transform.basis.x
    if Input.is_key_pressed(KEY_D):
        move_vec += transform.basis.x
    if Input.is_key_pressed(KEY_Q):
        move_vec.y -= 1.0
    if Input.is_key_pressed(KEY_E):
        move_vec.y += 1.0

    if move_vec.length_squared() > 0.0:
        move_vec = move_vec.normalized() * free_fly_speed
        global_position += move_vec * delta
        play_step_sound(delta)
    else:
        step_timer = 0.0

func apply_camera_bob(delta: float) -> void:
    var move_speed: float = velocity.length()
    if move_speed > 0.1:
        bob_time += delta * bob_frequency * (move_speed / speed)
    else:
        bob_time = lerp(bob_time, 0.0, delta * 10.0)

    var bob_target := Vector3.ZERO
    bob_target.x = sin(bob_time * 2.0) * bob_amplitude * 0.5
    bob_target.y = abs(sin(bob_time)) * bob_vertical
    bob_target.z = cos(bob_time * 2.0) * bob_amplitude * 0.2

    var shake_amount := clamp(move_speed / (speed * 1.2), 0.0, 1.0)
    var shake := Vector3(
        sin(bob_time * 7.0) * 0.008 * shake_amount,
        cos(bob_time * 9.0) * 0.006 * shake_amount,
        0.0
    )

    camera.position = camera_base_position + bob_target + shake

func play_step_sound(delta: float) -> void:
    step_timer -= delta
    if step_timer <= 0.0:
        if footstep_audio and footstep_audio.stream != null:
            footstep_audio.pitch_scale = 0.95 + randf_range(-0.08, 0.08)
            footstep_audio.volume_db = current_step_volume + randf_range(-1.5, 1.0)
            if not footstep_audio.playing:
                footstep_audio.play()
        step_timer = step_interval

func update_look() -> void:
    rotation.y = yaw
    camera.rotation.x = pitch
    camera.rotation.y = 0.0
    camera.rotation.z = 0.0
    flashlight.rotation.x = 0.0
    flashlight.rotation.y = 0.0
