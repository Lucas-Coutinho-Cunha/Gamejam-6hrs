class_name Map
extends Node2D

@onready var died: AudioStreamPlayer = $Died

signal player_lost

@export var player: Player
@export var camera: Camera2D
@export var max_fall_distance: float = 600.0
@export var reload_delay: float = 2.5
@export var lose_text: String = "Hell claims you once more..."
@export var lose_font: Font

@export var background: ColorRect

@export var map_height: float = 20000.0
@export var enemy_spacing: float = 250.0
@export var spacing_jitter: float = 60.0
@export var spawn_min_x: float = 120.0
@export var spawn_max_x: float = 600.0
@export var first_enemy_offset: float = 300.0

var enemy_scene: PackedScene = preload("res://scenes/enemy.tscn")

var highest_y: float = 0.0
var lost: bool = false
var start_y: float = 0.0


func _ready() -> void:
	highest_y = player.global_position.y
	_spawn_enemies()
	start_y = player.global_position.y


func _spawn_enemies() -> void:
	var y: float = player.global_position.y - first_enemy_offset
	var end_y: float = player.global_position.y - map_height

	while y > end_y:
		var enemy: Node2D = enemy_scene.instantiate() as Node2D
		add_child(enemy)
		enemy.global_position = Vector2(
			randf_range(spawn_min_x, spawn_max_x),
			y + randf_range(-spacing_jitter, spacing_jitter)
		)
		y -= enemy_spacing


func _physics_process(_delta: float) -> void:
	if lost:
		return
	highest_y = minf(highest_y, player.global_position.y)
	var progress: float = clampf((start_y - highest_y) / map_height, 0.0, 1.0)
	(background.material as ShaderMaterial).set_shader_parameter("progress", progress)
	
	camera.global_position.y = minf(camera.global_position.y, player.global_position.y)
	if player.global_position.y > highest_y + max_fall_distance:
		_lose()


func _lose() -> void:
	lost = true
	died.play()
	player_lost.emit()
	_show_lose_text()
	await get_tree().create_timer(reload_delay).timeout
	get_tree().reload_current_scene()


func _show_lose_text() -> void:
	var layer: CanvasLayer = CanvasLayer.new()
	add_child(layer)

	var settings: LabelSettings = LabelSettings.new()
	settings.font = lose_font
	settings.font_size = 128
	settings.font_color = Color("ff453fff")
	settings.outline_size = 28
	settings.outline_color = Color("7a1b1b")
	settings.shadow_size = 10
	settings.shadow_color = Color(0.0, 0.0, 0.0, 0.5)
	settings.shadow_offset = Vector2(0.0, 8.0)

	var label: Label = Label.new()
	label.text = lose_text
	label.label_settings = settings
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layer.add_child(label)
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.pivot_offset = get_viewport().get_visible_rect().size / 2.0
	label.scale = Vector2.ZERO

	var pop: Tween = label.create_tween()
	pop.tween_property(label, "scale", Vector2.ONE, 0.6) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

	var wobble: Tween = label.create_tween().set_loops()
	wobble.tween_property(label, "rotation", 0.04, 0.8) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	wobble.tween_property(label, "rotation", -0.04, 0.8) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
