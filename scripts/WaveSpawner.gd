extends Node
class_name WaveSpawner

var enemy_scene: PackedScene = preload("res://scenes/Enemy.tscn")
var wave_data_path: String = "res://data/waves.json"

var waves: Array = []
var current_wave_index: int = 0
var enemies_in_current_wave: int = 0
var enemies_spawned_in_wave: int = 0
var spawn_points: Array[Vector2] = []
var path_points: Array[Vector2] = []

@onready var spawn_timer: Timer = Timer.new()
@onready var wave_delay_timer: Timer = Timer.new()

signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)
signal enemy_spawned(enemy: Enemy)
signal all_waves_completed

func _ready():
    setup_timers()
    load_wave_data()
    
func setup_timers():
    # Setup spawn timer
    add_child(spawn_timer)
    spawn_timer.timeout.connect(_spawn_enemy)
    
    # Setup wave delay timer
    add_child(wave_delay_timer)
    wave_delay_timer.one_shot = true
    wave_delay_timer.timeout.connect(_start_next_wave)

func load_wave_data():
    if FileAccess.file_exists(wave_data_path):
        var file = FileAccess.open(wave_data_path, FileAccess.READ)
        var json_string = file.get_as_text()
        file.close()
        
        var json = JSON.new()
        var parse_result = json.parse(json_string)
        
        if parse_result == OK:
            waves = json.data.waves
        else:
            print("Error parsing wave data")
    else:
        # Create default waves if file doesn't exist
        create_default_waves()

func create_default_waves():
    waves = [
        {
            "wave_number": 1,
            "enemies": [
                {"type": "basic", "count": 5, "spawn_interval": 2.0}
            ],
            "delay_before_next": 10.0
        },
        {
            "wave_number": 2,
            "enemies": [
                {"type": "basic", "count": 8, "spawn_interval": 1.5}
            ],
            "delay_before_next": 10.0
        },
        {
            "wave_number": 3,
            "enemies": [
                {"type": "basic", "count": 6, "spawn_interval": 1.8},
                {"type": "fast", "count": 3, "spawn_interval": 2.5}
            ],
            "delay_before_next": 15.0
        }
    ]

func set_spawn_points(points: Array[Vector2]):
    spawn_points = points

func set_path_points(points: Array[Vector2]):
    path_points = points

func start_waves():
    if waves.is_empty():
        print("No wave data available")
        return
    
    current_wave_index = 0
    _start_wave(current_wave_index)

func _start_wave(wave_index: int):
    if wave_index >= waves.size():
        all_waves_completed.emit()
        return
    
    var wave = waves[wave_index]
    wave_started.emit(wave.wave_number)
    
    enemies_in_current_wave = 0
    enemies_spawned_in_wave = 0
    
    # Count total enemies in wave
    for enemy_group in wave.enemies:
        enemies_in_current_wave += enemy_group.count
    
    # Start spawning first enemy group
    _spawn_enemy_group(wave.enemies, 0)

func _spawn_enemy_group(enemy_groups: Array, group_index: int):
    if group_index >= enemy_groups.size():
        return
    
    var enemy_group = enemy_groups[group_index]
    var spawn_interval = enemy_group.spawn_interval
    var remaining_in_group = enemy_group.count
    
    spawn_timer.wait_time = spawn_interval
    spawn_timer.start()
    
    # Store data for spawning
    set_meta("current_enemy_group", enemy_group)
    set_meta("remaining_in_group", remaining_in_group)
    set_meta("enemy_groups", enemy_groups)
    set_meta("group_index", group_index)

func _spawn_enemy():
    var enemy_group = get_meta("current_enemy_group")
    var remaining_in_group = get_meta("remaining_in_group")
    var enemy_groups = get_meta("enemy_groups")
    var group_index = get_meta("group_index")
    
    if remaining_in_group > 0:
        # Spawn enemy
        var enemy = enemy_scene.instantiate()
        get_parent().add_child(enemy)
        
        # Set spawn position
        if not spawn_points.is_empty():
            enemy.global_position = spawn_points[0]
        
        # Set path
        if not path_points.is_empty():
            enemy.set_path(path_points)
        
        # Connect signals
        enemy.enemy_destroyed.connect(_on_enemy_destroyed)
        enemy.enemy_reached_end.connect(_on_enemy_reached_end)
        
        enemy_spawned.emit(enemy)
        enemies_spawned_in_wave += 1
        remaining_in_group -= 1
        set_meta("remaining_in_group", remaining_in_group)
        
        if remaining_in_group == 0:
            spawn_timer.stop()
            # Move to next enemy group
            _spawn_enemy_group(enemy_groups, group_index + 1)
    
func _on_enemy_destroyed():
    _check_wave_completion()

func _on_enemy_reached_end():
    _check_wave_completion()

func _check_wave_completion():
    var enemies_remaining = get_tree().get_nodes_in_group("enemies").size()
    
    if enemies_spawned_in_wave >= enemies_in_current_wave and enemies_remaining == 0:
        var current_wave = waves[current_wave_index]
        wave_completed.emit(current_wave.wave_number)
        
        current_wave_index += 1
        
        if current_wave_index >= waves.size():
            all_waves_completed.emit()
        else:
            # Start delay before next wave
            wave_delay_timer.wait_time = current_wave.get("delay_before_next", 10.0)
            wave_delay_timer.start()

func _start_next_wave():
    _start_wave(current_wave_index)

func get_current_wave_number() -> int:
    if current_wave_index < waves.size():
        return waves[current_wave_index].wave_number
    return -1

func get_total_waves() -> int:
    return waves.size()
