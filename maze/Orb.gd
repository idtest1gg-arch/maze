extends Node3D

@export var chase_speed: float = 2.6
@export var pursuit_distance: float = 1.0
@export var orb_y: float = 1.2
@export var orb_radius: float = 0.35
@export var light_energy: float = 3.0
@export var light_range: float = 5.0

var maze: Node3D
var player: Node3D
var grid: Array = []
var cell_size: float = 2.0

func _ready() -> void:
    maze = get_parent()
    player = maze.get_node_or_null("Player")
    if player == null:
        player = get_tree().get_first_node_in_group("Player")
    grid = maze.maze_grid if maze != null else []
    cell_size = maze.cell_size if maze != null else 2.0

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
    target_pos.y = orb_y
    var direction: Vector3 = target_pos - global_position
    if direction.length_squared() > 0.01:
        direction = direction.normalized()
        global_position += direction * chase_speed * delta

    if global_position.distance_to(player.global_position) < pursuit_distance:
        get_tree().reload_current_scene()

func a_star(start: Vector2i, goal: Vector2i) -> Array:
    var frontier: Array = [start]
    var came_from: Dictionary = {}
    var visited: Dictionary = {start: true}

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

        for direction in directions:
            var next: Vector2i = current + direction
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
    var path: Array = [cursor]
    while cursor != start:
        cursor = came_from[cursor]
        path.push_front(cursor)

    return path
