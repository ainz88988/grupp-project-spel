extends CharacterBody2D

@export var bullet_scene : PackedScene = preload("res://scenes/bullet.tscn")
@onready var collision_shape_2D = $CollisionShape2D
var shape
var radius

@export var health = 100
@export var walk_speed = 300
@export var sprint_speed = 500
@onready var barrel = $Barrel
@onready var sword = $Sword
@export var swing_duration = 0.1

var direction_to_mouse = Vector2.ZERO
var angle_to_mouse = 0
var barrel_length = 40
var cooldown = false
var spread_sum = 0

var grabbed = false
var time_to_nibbling = 0
var active_timer = 0

var arsenal = {
	"Sword": {
		"duration": swing_duration,
		"damage": 15,
		"fire_mode": "automatic",
		"sweep_range": deg_to_rad(70) #Degrees 
	},
	"Pistol": {
		"fire_mode": ["semi", "automatic"],
		"bullets_per_shot": 1,
		"fire_rate": 2,
		"spread": 2, #Degrees
		"bullet_type": "9mm",
		"bullet_damage": 2
	},
	"Shotgun": {
		"fire_mode": ["semi", "automatic"],
		"bullets_per_shot" : 7,
		"fire_rate": 0.5,
		"spread": 6, # Degrees
		"bullet_type": "buckshot",
		"bullet_damage": 1
	}
}

var arsenal_keys = arsenal.keys()
var selected_weapon = "Pistol"
var fire_mode_index = 0

var is_swinging = false 
var swing_start_angle = deg_to_rad(35)
var swing_end_angle = deg_to_rad(-35)
var last_barrel_rotation
var swing_progress = 0.0

var sweep_range = arsenal["Sword"]["sweep_range"]
var sword_offset = arsenal["Sword"]["sweep_range"] / 2.0

func _ready():
	shape = collision_shape_2D.shape
	radius = shape.radius
	
	barrel.visible = !barrel.visible
	sword.visible = !sword.visible
	pass

func _physics_process(delta):
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
	var pivot_distance = 20
	barrel.position = Vector2(cos(angle_to_mouse), sin(angle_to_mouse)) * pivot_distance
	
	if is_swinging != true:
		last_barrel_rotation = barrel.rotation
		sword.rotation = barrel.rotation + swing_start_angle
	else:
		swing(delta, last_barrel_rotation)

	if grabbed:
		active_timer += delta
		if active_timer >= time_to_nibbling:
			take_damage(10)
			print("Ouch!")
	else:
		active_timer = 0.0
	
	if Input.is_action_just_pressed("scroll_up"):
		var current_index = arsenal_keys.find(selected_weapon)
		current_index = clampi(current_index + 1, 0, arsenal_keys.size() - 1)
		selected_weapon = arsenal_keys[current_index]
		print("Selected weapon: ", selected_weapon)
		print("Current_index: " + str(current_index))
		if current_index > 0:
			barrel.visible = true
			sword.visible = false
	elif Input.is_action_just_pressed("scroll_down"):
		var current_index = arsenal_keys.find(selected_weapon)
		current_index = clampi(current_index - 1, 0, arsenal_keys.size() - 1)
		selected_weapon = arsenal_keys[current_index]
		print("Selected weapon: ", selected_weapon)
		print("Current_index: " + str(current_index))
		if current_index < 1:
			sword.visible = true
			barrel.visible = false
		
		
	if Input.is_action_just_pressed("switch_firemode"):
		fire_mode_index = (fire_mode_index + 1) % 2
		print(fire_mode_index)
	
	if !cooldown:
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
				swing_progress = 0.0
				cooldown = true
				await get_tree().create_timer(swing_duration).timeout
				cooldown = false


func swing(delta, initial_rotation):
	swing_progress += delta / swing_duration
	
	if swing_progress >= 1.0:
		is_swinging = false
		swing_progress = 1.0

	var eased_progress = pow(swing_progress, 3)
	sword.rotation = lerp(swing_start_angle, swing_end_angle, eased_progress) + initial_rotation
	print(initial_rotation)
	
	if swing_progress >= 1.0:
		sword.rotation = barrel.rotation + swing_start_angle

func shoot():
	print(selected_weapon + " fired!")
	var damage = arsenal[selected_weapon]["bullet_damage"]
	var bullets_per_shot = arsenal[selected_weapon]["bullets_per_shot"]
	var bullet_type = arsenal[selected_weapon]["bullet_type"]
	for i in range(bullets_per_shot):
		var spread = randf_range(-deg_to_rad(arsenal[selected_weapon]["spread"]), deg_to_rad(arsenal[selected_weapon]["spread"]))
		var bullet = bullet_scene.instantiate()
		bullet.bullet_type = bullet_type
		bullet.global_position = barrel.global_position + barrel_length * direction_to_mouse
		bullet.rotation = barrel.rotation + spread
		bullet.damage = damage
		get_tree().root.add_child(bullet)
	print("\t" + "[Bullet type: " + arsenal[selected_weapon]["bullet_type"] + "]")
	#print("\t" + "[Shot spread (degrees): " + str(rad_to_deg(spread)) + "]")
	#spread_sum += spread
	#print("Sum of spread:" + str(spread_sum))
	print()
	pass
	
func take_damage(damage : float):
	health -= damage
	if health <= 0:
		queue_free()
