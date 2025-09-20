extends CharacterBody2D
class_name Enemy

@export var max_health: float = 100.0
@export var speed: float = 150.0
@export var damage: int = 10
@export var reward_money: int = 25

var current_health: float
var path_points: Array[Vector2] = []
var current_target_index: int = 0
var target_position: Vector2

@onready var health_bar = $HealthBar
@onready var sprite = $Sprite2D

signal enemy_reached_end
signal enemy_destroyed

func _ready():
    current_health = max_health
    health_bar.max_value = max_health
    health_bar.value = current_health
    set_next_target()

func _physics_process(delta):
    if path_points.is_empty() or current_target_index >= path_points.size():
        return
    
    var direction = (target_position - global_position).normalized()
    velocity = direction * speed
    move_and_slide()
    
    if global_position.distance_to(target_position) < 10:
        current_target_index += 1
        set_next_target()

func set_path(points: Array[Vector2]):
    path_points = points
    current_target_index = 0
    set_next_target()

func set_next_target():
    if current_target_index < path_points.size():
        target_position = path_points[current_target_index]
    else:
        # Enemy reached the end
        enemy_reached_end.emit()
        queue_free()

func take_damage(damage_amount: float):
    current_health -= damage_amount
    health_bar.value = current_health
    
    if current_health <= 0:
        enemy_destroyed.emit()
        queue_free()
