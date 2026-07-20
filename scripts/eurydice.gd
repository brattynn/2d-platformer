extends CharacterBody2D
class_name Eurydice

@export var speed: float = 160.0
@export var gravity: float = 1200.0
@export var max_health: int = 60
@export var follow_delay: float = 0.7
@export var arrive_threshold: float = 6.0

@onready var sprite: Polygon2D = $Sprite
@onready var hit_flash_timer: Timer = $HitFlashTimer

var health: int
var base_color: Color
var target: Node2D = null
var trail: Array = []

signal health_changed(current: int, max_health: int)
signal lost

func _ready() -> void:
	health = max_health
	add_to_group("escort")
	base_color = sprite.color
	hit_flash_timer.timeout.connect(func(): sprite.color = base_color)
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target = players[0]

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0

	if target and is_instance_valid(target):
		var now := Time.get_ticks_msec() / 1000.0
		trail.append({"pos": target.global_position, "t": now})
		while trail.size() > 1 and now - trail[0]["t"] > follow_delay + 1.0:
			trail.pop_front()

		var goal: Vector2 = trail[0]["pos"]
		for entry in trail:
			if now - entry["t"] >= follow_delay:
				goal = entry["pos"]
			else:
				break

		var dx := goal.x - global_position.x
		if absf(dx) > arrive_threshold:
			var dir := signf(dx)
			velocity.x = dir * speed
			sprite.scale.x = dir
		else:
			velocity.x = 0.0
	else:
		velocity.x = 0.0

	move_and_slide()

func take_damage(amount: int) -> void:
	health -= amount
	sprite.color = Color.WHITE
	hit_flash_timer.start(0.08)
	health_changed.emit(health, max_health)
	if health <= 0:
		lost.emit()
		queue_free()
