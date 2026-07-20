extends CharacterBody2D
class_name Enemy

@export var speed: float = 90.0
@export var gravity: float = 1200.0
@export var max_health: int = 40
@export var contact_damage: int = 10
@export var aggro_range: float = 260.0
@export var knockback_speed: float = 260.0
@export var knockback_duration: float = 0.18
@export var knockback_resistant: bool = false

@onready var sprite: Polygon2D = $Sprite
@onready var hit_flash_timer: Timer = $HitFlashTimer
@onready var contact_area: Area2D = $ContactArea
@onready var contact_timer: Timer = $ContactTimer

var health: int
var player: Node2D = null
var base_color: Color
var knockback_time_left: float = 0.0
var knockback_velocity_x: float = 0.0

func _ready() -> void:
	health = max_health
	add_to_group("enemy")
	base_color = sprite.color
	hit_flash_timer.timeout.connect(func(): sprite.color = base_color)
	contact_timer.timeout.connect(_deal_contact_damage)
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0

	if knockback_time_left > 0.0:
		knockback_time_left -= delta
		velocity.x = knockback_velocity_x
	elif player and is_instance_valid(player):
		var to_player: Vector2 = player.global_position - global_position
		if absf(to_player.x) <= aggro_range:
			var dir := signf(to_player.x)
			velocity.x = dir * speed
			if dir != 0.0:
				sprite.scale.x = dir
		else:
			velocity.x = 0.0
	else:
		velocity.x = 0.0

	move_and_slide()

func _deal_contact_damage() -> void:
	for body in contact_area.get_overlapping_bodies():
		if body.is_in_group("player") and body.has_method("take_damage"):
			body.take_damage(contact_damage)

func take_damage(amount: int) -> void:
	health -= amount
	sprite.color = Color.WHITE
	hit_flash_timer.start(0.08)
	if not knockback_resistant and player and is_instance_valid(player):
		var dir := signf(global_position.x - player.global_position.x)
		if dir == 0.0:
			dir = 1.0
		knockback_velocity_x = dir * knockback_speed
		knockback_time_left = knockback_duration
	if health <= 0:
		die()

func die() -> void:
	queue_free()
