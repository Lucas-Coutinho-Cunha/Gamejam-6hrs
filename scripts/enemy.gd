class_name Enemy extends Area2D

@export var deals_damage_on_contact: bool = false

@export_enum("Regular", "Armor", "Spiky", "Clawed", "Slimy") var type: int
@export var is_angel: bool

@onready var wing_l: Sprite2D = $Node2D/WingL
@onready var wing_r: Sprite2D = $Node2D/WingR
@onready var body: Sprite2D = $Node2D/Body
@onready var helmet: Sprite2D = $Node2D/Helmet
@onready var spikes: Sprite2D = $Node2D/Spikes
@onready var claws: Sprite2D = $Node2D/Claws


var globalpos: Vector2
var is_dead: bool = false

func _ready() -> void:
	globalpos = global_position
	match type:
		0: helmet.visible = false; spikes.visible = false;
		1: helmet.visible = true; spikes.visible = false;
		2: helmet.visible = true; spikes.visible = true;
		3: helmet.visible = false; spikes.visible = false;
		4: helmet.visible = false; spikes.visible = false;

func _process(_delta: float) -> void:
	position.y += sin(Time.get_ticks_msec() * 0.01)
	wing_l.rotation = (sin(Time.get_ticks_msec()*0.01)* 0.5)
	wing_r.rotation = (-sin(Time.get_ticks_msec()*0.01)* 0.5)
	if is_dead:
		rotation += 0.2
		scale -= Vector2(0.01, 0.01)
		if rotation > 20:
			queue_free()

func die() -> void:
	is_dead = true

func lose_armor() -> void:
	type = 0
