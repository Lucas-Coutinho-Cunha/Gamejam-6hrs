class_name Player
extends CharacterBody2D

enum State { NORMAL, DASH }

@export_group("Movement")
@export var max_speed: float = 220.0
@export var acceleration: float = 1400.0
@export var friction: float = 900.0
@export var gravity: float = 1100.0
@export var jump_velocity: float = -380.0

@export_group("Bounce")
@export var bounce_velocity: float = -650.0

@export_group("Dash")
@export var dash_speed: float = 720.0
@export var dash_duration: float = 0.16
@export_range(0.0, 1.0) var dash_end_momentum: float = 0.35
@export var kills_per_dash: int = 3

@onready var attackbox: Area2D = $AttackBox

var state: State = State.NORMAL
var launched: bool = false
var has_dash: bool = true
var kills: int = 0
var facing: float = 1.0
var dash_dir: Vector2 = Vector2.RIGHT
var dash_time_left: float = 0.0


func _physics_process(delta: float) -> void:
	var input_x: float = Input.get_axis("left", "right")
	match state:
		State.NORMAL:
			_state_normal(delta, input_x)
		State.DASH:
			_state_dash(delta)
	_check_enemies()
 
 
func _state_normal(delta: float, input_x: float) -> void:
	if launched:
		if input_x != 0.0:
			facing = signf(input_x)
		if Input.is_action_just_pressed("dash") and has_dash:
			_start_dash(input_x)
			return
		var rate: float = acceleration if input_x != 0.0 else friction
		velocity.x = move_toward(velocity.x, input_x * max_speed, rate * delta)
	elif Input.is_action_just_pressed("bounce") and is_on_floor():
		velocity.y = jump_velocity * -100
		launched = true
	velocity.y += gravity * delta
	move_and_slide()
 
 
func _start_dash(input_x: float) -> void:
	dash_dir = Vector2(signf(input_x) if input_x != 0.0 else facing, 0.0)
	state = State.DASH
	dash_time_left = dash_duration
	has_dash = false
	velocity = dash_dir * dash_speed
 
 
func _state_dash(delta: float) -> void:
	dash_time_left -= delta
	velocity = dash_dir * dash_speed
	move_and_slide()
	if dash_time_left <= 0.0:
		state = State.NORMAL
		velocity = dash_dir * dash_speed * dash_end_momentum


func _check_enemies() -> void:
	for enemy: Node2D in attackbox.get_overlapping_areas():
		if not enemy.is_in_group("Enemy"):
			continue
		print("fuh")
		enemy.remove_from_group("Enemy")
		if enemy.has_method("die"):
			enemy.call("die")
		else:
			enemy.queue_free()
		
		if state == State.NORMAL:
			velocity.y = bounce_velocity * -100
		
		kills += 1
		if kills >= kills_per_dash:
			kills = 0
			has_dash = true
