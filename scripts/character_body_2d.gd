extends CharacterBody2D

#signaler
signal bullet_shot(bullet_scene, location)


# karaktärens hastighet
@export var speed = 200

# koppling till barrel noden under icon noden
@onready var barrel = $Icon/barrel

#laddar bullet scene
var bullet_scene = preload("res://scenes/bullet.tscn")


# cooldown variabel
var shoot_cd := false

# rörelse "W, A, S, D"
func _physics_process(delta):
	var direction = Vector2(Input.get_axis("left", "right"), Input.get_axis("up", "down"))
	velocity = direction * speed
	move_and_slide()


#shoot function med cooldown på 0.25 sekunder
func _process(delta):
	if Input.is_action_pressed("shoot"):
		if !shoot_cd:
			shoot_cd = true
			shoot()
			await get_tree().create_timer(0.25).timeout
			shoot_cd = false


# ej färdig shoot function
func shoot():
	bullet_shot.emit()
	pass

