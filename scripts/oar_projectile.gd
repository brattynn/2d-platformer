extends Area2D
class_name OarProjectile

@export var speed: float = 340.0
@export var lifetime: float = 2.5

var direction: float = 1.0
var damage: int = 10

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(lifetime).timeout.connect(queue_free)

func setup(dir: float, dmg: int) -> void:
	direction = dir
	damage = dmg
	scale.x = dir

func _physics_process(delta: float) -> void:
	position.x += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()
