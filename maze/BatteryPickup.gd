extends Node3D

@export var energy_amount: float = 50.0

var base_y: float = 0.0
var time: float = 0.0

func _ready() -> void:
    base_y = global_position.y
    build_battery_mesh()

func build_battery_mesh() -> void:
    var body := MeshInstance3D.new()
    var body_mesh := CylinderMesh.new()
    body_mesh.top_radius = 0.18
    body_mesh.bottom_radius = 0.18
    body_mesh.height = 0.5
    body.mesh = body_mesh
    body.rotation_degrees.x = 90.0

    var cap := MeshInstance3D.new()
    var cap_mesh := BoxMesh.new()
    cap_mesh.size = Vector3(0.22, 0.12, 0.22)
    cap.mesh = cap_mesh
    cap.position.y = 0.22

    var body_material := StandardMaterial3D.new()
    body_material.albedo_color = Color(1.0, 0.85, 0.1)
    body_material.emission_enabled = true
    body_material.emission = Color(1.0, 0.75, 0.2)
    body_material.emission_energy = 1.1
    body.material_override = body_material

    var cap_material := StandardMaterial3D.new()
    cap_material.albedo_color = Color(0.8, 0.8, 0.8)
    cap.material_override = cap_material

    add_child(body)
    add_child(cap)

func _process(delta: float) -> void:
    time += delta
    rotation.y += delta * 2.0
    position.y = base_y + sin(time * 2.2) * 0.18

func get_energy_amount() -> float:
    return energy_amount
