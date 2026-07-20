extends Node2D

@onready var player: Player = $Player
@onready var hud: CanvasLayer = $HUD
@onready var charon: Charon = $Charon
@onready var arena_trigger: Area2D = $ArenaTrigger
@onready var gate_shape: CollisionShape2D = $ArenaGate/CollisionShape2D

func _ready() -> void:
	hud.bind_player(player)
	arena_trigger.body_entered.connect(_on_arena_trigger_body_entered)
	charon.boss_defeated.connect(_on_charon_defeated)

func _on_arena_trigger_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		gate_shape.set_deferred("disabled", false)
		arena_trigger.set_deferred("monitoring", false)
		hud.bind_boss(charon, "Charon")

func _on_charon_defeated() -> void:
	gate_shape.set_deferred("disabled", true)
