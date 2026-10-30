extends Node3D

@export var energy_amount: float = 50.0

var base_y: float = 0.0
var time: float = 0.0

func _ready() -> void:
    base_y = global_position.y
    build_battery_mesh()

func build_battery_mesh() -> void:
    var mesh := MeshInstance3D.new()
    var obj_mesh: Mesh = load("res://battery_obj/battery.obj")
    mesh.mesh = obj_mesh
    mesh.scale = Vector3(0.22, 0.22, 0.22)
    mesh.rotation_degrees.x = 90.0

    var material := StandardMaterial3D.new()
    material.albedo_texture = load("res://battery_obj/baterijaTekstura.jpg")
    material.roughness = 0.8
    material.metallic = 0.2
    material.uv1_triplanar = false
    material.uv1_scale = Vector3.ONE
    mesh.material_override = material

    add_child(mesh)

func _process(delta: float) -> void:
    time += delta
    rotation.y += delta * 2.0
    position.y = base_y + sin(time * 2.2) * 0.18

func get_energy_amount() -> float:
    return energy_amount
