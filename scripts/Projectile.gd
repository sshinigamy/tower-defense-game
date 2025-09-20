extends CharacterBody2D
class_name Projectile

var speed: float = 400.0
var damage: float = 50.0
var direction: Vector2 = Vector2.ZERO
var lifetime: float = 5.0

@onready var sprite = $Sprite2D
@onready var trail = $Trail
@onready var collision_shape = $CollisionShape2D

signal hit_enemy(enemy: Enemy, damage: float)
signal projectile_destroyed

func _ready():
    # Set up trail effect
    if trail:
        trail.clear_points()
        trail.add_point(global_position)
    
    # Auto-destroy after lifetime
    var destroy_timer = Timer.new()
    destroy_timer.wait_time = lifetime
    destroy_timer.one_shot = true
    destroy_timer.timeout.connect(_on_lifetime_expired)
    add_child(destroy_timer)
    destroy_timer.start()

func _physics_process(delta):
    if direction == Vector2.ZERO:
        return
    
    # Move projectile
    velocity = direction * speed
    move_and_slide()
    
    # Update trail
    if trail and trail.get_point_count() > 0:
        var last_point = trail.get_point_position(trail.get_point_count() - 1)
        if global_position.distance_to(last_point) > 10:
            trail.add_point(global_position)
            
            # Limit trail length
            if trail.get_point_count() > 20:
                trail.remove_point(0)
    
    # Check for collisions with enemies
    for i in get_slide_collision_count():
        var collision = get_slide_collision(i)
        var collider = collision.get_collider()
        
        if collider is Enemy:
            hit_target(collider)
            return

func set_direction(new_direction: Vector2):
    direction = new_direction.normalized()
    # Rotate sprite to face direction
    if sprite:
        sprite.rotation = direction.angle()

func set_damage(new_damage: float):
    damage = new_damage

func set_speed(new_speed: float):
    speed = new_speed

func hit_target(enemy: Enemy):
    if enemy and is_instance_valid(enemy):
        enemy.take_damage(damage)
        hit_enemy.emit(enemy, damage)
    destroy_projectile()

func destroy_projectile():
    projectile_destroyed.emit()
    queue_free()

func _on_lifetime_expired():
    destroy_projectile()
