extends CharacterBody2D

var bullet_type = "9mm"
@export var speed = 800
@export var max_bounces = 100000000000
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
			queue_free()

func handle_collision(collision):
	velocity = velocity.bounce(collision.get_normal())
	bounce_count += 1
	rotation = velocity.angle()
