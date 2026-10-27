extends Node3D

@export var maze_width: int = 21
@export var maze_height: int = 21
@export var cell_size: float = 2.0
@export var wall_height: float = 2.5
@export var wall_color: Color = Color(0.92, 0.88, 0.8)
@export var floor_color: Color = Color(0.12, 0.14, 0.16)

var wall_material: StandardMaterial3D

func _ready() -> void:
    wall_material = create_wall_material()
    generate_maze()

func create_wall_material() -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_texture = load("res://2K/Poliigon_BrickReclaimedRunning_7787_BaseColor.jpg")
    material.normal_texture = load("res://2K/Poliigon_BrickReclaimedRunning_7787_Normal.png")
    material.roughness_texture = load("res://2K/Poliigon_BrickReclaimedRunning_7787_Roughness.jpg")
    material.ao_texture = load("res://2K/Poliigon_BrickReclaimedRunning_7787_AmbientOcclusion.jpg")
    material.uv1_scale = Vector3(0.8, 0.8, 1.0)
    material.uv1_triplanar = true
    return material

func generate_maze() -> void:
    for child in get_children():
        if child.name.begins_with("Generated"):
            child.queue_free()

    if maze_width % 2 == 0:
        maze_width += 1
    if maze_height % 2 == 0:
        maze_height += 1

    var grid: Array = []
    for y in range(maze_height):
        var row: Array = []
        for x in range(maze_width):
            row.append(1)
        grid.append(row)

    carve_maze(grid, Vector2i(1, 1))
    create_floor()
    create_walls(grid)
    spawn_batteries(grid)

func carve_maze(grid: Array, start: Vector2i) -> void:
    var stack: Array = [start]
    grid[start.y][start.x] = 0

    while not stack.is_empty():
        var current: Vector2i = stack.back()
        var options: Array = []
        var directions: Array = [
            Vector2i(2, 0),
            Vector2i(-2, 0),
            Vector2i(0, 2),
            Vector2i(0, -2)
        ]

        for delta in directions:
            var next: Vector2i = current + delta
            if next.x <= 0 or next.x >= maze_width - 1:
                continue
            if next.y <= 0 or next.y >= maze_height - 1:
                continue
            if grid[next.y][next.x] == 1:
                var wall_pos: Vector2i = current + delta / 2
                if grid[wall_pos.y][wall_pos.x] == 1:
                    options.append(delta)

        if options.is_empty():
            stack.pop_back()
            continue

        var delta: Vector2i = options[randi() % options.size()]
        var next: Vector2i = current + delta
        var mid: Vector2i = current + delta / 2

        grid[mid.y][mid.x] = 0
        grid[next.y][next.x] = 0
        stack.push_back(next)

func create_floor() -> void:
    var floor_body := StaticBody3D.new()
    floor_body.name = "GeneratedFloor"

    var floor_shape := CollisionShape3D.new()
    var floor_box := BoxShape3D.new()
    floor_box.size = Vector3(maze_width * cell_size, 0.2, maze_height * cell_size)
    floor_shape.shape = floor_box
    floor_shape.position = Vector3(0.0, -0.01, 0.0)
    floor_body.add_child(floor_shape)

    var floor_mesh := MeshInstance3D.new()
    var floor_box_mesh := BoxMesh.new()
    floor_box_mesh.size = Vector3(maze_width * cell_size, 0.2, maze_height * cell_size)
    floor_mesh.mesh = floor_box_mesh
    floor_mesh.position = Vector3(0.0, -0.01, 0.0)

    var material := StandardMaterial3D.new()
    material.albedo_color = floor_color
    material.roughness = 0.9
    floor_mesh.material_override = material

    floor_body.add_child(floor_mesh)
    add_child(floor_body)

func create_walls(grid: Array) -> void:
    for y in range(maze_height):
        for x in range(maze_width):
            if grid[y][x] != 1:
                continue

            var world_x: float = (x - (maze_width - 1) / 2.0) * cell_size
            var world_z: float = (y - (maze_height - 1) / 2.0) * cell_size
            add_wall_block(Vector3(world_x, 0.0, world_z))

func add_wall_block(position: Vector3) -> void:
    var wall_body := StaticBody3D.new()
    wall_body.name = "GeneratedWall"
    wall_body.position = Vector3(position.x, wall_height * 0.5 - 0.02, position.z)

    var collision := CollisionShape3D.new()
    var wall_shape := BoxShape3D.new()
    wall_shape.size = Vector3(cell_size, wall_height, cell_size)
    collision.shape = wall_shape
    wall_body.add_child(collision)

    var wall_mesh := MeshInstance3D.new()
    var box_mesh := BoxMesh.new()
    box_mesh.size = Vector3(1.0, 1.0, 1.0)
    wall_mesh.mesh = box_mesh
    wall_mesh.scale = Vector3(cell_size, wall_height, cell_size)
    wall_mesh.material_override = wall_material

    wall_body.add_child(wall_mesh)
    add_child(wall_body)

func spawn_batteries(grid: Array) -> void:
    var open_cells: Array = []
    for y in range(maze_height):
        for x in range(maze_width):
            if grid[y][x] == 0:
                open_cells.append(Vector2i(x, y))

    open_cells.shuffle()
    var battery_count: int = int(floor(float(open_cells.size()) / 10.0))
    battery_count = max(1, battery_count)

    for i in range(battery_count):
        if i >= open_cells.size():
            break
        var cell: Vector2i = open_cells[i]
        var battery := Node3D.new()
        battery.name = "Battery"
        battery.position = Vector3(
            (cell.x - (maze_width - 1) / 2.0) * cell_size,
            1.1,
            (cell.y - (maze_height - 1) / 2.0) * cell_size
        )
        var battery_script = load("res://BatteryPickup.gd")
        battery.set_script(battery_script)
        add_child(battery)
