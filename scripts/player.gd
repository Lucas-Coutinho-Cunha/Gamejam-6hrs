class_name Player
extends CharacterBody2D

enum State { NORMAL, DASH }

@export_group("Movement")
@export var max_speed: float = 330.0
@export var acceleration: float = 1400.0
@export var friction: float = 900.0
@export var gravity: float = 1100.0
@export var jump_velocity: float = 15

@export_group("Bounce")
@export var bounce_velocity: float = 10
@export var mini_bounce_velocity: float = 1

@export_group("Attack")
@export var attack_cooldown: float = 0.3

@export_group("Wrap")
@export var wrap_left: float = 0.0
@export var wrap_right: float = 1152.0

@export_group("Dash")
@export var dash_speed: float = 720.0
@export var dash_duration: float = 0.16
@export_range(0.0, 1.0) var dash_end_momentum: float = 0.35
@export var kills_per_dash: int = 3

@onready var sprite: Sprite2D = $Sprite2D
@onready var attack_box: Area2D = $AttackBox
@onready var attack: AudioStreamPlayer = $Attack
@onready var jump: AudioStreamPlayer = $Jump
@onready var kill: AudioStreamPlayer = $Kill
@onready var valkyries: AudioStreamPlayer = $RideOfTheValkyries

var state: State = State.NORMAL
var launched: bool = false
var has_dash: bool = true
var kills: int = 0
var facing: float = 1.0
var dash_dir: Vector2 = Vector2.RIGHT
var dash_time_left: float = 0.0
var attack_cooldown_left: float = 0.0
var ghost: Sprite2D


func _ready() -> void:
	ghost = sprite.duplicate() as Sprite2D
	add_child(ghost)


func _physics_process(delta: float) -> void:
	print(global_position.y)
	attack_cooldown_left = maxf(attack_cooldown_left - delta, 0.0)
	var input_x: float = Input.get_axis("left", "right")
	
	match state:
		State.NORMAL:
			_state_normal(delta, input_x)
		State.DASH:
			_state_dash(delta)
	
	_wrap_around()
	


func _state_normal(delta: float, input_x: float) -> void:
	if launched:
		if input_x != 0.0:
			facing = signf(input_x)
		if Input.is_action_just_pressed("dash") and has_dash:
			_start_dash(input_x)
			return
		_try_attack()
		var rate: float = acceleration if input_x != 0.0 else friction
		velocity.x = move_toward(velocity.x, input_x * max_speed, rate * delta)
	elif Input.is_action_just_pressed("bounce") and is_on_floor():
		velocity.y = jump_velocity * -100
		launched = true
		valkyries.play()
		jump.play()
	
	velocity.y += gravity * delta
	move_and_slide()


func _wrap_around() -> void:
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera == null:
		return

	var half_width: float = get_viewport_rect().size.x / camera.zoom.x / 2.0
	var center_x: float = camera.get_screen_center_position().x
	var left: float = center_x - half_width
	var right: float = center_x + half_width
	var width: float = right - left

	if global_position.x < left:
		global_position.x += width
	elif global_position.x > right:
		global_position.x -= width

	var near_left: bool = global_position.x < left + width / 2.0
	ghost.position = sprite.position + Vector2(width if near_left else -width, 0.0)
	ghost.flip_h = sprite.flip_h
	ghost.frame = sprite.frame


func _try_attack() -> void:
	if not Input.is_action_just_pressed("attack") or attack_cooldown_left > 0.0:
		return
	attack_cooldown_left = attack_cooldown
	attack.play()
	if velocity.y < 200:
		velocity.y = 200
	
	var areas: Array[Area2D] = attack_box.get_overlapping_areas()
	if areas.is_empty():
		return
	var enemy: Enemy = areas[0] as Enemy
	if enemy == null:
		return
	if enemy.type == 0:
		enemy.die()
		kill.play()
		velocity.y = bounce_velocity * -100
	elif enemy.type == 1:
		enemy.lose_armor()
		velocity.y = mini_bounce_velocity * -100
	
	
	kills += 1
	if kills >= kills_per_dash:
		kills = 0
		has_dash = true


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
