class_name Enemy extends Area2D

@export var deals_damage_on_contact: bool = false

@export_enum("Regular", "Armor", "Spiky", "Clawed", "Slimy") var type: int
@export var is_angel: bool
@onready var helmet: Sprite2D = $Helmet
@onready var spikes: Sprite2D = $Spikes
@onready var wing_l: Sprite2D = $WingL
@onready var wing_r: Sprite2D = $WingR

var is_dead: bool = false

func _ready() -> void:
	match type:
		0: helmet.visible = false; spikes.visible = false;
		1: helmet.visible = true; spikes.visible = false;
		2: helmet.visible = true; spikes.visible = true;
		3: helmet.visible = false; spikes.visible = false;
		4: helmet.visible = false; spikes.visible = false;

func _process(_delta: float) -> void:
	wing_l.rotate(sin(Time.get_ticks_msec()*0.0001)* 0.5)
	wing_r.rotate(-sin(Time.get_ticks_msec()*0.0001)* 0.5)
	if is_dead:
		rotation += 0.2
		scale -= Vector2(0.01, 0.01)
		if rotation > 20:
			queue_free()

func die() -> void:
	is_dead = true

func lose_armor() -> void:
	type = 0
