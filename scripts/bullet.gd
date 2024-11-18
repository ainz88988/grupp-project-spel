#Bullet script

extends CharacterBody2D

var bullet_type = "9mm"
@export var speed = 800
@export var max_bounces = 3
var damage
var bounce_count = 0


func _ready():
	velocity = Vector2(cos(rotation), sin(rotation)) * speed

func _physics_process(delta):
	if bullet_type == "9mm":
		if bounce_count < max_bounces:
			var collision = move_and_collide(velocity * delta)
			
			if collision:
				handle_collision(collision)
		else:
			queue_free()
	elif bullet_type == "buckshot":
		var collision = move_and_collide(velocity * delta)
		if collision:
			handle_collision(collision)

func handle_collision(collision):
	var collider = collision.get_collider()
	if str(collision.get_collider())[0] == "W":
		if bullet_type == "9mm":
			velocity = velocity.bounce(collision.get_normal())
			bounce_count += 1
			rotation = velocity.angle()
		elif bullet_type == "buckshot":
			queue_free()
	elif collider is Zombie:
		if collider.has_method("take_damage"):
			collider.take_damage(100)
		queue_free()
