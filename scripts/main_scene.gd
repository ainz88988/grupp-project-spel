extends Node2D

@export var zombie_scene : PackedScene = preload("res://scenes/Zombie.tscn")
@export var zombie_limit = 20
@onready var zombie = $Zombie


@export var main_path = NodePath("Main")
@export var player_path = NodePath("Player")
@export var ground_path = NodePath("Ground")
@export var walls_path = NodePath("Walls")

@onready var player = $Player
var camera_area

var spawn_cooldown = false
var spawn_cooldown_time = 1

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	spawn_zombies()


func spawn_zombies():
	if not spawn_cooldown:
		if get_tree().get_nodes_in_group("Zombies").size() < zombie_limit:
			var zombie_instance = zombie_scene.instantiate()
			zombie_instance.add_to_group("Zombies")
			camera_area = player.camera_area
			
			var spawn_locations_reference = [
				Vector2(930, 610), 
				Vector2(930, 2015), 
				Vector2(3615, 610), 
				Vector2(3615, 2015)
			]
			
			var spawn_locations = []
			for location in spawn_locations_reference:
				if not camera_area.has_point(location):
					spawn_locations.append(location)

			if spawn_locations.size() > 0:
				var random_index = randi_range(0, spawn_locations.size() - 1)
				zombie_instance.global_position = spawn_locations[random_index]
				zombie_instance.main_scene = get_node(main_path)
				zombie_instance.player = get_node(player_path)
				zombie_instance.ground = get_node(ground_path)
				zombie_instance.walls = get_node(walls_path)
				add_child(zombie_instance)
				zombie_instance.player = player
			else:
				print("No valid spawn locations found.")

			spawn_cooldown = true
			await get_tree().create_timer(spawn_cooldown_time).timeout
			spawn_cooldown = false
