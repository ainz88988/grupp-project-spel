#Player script

extends CharacterBody2D

@export var bullet_scene : PackedScene = preload("res://scenes/Bullet.tscn")
@onready var animated_sprite_2D = $AnimatedSprite2D
@onready var animation_player = $AnimationPlayer

@onready var audio_stream_player_2D = $AudioStreamPlayer2D

@onready var collision_shape_2D = $CollisionShape2D
@onready var sword = get_node("Hand").get_node("Sword")
var shape
var radius

@onready var camera = $Camera2D
var camera_top_left
var camera_bottom_right
var camera_area

var zombie
@export var zombie_path = NodePath("Zombie")


@export var health = 100
@export var walk_speed = 200
@export var sprint_speed = 300
@onready var barrel = $Barrel
@onready var hand = $Hand
@export var swing_duration = 0.1

var direction_to_mouse = Vector2.ZERO
var angle_to_mouse = 0
var barrel_length = 40
var cooldown = false
var spread_sum = 0

var attack_animations = ["Firing_pistol", "Firing_shotgun"]
var reload_animations = ["Reloading_pistol", "Reloading_shotgun"]
var last_animation_played

var arsenal = {
	"Sword": {
		"duration": swing_duration,
		"damage": 30,
		"fire_mode": "automatic",
	},
	"Pistol": {
		"fire_mode": ["semi", "automatic"],
		"ammo_capacity": 6,
		"bullets_per_shot": 1,
		"fire_rate": 2,
		"spread": 2, #Degrees
		"bullet_type": "9mm",
		"bullet_damage": 20,
	},
	"Shotgun": {
		"fire_mode": ["semi", "automatic"],
		"bullets_per_shot" : 7,
		"fire_rate": 0.5,
		"spread": 6, # Degrees
		"bullet_type": "buckshot",
		"bullet_damage": 20
	}
}

var pistol_shots_left = 6
var shotgun_shots_left = 1

var arsenal_keys = arsenal.keys()
var selected_weapon = "Pistol"
var fire_mode_index = 0

var is_swinging = false 
var hand_swing_start_angle = deg_to_rad(-40)
var hand_swing_end_angle = deg_to_rad(40)
var last_barrel_rotation
var swing_progress_hand = 0.0
var swing_progress_sword = 0.0

func _ready():
	animation_player.play("Idle")
	last_animation_played = "Idle"
	
	zombie = get_node(zombie_path)
	zombie.player_exists = true
	
	shape = collision_shape_2D.shape
	radius = shape.radius
	
	barrel.visible = !barrel.visible
	hand.visible = !hand.visible
	hand.process_mode = Node.PROCESS_MODE_DISABLED
	
func _physics_process(delta):
	get_camera_corners()
	var direction = Vector2(Input.get_axis("left", "right"), Input.get_axis("up", "down")).normalized()
	if !Input.is_action_pressed("sprint"):
		velocity = direction * walk_speed
	else:
		velocity = direction * sprint_speed
	#print("Velocity: " + str(velocity.length()))
	move_and_slide()
	
	var mouse_position = get_global_mouse_position()
	direction_to_mouse = (mouse_position - global_position).normalized()
	angle_to_mouse = (mouse_position - global_position).angle()
	barrel.rotation = angle_to_mouse
	animated_sprite_2D.rotation = angle_to_mouse
	var pivot_distance = 20
	barrel.position = Vector2(cos(angle_to_mouse), sin(angle_to_mouse)) * pivot_distance
	
	if is_swinging != true:
		last_barrel_rotation = barrel.rotation
		hand.rotation = barrel.rotation + hand_swing_start_angle
	else:
		swing(delta, last_barrel_rotation)
	
	if Input.is_action_just_pressed("scroll_up"):
		var current_index = arsenal_keys.find(selected_weapon)
		current_index = clampi(current_index + 1, 0, arsenal_keys.size() - 1)
		selected_weapon = arsenal_keys[current_index]
		print("Selected weapon: ", selected_weapon)
		print("Current_index: " + str(current_index))
		if current_index > 0:
			barrel.visible = true
			hand.visible = false
			if selected_weapon == "Pistol" and animation_player.current_animation not in attack_animations:
				if last_animation_played != "Firing_pistol":
					animation_player.play("Firing_pistol")
					last_animation_played = "Firing_pistol"
				hand.process_mode = Node.PROCESS_MODE_DISABLED
			elif selected_weapon == "Shotgun" and animation_player.current_animation not in attack_animations:
				if last_animation_played != "Firing_shotgun":
					animation_player.play("Firing_shotgun")
					last_animation_played = "Firing_shotgun"
				hand.process_mode = Node.PROCESS_MODE_DISABLED
			
	elif Input.is_action_just_pressed("scroll_down"):
		var current_index = arsenal_keys.find(selected_weapon)
		current_index = clampi(current_index - 1, 0, arsenal_keys.size() - 1)
		selected_weapon = arsenal_keys[current_index]
		print("Selected weapon: ", selected_weapon)
		#print("Current_index: " + str(current_index))
		if current_index < 1:
			hand.visible = true
			barrel.visible = false
			hand.process_mode = Node.PROCESS_MODE_INHERIT
		if selected_weapon == "Pistol" and animation_player.current_animation not in attack_animations:
			animation_player.play("Firing_pistol")
			last_animation_played = "Firing_pistol"
			#animation_player.seek(0, true)
			#animation_player.playback_active = false
			hand.process_mode = Node.PROCESS_MODE_DISABLED
		elif selected_weapon == "Shotgun" and animation_player.current_animation not in attack_animations:
			animation_player.play("Firing_shotgun")
			last_animation_played = "Firing_shotgun"
			#animation_player.seek(0, true)
			#animation_player.playback_active = false
			hand.process_mode = Node.PROCESS_MODE_DISABLED
		
	if Input.is_action_just_pressed("switch_firemode"):
		fire_mode_index = (fire_mode_index + 1) % 2
		print(fire_mode_index)
	
	if !cooldown and animation_player.current_animation not in attack_animations and animation_player.current_animation not in reload_animations:
		if selected_weapon == "Pistol" or selected_weapon == "Shotgun":
			if arsenal[selected_weapon]["fire_mode"][fire_mode_index] == "automatic":
				if Input.is_action_pressed("attack"):
					cooldown = true
					shoot()
					await get_tree().create_timer(1.0 / arsenal[selected_weapon]["fire_rate"]).timeout
					cooldown = false
			elif arsenal[selected_weapon]["fire_mode"][fire_mode_index] == "semi":
				if Input.is_action_just_pressed("attack"):
					cooldown = true
					shoot()
					await get_tree().create_timer(1.0 / arsenal[selected_weapon]["fire_rate"]).timeout
					cooldown = false
		elif selected_weapon == "Sword":
			if Input.is_action_just_pressed("attack"):
				is_swinging = true
				swing_progress_hand = 0.0
				cooldown = true
				await get_tree().create_timer(swing_duration).timeout
				cooldown = false


func swing(delta, initial_rotation):
	swing_progress_hand += delta / swing_duration
	
	if swing_progress_hand >= 1.0:
		is_swinging = false
		swing_progress_hand = 1.0

	var eased_progress = pow(swing_progress_hand, 3)
	hand.rotation = lerp(hand_swing_start_angle, hand_swing_end_angle, eased_progress) + initial_rotation
	#print(rad_to_deg(hand.rotation))
	
	if swing_progress_hand >= 1.0:
		hand.rotation = barrel.rotation + hand_swing_start_angle

func reload(gun_to_reload: String):
	if gun_to_reload == "Pistol":
		animation_player.play("Reloading_pistol")
	elif gun_to_reload == "Shotgun":
		#animation_player.play("Reloading_shotgun")
		pass
	

func shoot():
	print()
	if selected_weapon == "Pistol" and pistol_shots_left > 0:
		print("Pistol fired!")
		animation_player.play("Firing_pistol")
		last_animation_played = "Firing_pistol"
		audio_stream_player_2D.play_sound("Pistol_shot")
	elif selected_weapon == "Pistol":
		animation_player.play("Reloading_pistol")
		last_animation_played = "Reloading_pistol"
		print("Reloading pistol...")
	
	if selected_weapon == "Shotgun" and shotgun_shots_left > 0:
		print("Shotgun fired!")
		animation_player.play("Firing_shotgun")
		last_animation_played = "Firing_shotgun"
		audio_stream_player_2D.play_sound("Shotgun_shot")
		
	var bullet_type = arsenal[selected_weapon]["bullet_type"]
	var damage = arsenal[selected_weapon]["bullet_damage"]
	var bullets_per_shot = arsenal[selected_weapon]["bullets_per_shot"]
	var shotgun_offset = 0

	if bullet_type == "buckshot":
		shotgun_offset = 10
	else:
		shotgun_offset = 0

	for i in range(bullets_per_shot):
		var spread = randf_range(-deg_to_rad(arsenal[selected_weapon]["spread"]), deg_to_rad(arsenal[selected_weapon]["spread"]))

		var perpendicular_offset = Vector2(-direction_to_mouse.y, direction_to_mouse.x) * shotgun_offset

		var bullet_instance = bullet_scene.instantiate()
		bullet_instance.bullet_type = bullet_type
		bullet_instance.global_position = barrel.global_position + barrel_length * direction_to_mouse + perpendicular_offset
		bullet_instance.rotation = barrel.rotation + spread
		bullet_instance.damage = damage

		get_tree().root.add_child(bullet_instance)

	if selected_weapon == "Pistol" and pistol_shots_left > 0:
		print("\t" + "[Bullet type: " + arsenal[selected_weapon]["bullet_type"] + "]")
		print("Shots left: " + str(pistol_shots_left))
		
	elif selected_weapon == "Shotgun" and shotgun_shots_left > 0:
		print("\t" + "[Bullet type: " + arsenal[selected_weapon]["bullet_type"] + "]")
		print("Shots left: " + str(shotgun_shots_left))
	
	if selected_weapon == "Pistol" and pistol_shots_left > 0:
		pistol_shots_left -= 1
	else:
		pistol_shots_left = 6

	if selected_weapon == "Shotgun" and shotgun_shots_left > 0:
		shotgun_shots_left -= 1
	else:
		shotgun_shots_left = 1
	
func take_damage(damage : float):
	health -= damage
	print("Player health: " + str(health))
	if health <= 0:
		if is_instance_valid(zombie):
			zombie.player_exists = false
		print("Game_Over")
		get_tree().change_scene_to_file("res://scenes/Game_Over.tscn")


func get_camera_corners():
	var viewport_size = get_viewport().get_visible_rect().size
	var zoom = camera.zoom
	var half_size = (viewport_size * zoom) / 2

	camera_top_left = global_position - half_size
	camera_bottom_right = global_position + half_size
	camera_area = Rect2(camera_top_left, camera_bottom_right - camera_top_left)



func _on_hand_body_entered(body: Node2D) -> void:
	print(body)
	if body is Zombie:
		body.take_damage(arsenal["Sword"]["damage"])
	
