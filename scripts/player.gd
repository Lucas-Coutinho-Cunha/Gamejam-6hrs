class_name Player
extends CharacterBody2D

enum State { NORMAL, DASH, ATTACK }

@export_group("Movement")
@export var max_speed: float = 330.0
## Deceleration when no direction is held. High so stops are quick but not instant.
@export var friction: float = 8000.0

@export_group("Jump")
## Peak height of a jump, in pixels.
@export var jump_height: float = 400.0
## Seconds from takeoff to the peak.
@export var ascent_time: float = 0.4
## Seconds from the peak back down to takeoff height.
@export var descent_time: float = 0.3

@export_group("Bounce")
## Peak height of a pogo off a regular enemy, in pixels.
@export var bounce_height: float = 700.0
## Peak height of a pogo off an armored enemy (breaks the armor).
@export var mini_bounce_height: float = 250.0
## Sideways speed of a bounce off a diagonal attack. It keeps the dive's direction,
## so a down-right dive bounces up-right.
@export var bounce_horizontal_speed: float = 700.0
## Seconds after a diagonal bounce where held direction can't override its sideways momentum.
@export var bounce_control_lock: float = 0.25

# From h = v*t - g*t²/2 with the peak at t (v = g*t):
#   g = 2h / t²   and   v = 2h / t
var jump_velocity: float:
	get: return 2.0 * jump_height / ascent_time
var ascent_gravity: float:
	get: return 2.0 * jump_height / (ascent_time * ascent_time)
var descent_gravity: float:
	get: return 2.0 * jump_height / (descent_time * descent_time)

@export_group("Attack")
@export var attack_cooldown: float = 0.3
## The attack is a short committed dive: straight down, or 45° down if strafing.
@export var attack_dash_speed: float = 900.0
@export var attack_dash_duration: float = 0.1
## Fraction of the dive speed kept when the dive ends without a hit.
@export_range(0.0, 1.0) var attack_dash_end_momentum: float = 0.5

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
@onready var swipe: Polygon2D = $AttackBox/Swipe
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
var attack_dir: Vector2 = Vector2.DOWN
var attack_time_left: float = 0.0
var attack_landed: bool = false
var bounce_lock_left: float = 0.0
var ghost: Sprite2D
var swipe_tween: Tween


func _ready() -> void:
	ghost = sprite.duplicate() as Sprite2D
	add_child(ghost)
	swipe.modulate.a = 0.0


func _physics_process(delta: float) -> void:
	print(global_position.y)
	attack_cooldown_left = maxf(attack_cooldown_left - delta, 0.0)
	bounce_lock_left = maxf(bounce_lock_left - delta, 0.0)
	var input_x: float = Input.get_axis("left", "right")
	
	match state:
		State.NORMAL:
			_state_normal(delta, input_x)
		State.DASH:
			_state_dash(delta)
		State.ATTACK:
			_state_attack(delta)
	
	_wrap_around()
	


func _state_normal(delta: float, input_x: float) -> void:
	if launched:
		if input_x != 0.0:
			facing = signf(input_x)
		if Input.is_action_just_pressed("dash") and has_dash:
			_start_dash(input_x)
			return
		if Input.is_action_just_pressed("attack") and attack_cooldown_left <= 0.0:
			_start_attack(input_x)
			return
		if bounce_lock_left <= 0.0:
			if input_x != 0.0:
				velocity.x = input_x * max_speed
			else:
				velocity.x = move_toward(velocity.x, 0.0, friction * delta)
	elif Input.is_action_just_pressed("bounce") and is_on_floor():
		velocity.y = -jump_velocity
		launched = true
		valkyries.play()
		jump.play()
	
	velocity.y += (ascent_gravity if velocity.y < 0.0 else descent_gravity) * delta
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


func _start_attack(input_x: float) -> void:
	state = State.ATTACK
	attack_cooldown_left = attack_cooldown
	attack_time_left = attack_dash_duration
	attack_landed = false
	bounce_lock_left = 0.0
	attack_dir = Vector2(signf(input_x), 1.0).normalized()
	attack_box.rotation = attack_dir.angle() - PI / 2.0
	attack.play()
	_play_swipe()


# Committed dive: ignores all input until it ends or connects.
func _state_attack(delta: float) -> void:
	attack_time_left -= delta
	velocity = attack_dir * attack_dash_speed
	move_and_slide()

	if not attack_landed:
		for area in attack_box.get_overlapping_areas():
			var enemy: Enemy = area as Enemy
			if enemy != null and not enemy.is_dead:
				_hit_enemy(enemy)
				return

	if attack_time_left <= 0.0 or is_on_floor():
		state = State.NORMAL
		velocity = attack_dir * attack_dash_speed * attack_dash_end_momentum


func _hit_enemy(enemy: Enemy) -> void:
	attack_landed = true
	if enemy.type == 0:
		enemy.die()
		kill.play()
		_bounce(bounce_height)
	elif enemy.type == 1:
		enemy.lose_armor()
		_bounce(mini_bounce_height)

	kills += 1
	if kills >= kills_per_dash:
		kills = 0
		has_dash = true


# Reflect the dive off the enemy: up to the given height, keeping its sideways direction.
func _bounce(height: float) -> void:
	state = State.NORMAL
	velocity = Vector2(signf(attack_dir.x) * bounce_horizontal_speed, -_bounce_speed(height))
	if attack_dir.x != 0.0:
		bounce_lock_left = bounce_control_lock


# Same physics as the jump: launch speed that peaks at the given height.
func _bounce_speed(height: float) -> float:
	return sqrt(2.0 * ascent_gravity * height)


func _play_swipe() -> void:
	if swipe_tween:
		swipe_tween.kill()
	swipe.modulate.a = 1.0
	swipe_tween = create_tween()
	swipe_tween.tween_property(swipe, "modulate:a", 0.0, 0.15)


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
