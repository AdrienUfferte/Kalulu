extends Node2D
class_name Turtle

signal pressed(gp: Dictionary)
signal animation_changed(position: Vector2)

@onready var body: Node2D = $Body
@onready var sprite: AnimatedSprite2D = $Body/AnimatedSprite2D
@onready var label: Label = $Label
@onready var head_area_collision_shape: CollisionShape2D = $Body/HeadArea/CollisionShape2D
@onready var body_area_collision_shape: CollisionShape2D = $Body/BodyArea/CollisionShape2D
@onready var highlight_fx: HighlightFX = $HighlightFX
@onready var right_fx: RightFX = $RightFX
@onready var wrong_fx: WrongFX = $WrongFX
@onready var delete_timer: Timer = $DeleteTimer

var gp: Dictionary: 
	set(value):
		gp = value
		if gp.has("Grapheme"):
			label.text = gp.Grapheme
var velocity: float = 0.
var direction: Vector2 = Vector2(0,-1):
	set = _set_direction
var is_moving: bool = true
var is_visible_on_screen: bool = false


func _process(delta):
	if is_moving:
		position += velocity * delta * direction


func _set_direction(new_direction: Vector2) -> void:
	# Get the angle difference between the old and new direction
	var angle_to : float = rad_to_deg(direction.angle_to(new_direction))

	# Calculate the new angle of the body - this allows to get the closest angle for tweening
	var angle: float = body.rotation_degrees + rad_to_deg(direction.angle_to(new_direction))

	# Changes the direction
	direction = new_direction
	
	# Play turn animations	
	if angle_to > 0:
		sprite.play("swim_right")
	else:
		sprite.play("swim_left")

	# Tween the rotation of the body
	var tween: = create_tween()
	tween.tween_property(body, "rotation_degrees", angle, sprite.sprite_frames.get_frame_count(sprite.animation) /sprite.sprite_frames.get_animation_speed(sprite.animation))

#region Actions

func highlight(value: bool = true) -> void:
	if value:
		highlight_fx.play()
	else:
		highlight_fx.stop()


func right() -> void:
	is_moving = false
	sprite.play("victory")
	right_fx.play()
	await right_fx.finished


func wrong() -> void:
	is_moving = false
	wrong_fx.play()
	await wrong_fx.finished


func disappear() -> void:
	is_moving = false
	head_area_collision_shape.set_deferred("disabled", true)
	body_area_collision_shape.set_deferred("disabled", true)
	await get_tree().create_timer(randf_range(0., 0.2)).timeout
	sprite.play("disappear")
	var tween: = create_tween()
	tween.tween_property(label, "modulate:a", 0, sprite.sprite_frames.get_frame_count(sprite.animation) /sprite.sprite_frames.get_animation_speed(sprite.animation))

#endregion

#region Connections

func _on_swipe_detector_swipe(start_position: Vector2, end_position: Vector2):
	if not is_moving:
		return
	
	# Change the direction toward the swipe
	direction = start_position.direction_to(end_position)


func _on_animated_sprite_2d_animation_changed():
	if is_visible_on_screen:
		animation_changed.emit(global_position)


func _on_animated_sprite_2d_animation_finished():
	if sprite.animation in ["swim_left", "swim_right"]:
		sprite.play("swim")
	elif sprite.animation == "disappear":
		if right_fx.is_playing:
			await right_fx.finished
		if wrong_fx.is_playing:
			await wrong_fx.is_playing
		
		queue_free()


func _on_visible_on_screen_notifier_2d_screen_entered():
	is_visible_on_screen = true


func _on_visible_on_screen_notifier_2d_screen_exited():
	is_visible_on_screen = false
	delete_timer.start()


func _on_delete_timer_timeout():
	if not is_visible_on_screen:
		queue_free()


func _on_body_area_area_entered(area):
	disappear()


func _on_swipe_detector_pressed() -> void:
	pressed.emit(gp)

#endregion





