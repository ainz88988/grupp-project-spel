extends CharacterBody2D

@onready var navigation_agent_2D : NavigationAgent2D = $NavigationAgent2D
@onready var collision_shape_2D = $CollisionShape2D

@export var player_path = NodePath("Player")
@export var main_path = NodePath("Main")

var player
var health = 20
@export var healths = [20, 40, 60]
var speed = 100
@export var speeds = [100, 150, 200]

var matrix = []

var direction

func _ready():
	var shape = collision_shape_2D.shape
	
	#navigation_agent_2D.agent_radius = shape.radius
	
	#for y in range(0, 41):
	#	matrix.append([])
	#	for x in range(0, 71):
	#		matrix[y].append(x)
	player = get_node(player_path)

func _physics_process(delta):
	if player:
		navigation_agent_2D.target_position = player.global_position
		var current_position = global_position
		var next_path_position = navigation_agent_2D.get_next_path_position()
		var new_velocity = current_position.direction_to(next_path_position).normalized() * speed
		
		if navigation_agent_2D.avoidance_enabled:
			navigation_agent_2D.set_velocity(new_velocity)
		else:
			_on_navigation_agent_2d_velocity_computed(new_velocity)
		
		#direction = (player.global_position - global_position).normalized()
		#velocity = direction * speed
		move_and_slide()


func _on_navigation_agent_2d_velocity_computed(safe_velocity: Vector2) -> void:
	velocity = safe_velocity
