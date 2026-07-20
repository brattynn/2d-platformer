extends CanvasLayer

@onready var health_bar: ProgressBar = $HealthBar
@onready var death_label: Label = $DeathLabel
@onready var boss_health_bar: ProgressBar = $BossHealthBar
@onready var boss_label: Label = $BossLabel
@onready var victory_label: Label = $VictoryLabel
@onready var escort_health_bar: ProgressBar = $EscortHealthBar
@onready var doubt_bar: ProgressBar = $DoubtBar
@onready var escort_lost_label: Label = $EscortLostLabel

func bind_player(player: Node) -> void:
	health_bar.max_value = player.max_health
	health_bar.value = player.health
	player.health_changed.connect(_on_health_changed)
	player.died.connect(_on_player_died)

var _current_boss_name: String = ""

func bind_boss(boss: Node, boss_name: String = "") -> void:
	boss_health_bar.max_value = boss.max_health
	boss_health_bar.value = boss.health
	boss_health_bar.visible = true
	boss_label.text = boss_name
	boss_label.visible = boss_name != ""
	_current_boss_name = boss_name
	boss.boss_health_changed.connect(_on_boss_health_changed)
	boss.boss_defeated.connect(_on_boss_defeated)

func bind_escort(escort: Node) -> void:
	escort_health_bar.max_value = escort.max_health
	escort_health_bar.value = escort.health
	escort_health_bar.visible = true
	doubt_bar.visible = true
	escort.health_changed.connect(_on_escort_health_changed)

func update_doubt(doubt: float, looking: bool) -> void:
	doubt_bar.value = doubt * 100.0
	doubt_bar.modulate = Color(1, 0.55, 0.55) if looking else Color(1, 1, 1)

func show_escort_loss() -> void:
	escort_health_bar.visible = false
	doubt_bar.visible = false
	escort_lost_label.visible = true

func show_message(text: String) -> void:
	victory_label.text = text
	victory_label.visible = true

func _on_health_changed(current: int, max_health: int) -> void:
	health_bar.max_value = max_health
	health_bar.value = current

func _on_escort_health_changed(current: int, max_health: int) -> void:
	escort_health_bar.max_value = max_health
	escort_health_bar.value = current

func _on_boss_health_changed(current: int, max_health: int) -> void:
	boss_health_bar.max_value = max_health
	boss_health_bar.value = current

func _on_boss_defeated() -> void:
	boss_health_bar.visible = false
	boss_label.visible = false
	victory_label.text = "%s defeated!" % _current_boss_name if _current_boss_name != "" else "Boss defeated!"
	victory_label.visible = true

func _on_player_died() -> void:
	death_label.visible = true
	await get_tree().create_timer(1.5).timeout
	get_tree().reload_current_scene()
