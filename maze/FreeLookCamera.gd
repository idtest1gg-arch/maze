extends Camera3D

@export var mouse_sensitivity: float = 0.0025
@export var movement_speed: float = 10.0
@export var sprint_speed: float = 18.0
@export var vertical_speed: float = 8.0

var pitch: float = -0.35
var yaw: float = -PI / 2.0

func _ready() -> void:
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
    update_camera_rotation()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        yaw -= event.relative.x * mouse_sensitivity
        pitch -= event.relative.y * mouse_sensitivity
        pitch = clamp(pitch, -1.3, 1.3)
        update_camera_rotation()

    elif event is InputEventKey and event.is_pressed() and event.keycode == KEY_ESCAPE:
        Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed() and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
        Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _process(delta: float) -> void:
    var move := Vector3.ZERO
    var input_x := int(Input.is_key_pressed(KEY_D)) - int(Input.is_key_pressed(KEY_A))
    var input_y := int(Input.is_key_pressed(KEY_W)) - int(Input.is_key_pressed(KEY_S))
    var input_vertical := int(Input.is_key_pressed(KEY_E)) - int(Input.is_key_pressed(KEY_Q))

    move = (basis.x * input_x) + (-basis.z * input_y) + (Vector3.UP * input_vertical)
    if move.length() > 0.0:
        move = move.normalized()

    var speed := movement_speed
    if Input.is_key_pressed(KEY_SHIFT):
        speed = sprint_speed

    position += move * speed * delta

func update_camera_rotation() -> void:
    basis = Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, pitch)
