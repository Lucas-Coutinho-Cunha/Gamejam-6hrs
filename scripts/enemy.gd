class_name Enemy extends Area2D

@export var deals_damage_on_contact: bool = false

@export_enum("Regular", "Spiky", "Armor") var type: int
@export var is_angel: bool

var player: Player
var is_alive: bool = true


func _process(delta: float) -> void:
	if not is_alive:
		rotation += 0.2
		scale -= Vector2(0.01, 0.01)
		if rotation > 20:
			queue_free()


func attack() -> void:
	pass


func die() -> void:
	is_alive = false
