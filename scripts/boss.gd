extends Enemy
class_name Boss

signal boss_health_changed(current: int, max_health: int)
signal boss_defeated

enum State { CHASE, TELEGRAPH, ATTACK, RECOVER }

@export var telegraph_duration: float = 0.4
@export var recover_duration: float = 0.5
@export var attack_range: float = 90.0

var state: State = State.CHASE
var state_timer: float = 0.0
var pending_attack: String = ""

func _ready() -> void:
	super._ready()
	knockback_resistant = true

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0

	match state:
		State.CHASE:
			_process_chase()
		State.TELEGRAPH:
			velocity.x = 0.0
			state_timer -= delta
			if state_timer <= 0.0:
				_enter_attack()
		State.ATTACK:
			velocity.x = 0.0
			state_timer -= delta
			if state_timer <= 0.0:
				_enter_recover()
		State.RECOVER:
			velocity.x = 0.0
			state_timer -= delta
			if state_timer <= 0.0:
				state = State.CHASE

	move_and_slide()

func _process_chase() -> void:
	if player and is_instance_valid(player):
		var to_player: Vector2 = player.global_position - global_position
		if absf(to_player.x) <= attack_range:
			_enter_telegraph()
		elif absf(to_player.x) <= aggro_range:
			var dir := signf(to_player.x)
			velocity.x = dir * speed
			if dir != 0.0:
				sprite.scale.x = dir
		else:
			velocity.x = 0.0
	else:
		velocity.x = 0.0

func _enter_telegraph() -> void:
	state = State.TELEGRAPH
	state_timer = telegraph_duration
	pending_attack = _choose_attack()
	_on_telegraph_start(pending_attack)

func _enter_attack() -> void:
	state = State.ATTACK
	state_timer = _perform_attack(pending_attack)

func _enter_recover() -> void:
	state = State.RECOVER
	state_timer = recover_duration

# Override in subclasses.
func _choose_attack() -> String:
	return "default"

func _on_telegraph_start(_attack_name: String) -> void:
	pass

# Override in subclasses; return the attack's active duration.
func _perform_attack(_attack_name: String) -> float:
	return 0.2

func take_damage(amount: int) -> void:
	super.take_damage(amount)
	boss_health_changed.emit(health, max_health)

func die() -> void:
	boss_defeated.emit()
	super.die()
