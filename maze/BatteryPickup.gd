extends Node3D

@export var energy_amount: float = 50.0

var base_y: float = 0.0
var time: float = 0.0

func _ready() -> void:
    base_y = global_position.y
    _build_pickup_mesh()

func _build_pickup_mesh() -> void:
    var mesh_instance := MeshInstance3D.new()
    var box_mesh := BoxMesh.new()
    box_mesh.size = Vector3(0.18, 0.36, 0.18)
    mesh_instance.mesh = box_mesh

    var material := StandardMaterial3D.new()
    material.albedo_color = Color(1.0, 0.9, 0.2)
    material.emission_enabled = true
    material.emission = Color(1.0, 0.8, 0.2)
    material.emission_energy = 0.8
    mesh_instance.material_override = material
    add_child(mesh_instance)

func _process(delta: float) -> void:
    time += delta
    rotation.y += delta * 2.0
    position.y = base_y + sin(time * 2.2) * 0.18

func get_energy_amount() -> float:
    return energy_amount
