extends Node3D

var player: Node3D
var grid: Array
var maze_width: int = 21
var maze_height: int = 21
var cell_size: float = 2.0
var move_speed: float = 2.25
var current_path: Array = []

func _process(delta: float) -> void:
    if player == null:
        return
    if grid == null:
        return

    var player_cell: Vector2i = world_to_cell(player.global_position)
    var orb_cell: Vector2i = world_to_cell(global_position)
    if player_cell == orb_cell:
        if player.has_method("restart_level"):
            player.restart_level()
        return

    current_path = find_path(orb_cell, player_cell)
    if current_path.size() <= 1:
        return

    var next_cell: Vector2i = current_path[1]
    var target_position: Vector3 = Vector3(
        (next_cell.x - (maze_width - 1) / 2.0) * cell_size,
        1.2,
        (next_cell.y - (maze_height - 1) / 2.0) * cell_size
    )

    var direction := target_position - global_position
    direction.y = 0.0
    if direction.length() > 0.05:
        global_position += direction.normalized() * move_speed * delta

    if global_position.distance_to(player.global_position) < 1.1:
        if player.has_method("restart_level"):
            player.restart_level()

func world_to_cell(world_pos: Vector3) -> Vector2i:
    var x: int = int(round((world_pos.x / cell_size) + (maze_width - 1) / 2.0))
    var y: int = int(round((world_pos.z / cell_size) + (maze_height - 1) / 2.0))
    return Vector2i(x, y)

func find_path(start: Vector2i, goal: Vector2i) -> Array:
    var queue: Array = [start]
    var visited: Dictionary = {}
    visited[start] = true
    var came_from: Dictionary = {}

    while not queue.is_empty():
        var current: Vector2i = queue.pop_front()
        if current == goal:
            break

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
            came_from[next] = current
            queue.push_back(next)

    var path: Array = []
    var current_cell: Vector2i = goal
    while true:
        path.push_front(current_cell)
        if current_cell == start:
            break
        if not came_from.has(current_cell):
            return []
        current_cell = came_from[current_cell]

    return path
