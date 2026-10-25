extends Node3D

@export var maze_width: int = 17
@export var maze_height: int = 17
@export var cell_size: float = 2.0
@export var wall_height: float = 2.5
@export var wall_thickness: float = 0.22
@export var wall_margin: float = 0.1
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
            row.append({
                "visited": false,
                "walls": {"N": true, "E": true, "S": true, "W": true}
            })
        grid.append(row)

    var stack: Array = [Vector2i(1, 1)]
    grid[1][1]["visited"] = true

    while not stack.is_empty():
        var current: Vector2i = stack.back()
        var options: Array = []
        var directions: Array = [
            Vector2i(0, -2),
            Vector2i(2, 0),
            Vector2i(0, 2),
            Vector2i(-2, 0)
        ]

        for delta in directions:
            var next_cell: Vector2i = current + delta
            if next_cell.x <= 0 or next_cell.x >= maze_width - 1:
                continue
            if next_cell.y <= 0 or next_cell.y >= maze_height - 1:
                continue
            if grid[next_cell.y][next_cell.x]["visited"]:
                continue
            options.append(delta)

        if options.is_empty():
            stack.pop_back()
            continue

        var delta: Vector2i = options[randi() % options.size()]
        var next_cell: Vector2i = current + delta
        var wall_cell: Vector2i = current + delta / 2

        if delta.x > 0:
            grid[current.y][current.x]["walls"]["E"] = false
            grid[wall_cell.y][wall_cell.x]["walls"]["W"] = false
        elif delta.x < 0:
            grid[current.y][current.x]["walls"]["W"] = false
            grid[wall_cell.y][wall_cell.x]["walls"]["E"] = false
        elif delta.y > 0:
            grid[current.y][current.x]["walls"]["S"] = false
            grid[wall_cell.y][wall_cell.x]["walls"]["N"] = false
        elif delta.y < 0:
            grid[current.y][current.x]["walls"]["N"] = false
            grid[wall_cell.y][wall_cell.x]["walls"]["S"] = false

        grid[next_cell.y][next_cell.x]["visited"] = true
        stack.push_back(next_cell)

    create_floor()

    for y in range(maze_height):
        for x in range(maze_width):
            var cell: Dictionary = grid[y][x]
            var center_x := x * cell_size - (maze_width * cell_size) / 2.0 + cell_size / 2.0
            var center_z := y * cell_size - (maze_height * cell_size) / 2.0 + cell_size / 2.0

            if cell["walls"]["N"]:
                add_wall_segment(
                    Vector3(center_x, wall_height * 0.5, center_z - cell_size * 0.5 + wall_margin),
                    Vector3(cell_size - wall_margin * 2.0, wall_height, wall_thickness)
                )
            if cell["walls"]["E"]:
                add_wall_segment(
                    Vector3(center_x + cell_size * 0.5 - wall_margin, wall_height * 0.5, center_z),
                    Vector3(wall_thickness, wall_height, cell_size - wall_margin * 2.0)
                )
            if cell["walls"]["S"]:
                add_wall_segment(
                    Vector3(center_x, wall_height * 0.5, center_z + cell_size * 0.5 - wall_margin),
                    Vector3(cell_size - wall_margin * 2.0, wall_height, wall_thickness)
                )
            if cell["walls"]["W"]:
                add_wall_segment(
                    Vector3(center_x - cell_size * 0.5 + wall_margin, wall_height * 0.5, center_z),
                    Vector3(wall_thickness, wall_height, cell_size - wall_margin * 2.0)
                )

func create_floor() -> void:
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

func add_wall_segment(position: Vector3, size: Vector3) -> void:
    var wall_mesh := BoxMesh.new()
    wall_mesh.size = Vector3(1.0, 1.0, 1.0)

    var wall_instance := MeshInstance3D.new()
    wall_instance.name = "GeneratedWall"
    wall_instance.mesh = wall_mesh
    wall_instance.scale = size
    wall_instance.position = position

    var material := StandardMaterial3D.new()
    material.albedo_color = wall_color
    material.roughness = 0.8
    wall_instance.material_override = material
    add_child(wall_instance)
