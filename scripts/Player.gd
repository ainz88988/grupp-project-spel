extends CharacterBody2D

@export var bullet_scene : PackedScene = preload("res://scenes/bullet.tscn")

@export var health = 100
@export var walk_speed = 300
@export var sprint_speed = 500
@onready var barrel = $Barrel

var direction_to_mouse = Vector2.ZERO
var angle_to_mouse = 0
var barrel_length = 40
var cooldown = false

var spread_sum = 0

var grabbed = false
var time_to_nibbling = 0
var active_timer = 0

var arsenal = {
	"Pistol": {
		"fire_mode": "automatic",
		"bullets_per_shot": 1,
		"fire_rate": 0.5,
		"spread": 2, #degrees
		"bullet_type": "9mm",
		"bullet_damage": 2
	},
	"Shotgun": {
		"fire_mode": "automatic",
		"bullets_per_shot" : 7,
		"fire_rate": 2,
		"spread": 6, # degrees
		"bullet_type": "buckshot",
		"bullet_damage": 1
	},
	"Sword": {
		"lag": 2,
		"damage": 15,
		"fire_mode": "automatic"
	}
}

var arsenal_keys = arsenal.keys()

var selected_weapon = "Pistol"

func _physics_process(delta):
	var direction = Vector2(Input.get_axis("left", "right"), Input.get_axis("up", "down")).normalized()
	if !Input.is_action_pressed("sprint"):
		velocity = direction * walk_speed
	else:
		velocity = direction * sprint_speed
	#print("Velocity: " + str(velocity.length()))
	move_and_slide()
	
	if grabbed:
		active_timer += delta

		if active_timer >= time_to_nibbling:
			take_damage(10)
			print("Ouch!")
			
	else:
		active_timer = 0.0
		
func take_damage(damage : float):
	health -= damage
	if health <= 0:
		game_over()
	pass

func game_over():
	queue_free()

func _process(delta):
	var mouse_position = get_global_mouse_position()
	
	direction_to_mouse = (mouse_position - global_position).normalized()
	
	angle_to_mouse = (mouse_position - global_position).angle()
	
	barrel.rotation = angle_to_mouse
	
	var pivot_distance = 20
	barrel.position = Vector2(cos(angle_to_mouse), sin(angle_to_mouse)) * pivot_distance
	
	if Input.is_action_just_pressed("scroll_up"):
		var current_index = arsenal_keys.find(selected_weapon)
		current_index = clampi(current_index + 1, 0, arsenal_keys.size() - 1)
		selected_weapon = arsenal_keys[current_index]
		print("Selected weapon: ", selected_weapon)
	elif Input.is_action_just_pressed("scroll_down"):
		var current_index = arsenal_keys.find(selected_weapon)
		current_index = clampi(current_index - 1, 0, arsenal_keys.size() - 1)
		selected_weapon = arsenal_keys[current_index]
		print("Selected weapon: ", selected_weapon)

	
	if !cooldown:
		if selected_weapon == "Pistol" or selected_weapon == "Shotgun":
			if arsenal[selected_weapon]["fire_mode"] == "automatic":
				if Input.is_action_pressed("attack"):
					cooldown = true
					shoot()
					await get_tree().create_timer(arsenal[selected_weapon]["fire_rate"]).timeout
					cooldown = false
			else:
				if Input.is_action_just_pressed("attack"):
					cooldown = true
					shoot()
					await get_tree().create_timer(arsenal[selected_weapon]["fire_rate"]).timeout
					cooldown = false


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
