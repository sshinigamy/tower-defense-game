extends StaticBody2D
class_name Tower

@export var damage: float = 50.0
@export var range_radius: float = 200.0
@export var fire_rate: float = 1.0
@export var projectile_speed: float = 400.0
@export var cost: int = 100

var projectile_scene: PackedScene = preload("res://scenes/Projectile.tscn")
var enemies_in_range: Array[Enemy] = []
var current_target: Enemy

@onready var detection_area = $DetectionArea
@onready var detection_radius = $DetectionArea/DetectionRadius
@onready var shoot_timer = $ShootTimer
@onready var sprite = $Sprite2D

signal target_acquired(target: Enemy)
signal projectile_fired

func _ready():
    setup_detection_area()
    setup_shoot_timer()
    detection_area.body_entered.connect(_on_body_entered)
    detection_area.body_exited.connect(_on_body_exited)
    shoot_timer.timeout.connect(_on_shoot_timer_timeout)

func setup_detection_area():
    var shape = CircleShape2D.new()
    shape.radius = range_radius
    detection_radius.shape = shape

func setup_shoot_timer():
    shoot_timer.wait_time = 1.0 / fire_rate
    shoot_timer.start()

func _on_body_entered(body: Node2D):
    if body is Enemy:
        enemies_in_range.append(body)
        if not current_target:
            acquire_target()

func _on_body_exited(body: Node2D):
    if body is Enemy:
        enemies_in_range.erase(body)
        if body == current_target:
            current_target = null
            acquire_target()

func acquire_target():
    if enemies_in_range.is_empty():
        current_target = null
        return
    
    # Target the closest enemy
    var closest_enemy: Enemy = null
    var closest_distance: float = INF
    
    for enemy in enemies_in_range:
        var distance = global_position.distance_to(enemy.global_position)
        if distance < closest_distance:
            closest_distance = distance
            closest_enemy = enemy
    
    current_target = closest_enemy
    if current_target:
        target_acquired.emit(current_target)

func _on_shoot_timer_timeout():
    if current_target:
        fire_projectile(current_target)

func fire_projectile(target: Enemy):
    if not projectile_scene:
        return
    
    var projectile = projectile_scene.instantiate()
    get_parent().add_child(projectile)
    projectile.global_position = global_position
    
    # Calculate direction to target
    var direction = (target.global_position - global_position).normalized()
    projectile.set_direction(direction)
    projectile.set_damage(damage)
    projectile.set_speed(projectile_speed)
    
    projectile_fired.emit()

func upgrade_damage(increase: float):
    damage += increase

func upgrade_range(increase: float):
    range_radius += increase
    setup_detection_area()

func upgrade_fire_rate(increase: float):
    fire_rate += increase
    setup_shoot_timer()
