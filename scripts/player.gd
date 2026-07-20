extends CharacterBody2D
class_name Player

@export var speed: float = 220.0
@export var jump_velocity: float = -420.0
@export var gravity: float = 1200.0
@export var jump_cut_multiplier: float = 0.45
@export var max_health: int = 100
@export var attack_damage: int = 20
@export var attack_offset: float = 30.0
@export var dodge_speed: float = 480.0
@export var dodge_duration: float = 0.2
@export var dodge_cooldown: float = 0.5
@export var attack_duration: float = 0.18
@export var attack_cooldown: float = 0.35

@onready var sprite: Polygon2D = $Sprite
@onready var attack_area: Area2D = $AttackArea
@onready var attack_shape: CollisionShape2D = $AttackArea/CollisionShape2D
@onready var attack_sprite: Polygon2D = $AttackArea/AttackSprite
@onready var attack_duration_timer: Timer = $AttackDurationTimer
@onready var attack_cooldown_timer: Timer = $AttackCooldownTimer
@onready var dodge_duration_timer: Timer = $DodgeDurationTimer
@onready var dodge_cooldown_timer: Timer = $DodgeCooldownTimer

var health: int
var facing: int = 1
var is_attacking: bool = false
var is_dodging: bool = false
var can_attack: bool = true
var can_dodge: bool = true
var is_invulnerable: bool = false
var already_hit: Array = []

signal health_changed(current: int, max_health: int)
signal died

func _ready() -> void:
	health = max_health
	attack_shape.disabled = true
	add_to_group("player")
	attack_area.body_entered.connect(_on_attack_area_body_entered)
	attack_duration_timer.timeout.connect(_end_attack)
	attack_cooldown_timer.timeout.connect(func(): can_attack = true)
	dodge_duration_timer.timeout.connect(_end_dodge)
	dodge_cooldown_timer.timeout.connect(func(): can_dodge = true)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0

	var direction := Input.get_axis("move_left", "move_right")

	if direction != 0 and not is_dodging:
		facing = int(sign(direction))
		sprite.scale.x = facing

	attack_area.position.x = attack_offset * facing

	if is_dodging:
		velocity.x = dodge_speed * facing
	elif is_attacking:
		velocity.x = move_toward(velocity.x, 0, speed * 4 * delta)
	else:
		velocity.x = direction * speed

	if Input.is_action_just_pressed("jump") and is_on_floor() and not is_dodging:
		velocity.y = jump_velocity

	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= jump_cut_multiplier

	if Input.is_action_just_pressed("attack") and can_attack and not is_dodging:
		_start_attack()

	if Input.is_action_just_pressed("dodge") and can_dodge and not is_attacking:
		_start_dodge()

	move_and_slide()

func _start_attack() -> void:
	is_attacking = true
	can_attack = false
	already_hit.clear()
	attack_shape.disabled = false
	attack_sprite.visible = true
	attack_duration_timer.start(attack_duration)
	attack_cooldown_timer.start(attack_cooldown)

func _end_attack() -> void:
	is_attacking = false
	attack_shape.disabled = true
	attack_sprite.visible = false

func _start_dodge() -> void:
	is_dodging = true
	can_dodge = false
	is_invulnerable = true
	dodge_duration_timer.start(dodge_duration)
	dodge_cooldown_timer.start(dodge_cooldown)

func _end_dodge() -> void:
	is_dodging = false
	is_invulnerable = false

func _on_attack_area_body_entered(body: Node2D) -> void:
	if body in already_hit:
		return
	if body.is_in_group("enemy") and body.has_method("take_damage"):
		body.take_damage(attack_damage)
		already_hit.append(body)

func take_damage(amount: int) -> void:
	if is_invulnerable:
		return
	health -= amount
	health_changed.emit(health, max_health)
	if health <= 0:
		die()

func die() -> void:
	died.emit()
	set_physics_process(false)
	queue_free()
