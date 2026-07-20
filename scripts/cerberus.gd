extends Boss
class_name Cerberus

@export var bite_range: float = 110.0
@export var lunge_range: float = 340.0
@export var stomp_range: float = 80.0
@export var bite_damage: int = 14
@export var lunge_damage: int = 18
@export var lunge_speed: float = 600.0
@export var stomp_damage: int = 20
@export var phase2_health_ratio: float = 0.66
@export var phase3_health_ratio: float = 0.33

@onready var bite_area: Area2D = $BiteArea
@onready var bite_shape: CollisionShape2D = $BiteArea/CollisionShape2D
@onready var bite_sprite: Polygon2D = $BiteArea/BiteSprite
@onready var lunge_area: Area2D = $LungeArea
@onready var lunge_shape: CollisionShape2D = $LungeArea/CollisionShape2D
@onready var lunge_sprite: Polygon2D = $LungeArea/LungeSprite
@onready var stomp_area: Area2D = $StompArea
@onready var stomp_shape: CollisionShape2D = $StompArea/CollisionShape2D
@onready var stomp_sprite: Polygon2D = $StompArea/StompSprite

var phase: int = 1
var lunge_direction: float = 1.0
var hit_this_attack: Array = []

func _ready() -> void:
	super._ready()
	bite_shape.disabled = true
	lunge_shape.disabled = true
	stomp_shape.disabled = true
	bite_area.body_entered.connect(_on_attack_body_entered.bind(bite_damage, "bite"))
	lunge_area.body_entered.connect(_on_attack_body_entered.bind(lunge_damage, "lunge"))
	stomp_area.body_entered.connect(_on_attack_body_entered.bind(stomp_damage, "stomp"))

func _choose_attack() -> String:
	if not player or not is_instance_valid(player):
		return "bite"
	var dist := absf(player.global_position.x - global_position.x)
	if phase >= 3 and dist <= stomp_range:
		return "stomp"
	if dist <= bite_range:
		return "bite"
	return "lunge"

func _on_telegraph_start(attack_name: String) -> void:
	match attack_name:
		"bite":
			sprite.color = Color(1.0, 0.4, 0.1)
		"lunge":
			sprite.color = Color(0.7, 0.2, 0.9)
			# Anticipation crouch: squash back before the dash releases forward.
			var facing_sign := signf(sprite.scale.x) if sprite.scale.x != 0.0 else 1.0
			var tween := create_tween()
			tween.tween_property(sprite, "scale", Vector2(0.7 * facing_sign, 1.25), telegraph_duration * 0.8)
		"stomp":
			sprite.color = Color(1.0, 0.9, 0.9)

func _perform_attack(attack_name: String) -> float:
	sprite.color = base_color
	hit_this_attack.clear()
	match attack_name:
		"bite":
			_do_bite()
			return 0.2
		"lunge":
			_start_lunge()
			return 0.35
		"stomp":
			_do_stomp()
			return 0.25
	return 0.2

func _process_attack(_delta: float) -> void:
	if pending_attack == "lunge":
		velocity.x = lunge_direction * lunge_speed
	else:
		velocity.x = 0.0

func _do_bite() -> void:
	var facing := sprite.scale.x if sprite.scale.x != 0.0 else 1.0
	bite_area.position.x = bite_range * 0.5 * signf(facing)
	bite_shape.disabled = false
	bite_sprite.visible = true
	get_tree().create_timer(0.15).timeout.connect(func():
		bite_shape.disabled = true
		bite_sprite.visible = false
	)

func _start_lunge() -> void:
	if player and is_instance_valid(player):
		lunge_direction = signf(player.global_position.x - global_position.x)
	else:
		lunge_direction = sprite.scale.x if sprite.scale.x != 0.0 else 1.0
	# Ignore the player's physical body during the dash so standing close
	# doesn't stop the movement dead on contact before it can play out.
	set_collision_mask_value(2, false)
	lunge_shape.disabled = false
	lunge_sprite.visible = true
	sprite.scale = Vector2(1.5 * lunge_direction, 0.75)
	var tween := create_tween()
	tween.tween_property(sprite, "scale", Vector2(lunge_direction, 1.0), 0.35)
	get_tree().create_timer(0.35).timeout.connect(func():
		lunge_shape.disabled = true
		lunge_sprite.visible = false
		set_collision_mask_value(2, true)
	)

func _do_stomp() -> void:
	stomp_shape.disabled = false
	stomp_sprite.visible = true
	stomp_sprite.scale = Vector2(0.3, 0.3)
	var tween := create_tween()
	tween.tween_property(stomp_sprite, "scale", Vector2.ONE, 0.2)
	get_tree().create_timer(0.2).timeout.connect(func():
		stomp_shape.disabled = true
		stomp_sprite.visible = false
		stomp_sprite.scale = Vector2.ONE
	)

func _on_attack_body_entered(body: Node2D, damage: int, attack_name: String) -> void:
	if body in hit_this_attack:
		return
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage)
		if attack_name == "stomp" and body.has_method("apply_knockback"):
			var dir := signf(body.global_position.x - global_position.x)
			if dir == 0.0:
				dir = 1.0
			body.apply_knockback(dir, 380.0)
		hit_this_attack.append(body)

func take_damage(amount: int) -> void:
	super.take_damage(amount)
	_update_phase()

func _update_phase() -> void:
	var ratio := float(health) / float(max_health)
	if phase < 3 and ratio <= phase3_health_ratio:
		_enter_phase(3)
	elif phase < 2 and ratio <= phase2_health_ratio:
		_enter_phase(2)

func _enter_phase(new_phase: int) -> void:
	phase = new_phase
	if phase == 2:
		attack_range = lunge_range
	elif phase == 3:
		attack_range = lunge_range
		speed *= 1.3
		telegraph_duration *= 0.7
		recover_duration *= 0.7
		sprite.color = Color(0.5, 0.05, 0.05)
		base_color = sprite.color
