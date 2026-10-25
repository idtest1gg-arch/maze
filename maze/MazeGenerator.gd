extends Node3D

@export var maze_width: int = 21
@export var maze_height: int = 21
@export var cell_size: float = 2.0
@export var wall_height: float = 2.5
@export var wall_color: Color = Color(0.92, 0.88, 0.8)
@export var floor_color: Color = Color(0.12, 0.14, 0.16)

func _ready() -> void:
    generate_maze()

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
    create_floor(grid)
    create_walls(grid)

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

func create_floor(grid: Array) -> void:
    var floor_mesh := BoxMesh.new()
    floor_mesh.size = Vector3(maze_width * cell_size, 0.2, maze_height * cell_size)

    var floor_instance := MeshInstance3D.new()
    floor_instance.name = "GeneratedFloor"
    floor_instance.mesh = floor_mesh
    floor_instance.position = Vector3(0.0, -0.15, 0.0)

    var material := StandardMaterial3D.new()
    material.albedo_color = floor_color
    material.roughness = 0.9
    floor_instance.material_override = material
    add_child(floor_instance)

func create_walls(grid: Array) -> void:
    for y in range(maze_height):
        for x in range(maze_width):
            if grid[y][x] != 1:
                continue

            var world_x: float = (x - (maze_width - 1) / 2.0) * cell_size
            var world_z: float = (y - (maze_height - 1) / 2.0) * cell_size
            add_wall_block(Vector3(world_x, wall_height * 0.5, world_z))

func add_wall_block(position: Vector3) -> void:
    var wall_mesh := BoxMesh.new()
    wall_mesh.size = Vector3(1.0, 1.0, 1.0)

    var wall_instance := MeshInstance3D.new()
    wall_instance.name = "GeneratedWall"
    wall_instance.mesh = wall_mesh
    wall_instance.scale = Vector3(cell_size, wall_height, cell_size)
    wall_instance.position = position

    var material := StandardMaterial3D.new()
    material.albedo_color = wall_color
    material.roughness = 0.8
    wall_instance.material_override = material
    add_child(wall_instance)
