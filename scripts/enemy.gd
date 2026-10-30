class_name Enemy extends Node

@export var deals_damage_on_contact: bool = false

@export_enum("Regular", "Spiky", "Armor") var type: int
@export var is_angel: bool

var player: Player
var is_alive: bool = true

func attack() -> void:
	pass


func die() -> void:
	print("YEOWCH")
