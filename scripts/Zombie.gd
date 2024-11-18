#Zombie script

extends CharacterBody2D
class_name Zombie

@onready var navigation_agent_2D : NavigationAgent2D = $NavigationAgent2D
@onready var collision_shape_2D = $CollisionShape2D

@export var main_path = NodePath("Main")
@export var player_path = NodePath("Player")

var main_scene
var player
var player_exists = true
var health = 20
@export var healths = [20, 40, 60]
var speed = 100
@export var speeds = [100, 150, 200]

var matrix = []

var direction
var shape

var nomnoming = false

func _ready():
	shape = collision_shape_2D.shape
	player = get_node(player_path)
	main_scene = get_node(main_path)

func _physics_process(delta):
	#print("My layer: " + str(self.collision_layer))
	if player_exists:
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
		var nomnom_distance = shape.radius + player.radius + 1
		
		
		if distance_to_player <= nomnom_distance and nomnoming == false:
			nomnoming = true
			player.take_damage(10)
			if get_tree():
				await get_tree().create_timer(0.1).timeout
			nomnoming = false
			
		move_and_slide()

func get_adjusted_target_position(agent_position: Vector2, target_position: Vector2, agent_radius: float, player_radius : float) -> Vector2:
	direction = (target_position - agent_position).normalized()
	return target_position - direction * (agent_radius + player_radius)


func _on_navigation_agent_2d_velocity_computed(safe_velocity: Vector2) -> void:
	velocity = safe_velocity

func take_damage(damage: float):
	health -= damage
	if health <= 0:
		queue_free()
