@tool
extends Control

const garden_scene: = preload("res://resources/gardens/garden.tscn")

@export var gardens_layout: GardensLayout:
	set = set_gardens_layout

@onready var garden_parent: = %GardenParent
@onready var line: = $ScrollContainer/Line2D
@onready var scroll_container: = $ScrollContainer

var curve: Curve2D


func set_gardens_layout(p_gardens_layout: GardensLayout) -> void:
	gardens_layout = p_gardens_layout
	add_gardens()
	if garden_parent:
		await get_tree().process_frame
	set_up_path()


func _process(_delta: float) -> void:
	line.position.x = - scroll_container.scroll_horizontal


func add_gardens() -> void:
	if not garden_parent:
		return
	for child in garden_parent.get_children():
		child.queue_free()
	for garden_layout in gardens_layout.gardens:
		var garden: = garden_scene.instantiate()
		garden_parent.add_child(garden)
		garden.garden_layout = garden_layout


func set_up_path() -> void:
	if not garden_parent:
		return
	curve = Curve2D.new()
	for i in gardens_layout.gardens.size():
		var garden_layout: = gardens_layout.gardens[i]
		var garden_control: = garden_parent.get_child(i)
		for lesson_button in garden_layout.lesson_buttons:
			var point_position: Vector2 = garden_parent.position + garden_control.position + Vector2(lesson_button.position)
			point_position += garden_control.get_button_size() / 2
			var point_in_position: = Vector2.ZERO
			if curve.point_count > 1:
				point_in_position = curve.get_point_position(curve.point_count - 1) + curve.get_point_out(curve.point_count - 1) - point_position
			curve.add_point(point_position, point_in_position, lesson_button.path_out_position)
	line.points = curve.get_baked_points()


func _ready() -> void:
	set_gardens_layout(gardens_layout)
