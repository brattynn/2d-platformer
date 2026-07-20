extends Node2D

@export var doubt_fill_rate: float = 0.35
@export var doubt_drain_rate: float = 0.15

@onready var player: Player = $Player
@onready var eurydice: Eurydice = $Eurydice
@onready var hud: CanvasLayer = $HUD
@onready var level_exit: Area2D = $LevelExit

var doubt: float = 0.0
var escort_lost: bool = false
var level_won: bool = false
var player_at_exit: bool = false
var escort_at_exit: bool = false

func _ready() -> void:
	hud.bind_player(player)
	hud.bind_escort(eurydice)
	eurydice.lost.connect(_on_eurydice_lost)
	level_exit.body_entered.connect(_on_level_exit_body_entered)

func _process(delta: float) -> void:
	if escort_lost or level_won:
		return

	var looking := false
	if is_instance_valid(eurydice):
		var dir_to_eurydice := signf(eurydice.global_position.x - player.global_position.x)
		if dir_to_eurydice < 0.0 and Input.is_action_pressed("move_left"):
			looking = true
		elif dir_to_eurydice > 0.0 and Input.is_action_pressed("move_right"):
			looking = true

	player.external_speed_multiplier = 0.5 if looking else 1.0
	player.attack_locked = looking

	doubt = clampf(doubt + (doubt_fill_rate if looking else -doubt_drain_rate) * delta, 0.0, 1.0)
	hud.update_doubt(doubt, looking)
	if doubt >= 1.0:
		_on_eurydice_lost()

func _on_eurydice_lost() -> void:
	if escort_lost:
		return
	escort_lost = true
	if is_instance_valid(eurydice):
		eurydice.queue_free()
	hud.show_escort_loss()
	await get_tree().create_timer(2.0).timeout
	get_tree().reload_current_scene()

func _on_level_exit_body_entered(body: Node2D) -> void:
	if level_won or escort_lost:
		return
	if body.is_in_group("player"):
		player_at_exit = true
	elif body.is_in_group("escort"):
		escort_at_exit = true
	if player_at_exit and escort_at_exit:
		level_won = true
		hud.show_message("You reached the surface, together.")
