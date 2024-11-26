#Zombie script

extends CharacterBody2D
class_name Zombie

@onready var animated_sprite_2D = $AnimatedSprite2D
@onready var animation_player = $AnimationPlayer
@onready var navigation_agent_2D : NavigationAgent2D = $NavigationAgent2D
@onready var collision_shape_2D = $CollisionShape2D

var main_path
var main_scene
var player_path
var player
var ground_path
var ground
var walls_path
var walls

var map_ready
var player_exists = true

var health = 100
@export var healths = [20, 40, 60]
var speed = 100
@export var speeds = [100, 150, 200]

var matrix = []

var direction
var shape

var nomnoming = false

func _ready():
	#print("Googoogaagaa")
	animation_player.play("Walking")
	shape = collision_shape_2D.shape

func _physics_process(delta):
	if player_exists and ground and walls:
		var current_position = global_position
		navigation_agent_2D.target_position = get_adjusted_target_position(current_position, player.global_position, shape.radius, player.radius)
		var next_path_position = navigation_agent_2D.get_next_path_position()
		var new_velocity = current_position.direction_to(next_path_position).normalized() * speed


		
		navigation_agent_2D.target_desired_distance = shape.radius + player.radius
		
		if navigation_agent_2D.avoidance_enabled:
			navigation_agent_2D.set_velocity(new_velocity)
		else:
			_on_navigation_agent_2d_velocity_computed(new_velocity)
		
		var distance_to_player = pow(pow(abs(global_position.x - player.global_position.x), 2) + pow(abs(global_position.y - player.global_position.y), 2), 0.5)
		var nomnom_distance = shape.radius + player.radius + 2
		
		
		if distance_to_player <= nomnom_distance and nomnoming == false:
			nomnoming = true
			player.take_damage(10)
			if get_tree():
				await get_tree().create_timer(0.2).timeout
			nomnoming = false
		
		if distance_to_player > nomnom_distance:
			animated_sprite_2D.rotation = velocity.angle()
			move_and_slide()
		else:
			animated_sprite_2D.rotation = current_position.direction_to(next_path_position).angle()
		#print(nomnoming)

func get_adjusted_target_position(agent_position: Vector2, target_position: Vector2, agent_radius: float, player_radius : float) -> Vector2:
	direction = (target_position - agent_position).normalized()
	return target_position - direction * (agent_radius + player_radius)


func _on_navigation_agent_2d_velocity_computed(safe_velocity: Vector2) -> void:
	velocity = safe_velocity

func take_damage(damage: float):
	health -= damage
	print("Zombie health: " + str(health))
	if health <= 0:
		queue_free()
