extends Boss
class_name Charon

@export var pole_range: float = 90.0
@export var pole_damage: int = 15
@export var oar_damage: int = 12
@export var projectile_scene: PackedScene = preload("res://scenes/entities/OarProjectile.tscn")

@onready var pole_area: Area2D = $PoleArea
@onready var pole_shape: CollisionShape2D = $PoleArea/CollisionShape2D
@onready var pole_sprite: Polygon2D = $PoleArea/PoleSprite

var pole_already_hit: Array = []

func _ready() -> void:
	super._ready()
	pole_shape.disabled = true
	pole_area.body_entered.connect(_on_pole_area_body_entered)

func _choose_attack() -> String:
	if player and is_instance_valid(player):
		var dist := absf(player.global_position.x - global_position.x)
		if dist <= pole_range:
			return "pole"
	return "oar"

func _on_telegraph_start(attack_name: String) -> void:
	if attack_name == "pole":
		sprite.color = Color(1.0, 0.85, 0.3)
	else:
		sprite.color = Color(0.6, 0.8, 1.0)

func _perform_attack(attack_name: String) -> float:
	sprite.color = base_color
	if attack_name == "pole":
		_do_pole_sweep()
		return 0.2
	else:
		_do_oar_throw()
		return 0.15

func _do_pole_sweep() -> void:
	pole_already_hit.clear()
	var facing := sprite.scale.x if sprite.scale.x != 0.0 else 1.0
	pole_area.position.x = pole_range * 0.5 * signf(facing)
	pole_shape.disabled = false
	pole_sprite.visible = true
	get_tree().create_timer(0.15).timeout.connect(func():
		pole_shape.disabled = true
		pole_sprite.visible = false
	)

func _do_oar_throw() -> void:
	if not player or not is_instance_valid(player):
		return
	var proj: OarProjectile = projectile_scene.instantiate()
	get_parent().add_child(proj)
	proj.global_position = global_position
	var dir := signf(player.global_position.x - global_position.x)
	proj.setup(dir, oar_damage)

func _on_pole_area_body_entered(body: Node2D) -> void:
	if body in pole_already_hit:
		return
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(pole_damage)
		pole_already_hit.append(body)
