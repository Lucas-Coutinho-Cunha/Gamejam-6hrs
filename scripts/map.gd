class_name Map
extends Node2D
## Vertical scroller map: the camera only scrolls upward, and if the player
## falls too far below their highest point they lose and the level reloads.

signal player_lost

@export var player: Player
@export var camera: Camera2D
## How far (in pixels) below their highest point the player may fall.
@export var max_fall_distance: float = 600.0
## Seconds to wait before reloading (long enough to read the message).
@export var reload_delay: float = 2.5
@export var lose_text: String = "Hell claims you once more..."
## Optional: assign a bubbly/cartoony font for the lose text.
@export var lose_font: Font

var highest_y: float = 0.0
var lost: bool = false


func _ready() -> void:
	highest_y = player.global_position.y


func _physics_process(_delta: float) -> void:
	if lost:
		return # Camera stays frozen where the player was last.

	highest_y = minf(highest_y, player.global_position.y)

	# Camera scrolls up with the player, never down.
	camera.global_position.y = minf(camera.global_position.y, player.global_position.y)

	if player.global_position.y > highest_y + max_fall_distance:
		_lose()


func _lose() -> void:
	lost = true
	player_lost.emit()
	_show_lose_text()
	await get_tree().create_timer(reload_delay).timeout
	get_tree().reload_current_scene()


func _show_lose_text() -> void:
	var layer: CanvasLayer = CanvasLayer.new()
	add_child(layer)

	var settings: LabelSettings = LabelSettings.new()
	settings.font = lose_font
	settings.font_size = 72
	settings.font_color = Color("ffd23f")
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

	# Bouncy pop-in, then a gentle wobble.
	var pop: Tween = label.create_tween()
	pop.tween_property(label, "scale", Vector2.ONE, 0.6) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

	var wobble: Tween = label.create_tween().set_loops()
	wobble.tween_property(label, "rotation", 0.04, 0.5) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	wobble.tween_property(label, "rotation", -0.04, 0.5) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
