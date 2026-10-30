extends Node3D

var maze: Node3D
var player: Node3D
var grid: Array = []
var cell_size: float = 2.0
var move_speed: float = 2.6

func _ready() -> void:
    maze = get_parent()
    player = maze.get_node("Player")
    grid = maze.maze_grid
    cell_size = maze.cell_size

func _process(delta: float) -> void:
    if player == null or maze == null:
        return

    if grid.is_empty():
        grid = maze.maze_grid

    var player_cell: Vector2i = maze.world_to_cell(player.global_position)
    var orb_cell: Vector2i = maze.world_to_cell(global_position)
    var next_cell: Vector2i = orb_cell

    var path: Array = a_star(orb_cell, player_cell)
    if path.size() > 1:
        next_cell = path[1]

    var target_pos: Vector3 = maze.cell_to_world(next_cell)
    target_pos.y = 1.2
    var dir: Vector3 = target_pos - global_position
    if dir.length_squared() > 0.01:
        dir = dir.normalized()
        global_position += dir * move_speed * delta

    if global_position.distance_to(player.global_position) < 1.0:
        get_tree().reload_current_scene()

func a_star(start: Vector2i, goal: Vector2i) -> Array:
    var frontier: Array = [start]
    var came_from: Dictionary = {}
    var visited: Dictionary = {start: true}
    var path: Array = []

    while not frontier.is_empty():
        var current: Vector2i = frontier.pop_front()
        if current == goal:
            break

        var directions: Array = [
            Vector2i(1, 0),
            Vector2i(-1, 0),
            Vector2i(0, 1),
            Vector2i(0, -1)
        ]

        for dir in directions:
            var next: Vector2i = current + dir
            if not maze.is_walkable(next):
                continue
            if visited.has(next):
                continue

            visited[next] = true
            came_from[next] = current
            frontier.push_back(next)

    if not came_from.has(goal):
        return [start]

    var cursor: Vector2i = goal
    path.push_front(cursor)
    while cursor != start:
        cursor = came_from[cursor]
        path.push_front(cursor)

    return path
