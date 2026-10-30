class_name Enemy extends Area2D

@export var deals_damage_on_contact: bool = false

@export_enum("Regular", "Spiky", "Armor") var type: int
@export var is_angel: bool

var is_dead: bool = false

func _process(_delta: float) -> void:
	if is_dead:
		rotation += 0.2
		scale -= Vector2(0.01, 0.01)
		if rotation > 20:
			queue_free()

func die() -> void:
	is_dead = true
