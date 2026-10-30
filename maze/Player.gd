extends CharacterBody3D

@export var speed: float = 4.5
@export var acceleration: float = 10.0
@export var friction: float = 8.0
@export var mouse_sensitivity: float = 0.0025
@export var min_pitch: float = -1.3
@export var max_pitch: float = 1.3

@export var bob_frequency: float = 8.0
@export var bob_amplitude: float = 0.025
@export var bob_vertical: float = 0.045
@export var free_fly_speed: float = 8.0
@export var flashlight_drain_per_second: float = 4.5
@export var flashlight_max_energy: float = 200.0
@export var flashlight_start_energy: float = 100.0

const FOOTSTEP_POOL_SIZE := 4

var pitch: float = -0.5
var yaw: float = 0.0
var bob_time: float = 0.0
var camera_base_position: Vector3
var free_camera: bool = false
var step_timer: float = 0.0
var flashlight_battery: float = 100.0
var flashlight_on: bool = true
var footstep_pool: Array[AudioStreamPlayer] = []

@onready var camera: Camera3D = $Camera3D
@onready var flashlight: SpotLight3D = $Camera3D/SpotLight3D
@onready var battery_label: Label = $"../CanvasLayer/BatteryLabel"

func _ready() -> void:
    flashlight_battery = flashlight_start_energy
    camera_base_position = camera.position
    build_footstep_pool()
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
    update_flashlight_ui()
    update_look()

func build_footstep_pool() -> void:
    for i in range(FOOTSTEP_POOL_SIZE):
        var player := AudioStreamPlayer.new()
        player.name = "FootstepAudio_%d" % i
        player.stream = load("res://footstep-on-concrete-4.wav")
        player.volume_db = -10.0
        add_child(player)
        footstep_pool.append(player)

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.is_pressed() and event.keycode == KEY_F4:
        free_camera = not free_camera
        Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
        return

    if event is InputEventKey and event.is_pressed() and event.keycode == KEY_Q:
        flashlight_on = not flashlight_on
        if not flashlight_on:
            flashlight.light_energy = 0.0
        update_flashlight_ui()
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
    update_flashlight(delta)

    if free_camera:
        update_free_camera(delta)
        return

    update_walk_movement(delta)
    apply_camera_bob(delta)
    check_pickups()

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
        play_step_sound(Vector2(velocity.x, velocity.z).length())
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
    if Input.is_key_pressed(KEY_I):
        move_vec.y += 1.0
    if Input.is_key_pressed(KEY_O):
        move_vec.y -= 1.0

    if move_vec.length_squared() > 0.0:
        move_vec = move_vec.normalized() * free_fly_speed
        global_position += move_vec * delta
        play_step_sound(move_vec.length() * 0.7)
    else:
        step_timer = 0.0

func apply_camera_bob(delta: float) -> void:
    var move_speed: float = Vector2(velocity.x, velocity.z).length()
    if move_speed > 0.1:
        bob_time += delta * bob_frequency * (move_speed / max(speed, 0.001))
    else:
        bob_time = lerp(bob_time, 0.0, delta * 7.0)

    var bob_strength: float = 0.0
    if move_speed > 0.1:
        bob_strength = clamp(move_speed / max(speed, 0.001), 0.0, 1.0)

    var target_x: float = sin(bob_time * 2.0) * bob_amplitude * 0.6 * (0.5 + bob_strength)
    var target_y: float = sin(bob_time * 2.0 + PI * 0.5) * bob_vertical * 0.7 * (0.5 + bob_strength)
    var target_z: float = cos(bob_time * 2.0) * bob_amplitude * 0.2
    var shake_x: float = sin(bob_time * 10.0) * 0.003 * bob_strength
    var shake_y: float = cos(bob_time * 8.0) * 0.0022 * bob_strength

    camera.position = camera_base_position + Vector3(target_x, target_y, target_z) + Vector3(shake_x, shake_y, 0.0)

func play_step_sound(move_speed: float) -> void:
    var step_delay: float = clamp(0.52 - move_speed * 0.04, 0.18, 0.52)
    step_timer -= get_physics_process_delta_time()
    if step_timer <= 0.0:
        var audio_player: AudioStreamPlayer = null
        for footstep_player in footstep_pool:
            if not footstep_player.playing:
                audio_player = footstep_player
                break

        if audio_player == null:
            audio_player = footstep_pool[0]

        if audio_player != null:
            audio_player.pitch_scale = 0.9 + randf_range(-0.1, 0.12)
            audio_player.volume_db = -10.0 + randf_range(-1.5, 1.0)
            audio_player.play()

        step_timer = step_delay

func update_flashlight(delta: float) -> void:
    if battery_label == null:
        return

    if flashlight_on and flashlight_battery > 0.0:
        flashlight_battery -= flashlight_drain_per_second * delta
        flashlight.light_energy = 2.2
    else:
        flashlight.light_energy = 0.0

    flashlight_battery = clamp(flashlight_battery, 0.0, flashlight_max_energy)
    update_flashlight_ui()

func update_flashlight_ui() -> void:
    if battery_label == null:
        return
    if flashlight_on and flashlight_battery > 0.0:
        battery_label.text = "BATTERY: %d%%" % int(flashlight_battery)
    else:
        battery_label.text = "BATTERY: OFF"

func collect_battery(amount: float) -> void:
    flashlight_battery = clamp(flashlight_battery + amount, 0.0, flashlight_max_energy)
    update_flashlight_ui()

func check_pickups() -> void:
    if get_parent() == null:
        return

    for child in get_parent().get_children():
        if child is Node3D and child.name.begins_with("Battery"):
            var battery_node: Node3D = child
            if battery_node.global_position.distance_to(global_position) < 1.2:
                var pickup_amount: float = 50.0
                if battery_node.has_method("get_energy_amount"):
                    pickup_amount = battery_node.get_energy_amount()
                collect_battery(pickup_amount)
                battery_node.queue_free()

func update_look() -> void:
    rotation.y = yaw
    camera.rotation.x = pitch
    camera.rotation.y = 0.0
    camera.rotation.z = 0.0
    flashlight.rotation.x = 0.0
    flashlight.rotation.y = 0.0
