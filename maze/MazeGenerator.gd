extends Node3D

@export var maze_width: int = 21
@export var maze_height: int = 21
@export var cell_size: float = 2.0
@export var wall_height: float = 2.5
@export var wall_color: Color = Color(0.92, 0.88, 0.8)
@export var floor_color: Color = Color(0.55, 0.55, 0.55)
@export var ceiling_color: Color = Color(0.7, 0.7, 0.7)

var wall_material: StandardMaterial3D

func _ready() -> void:
    wall_material = create_wall_material()
    generate_maze()
    spawn_player()

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
        if child.name.begins_with("Generated") or child.name.begins_with("Battery") or child.name == "Orb":
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
    create_ceiling()
    spawn_batteries(grid)
    spawn_orb(grid)

func spawn_player() -> void:
    var player = get_node_or_null("Player")
    if player == null:
        return

    var start_x: float = 1.0 - float(maze_width - 1) / 2.0
    var start_z: float = 1.0 - float(maze_height - 1) / 2.0
    player.position = Vector3(start_x * cell_size, 1.2, start_z * cell_size)
    player.rotation = Vector3.ZERO

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

func create_ceiling() -> void:
    var ceiling_mesh := MeshInstance3D.new()
    var box_mesh := BoxMesh.new()
    box_mesh.size = Vector3(maze_width * cell_size, 0.2, maze_height * cell_size)
    ceiling_mesh.mesh = box_mesh
    ceiling_mesh.position = Vector3(0.0, wall_height + 0.08, 0.0)

    var material := StandardMaterial3D.new()
    material.albedo_color = ceiling_color
    material.roughness = 0.9
    ceiling_mesh.material_override = material
    add_child(ceiling_mesh)

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
            if grid[y][x] == 0 and Vector2i(x, y) != Vector2i(1, 1):
                open_cells.append(Vector2i(x, y))

    open_cells.shuffle()
    var battery_count: int = int(floor(float(open_cells.size()) / 10.0))
    battery_count = max(1, battery_count)

    for i in range(battery_count):
        if i >= open_cells.size():
            break

        var cell: Vector2i = open_cells[i]
        var battery := Node3D.new()
        battery.name = "Battery_%d" % i
        battery.position = Vector3(
            (cell.x - (maze_width - 1) / 2.0) * cell_size,
            1.1,
            (cell.y - (maze_height - 1) / 2.0) * cell_size
        )

        var battery_script = load("res://BatteryPickup.gd")
        battery.set_script(battery_script)
        add_child(battery)

func spawn_orb(grid: Array) -> void:
    var farthest := find_farthest_open_cell(Vector2i(1, 1), grid)
    if farthest == null:
        return

    var orb := Node3D.new()
    orb.name = "Orb"
    orb.position = Vector3(
        (farthest.x - (maze_width - 1) / 2.0) * cell_size,
        1.2,
        (farthest.y - (maze_height - 1) / 2.0) * cell_size
    )

    var orb_mesh := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = 0.35
    sphere.height = 0.7
    orb_mesh.mesh = sphere

    var material := StandardMaterial3D.new()
    material.albedo_color = Color.BLACK
    material.emission_enabled = true
    material.emission = Color(0.0, 0.0, 0.0)
    material.roughness = 0.25
    orb_mesh.material_override = material
    orb.add_child(orb_mesh)

    var red_light := OmniLight3D.new()
    red_light.light_color = Color(1.0, 0.0, 0.0)
    red_light.light_energy = 3.0
    red_light.omni_range = 5.0
    red_light.shadow_enabled = true
    orb.add_child(red_light)

    add_child(orb)

func find_farthest_open_cell(start: Vector2i, grid: Array) -> Vector2i:
    var queue: Array = [start]
    var visited: Dictionary = {}
    visited[start] = true
    var previous: Dictionary = {}
    var farthest: Vector2i = start

    while not queue.is_empty():
        var current: Vector2i = queue.pop_front()
        farthest = current

        var directions: Array = [
            Vector2i(1, 0),
            Vector2i(-1, 0),
            Vector2i(0, 1),
            Vector2i(0, -1)
        ]

        for direction in directions:
            var next: Vector2i = current + direction
            if next.x < 0 or next.x >= maze_width:
                continue
            if next.y < 0 or next.y >= maze_height:
                continue
            if grid[next.y][next.x] != 0:
                continue
            if visited.has(next):
                continue

            visited[next] = true
            previous[next] = current
            queue.push_back(next)

    return farthest
