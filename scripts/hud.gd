extends CanvasLayer

@onready var health_bar: ProgressBar = $HealthBar
@onready var death_label: Label = $DeathLabel
@onready var boss_health_bar: ProgressBar = $BossHealthBar
@onready var boss_label: Label = $BossLabel
@onready var victory_label: Label = $VictoryLabel

func bind_player(player: Node) -> void:
	health_bar.max_value = player.max_health
	health_bar.value = player.health
	player.health_changed.connect(_on_health_changed)
	player.died.connect(_on_player_died)

func bind_boss(boss: Node, boss_name: String = "") -> void:
	boss_health_bar.max_value = boss.max_health
	boss_health_bar.value = boss.health
	boss_health_bar.visible = true
	boss_label.text = boss_name
	boss_label.visible = boss_name != ""
	boss.boss_health_changed.connect(_on_boss_health_changed)
	boss.boss_defeated.connect(_on_boss_defeated)

func _on_health_changed(current: int, max_health: int) -> void:
	health_bar.max_value = max_health
	health_bar.value = current

func _on_boss_health_changed(current: int, max_health: int) -> void:
	boss_health_bar.max_value = max_health
	boss_health_bar.value = current

func _on_boss_defeated() -> void:
	boss_health_bar.visible = false
	boss_label.visible = false
	victory_label.visible = true

func _on_player_died() -> void:
	death_label.visible = true
	await get_tree().create_timer(1.5).timeout
	get_tree().reload_current_scene()
