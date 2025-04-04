extends Control

@export var element_scene: = preload("res://sources/language_tool/word_list_element.tscn")

@onready var elements_container: = %ElementsContainer
@onready var new_gp_layer: = $NewGPLayer
@onready var new_gp: = %NewGP
@onready var title: = %ListTitle
@onready var lesson_title: = %Lesson
@onready var word_title: = %Word
@onready var graphemes_title: = %Graphemes
@onready var error_label: = %ErrorLabel

var undo_redo: = UndoRedo.new()
var in_new_gp_mode: = false:
	set = set_in_new_gp_mode
var _e
var sub_elements_list: Dictionary = {}
var new_gp_asked_element
var new_gp_asked_ind: int


func create_sub_elements_list() -> void:
	sub_elements_list.clear()
	Database.db.query("Select * FROM GPs ORDER BY GPs.Grapheme")
	for e in Database.db.query_result:
		sub_elements_list[e.ID] = {
			grapheme = e.Grapheme,
			phoneme = e.Phoneme,
		}


func _ready() -> void:
	create_sub_elements_list()
	
	_e = element_scene.instantiate()
	
	Database.db.query(_get_query())
	
	var results: = Database.db.query_result
	for e in results:
		var element: = element_scene.instantiate()
		element.sub_elements_list = sub_elements_list
		element.word = e[_e.table_graph_column]
		element.id = e[_e.table_graph_column + "Id"]
		element.exception = e.Exception
		element.set_gp_ids_from_string(e[_e.sub_table_id + "s"])
		elements_container.add_child(element)
		element.undo_redo = undo_redo
		element.delete_pressed.connect(_on_element_delete_pressed.bind(element))
		element.new_GP_asked.connect(_on_element_new_GP_asked.bind(element))
		element.GPs_updated.connect(_on_GPs_updated)
		element.update_lesson()
	
	title.set_title(_e.table_graph_column + " List")
	lesson_title.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	word_title.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	word_title.text = _e.table_graph_column
	graphemes_title.text = _e.sub_table
	_reorder_by("lesson")


func _get_query() -> String:
	return "SELECT %s.ID as %sId, %s, group_concat(%s, ' ') as %ss, group_concat(%s, ' ') as %ss, group_concat(%s.ID, ' ') as %ss, %s.Exception 
			FROM %s 
			INNER JOIN ( SELECT * FROM %s ORDER BY %s.Position ) %s ON %s.ID = %s.%sID 
			INNER JOIN %s ON %s.ID = %s.%s
			GROUP BY %s.ID" % [_e.table, _e.table_graph_column,
				_e.table_graph_column, _e.sub_table_graph_column, _e.sub_table_graph_column,
				_e.sub_table_phon_column, _e.sub_table_phon_column,
				_e.sub_table, _e.sub_table_id, _e.table,
				_e.table,
				_e.relational_table, _e.relational_table, _e.relational_table, _e.table, _e.relational_table, _e.table_graph_column,
				_e.sub_table, _e.sub_table, _e.relational_table, _e.sub_table_id,
				_e.table]


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_undo"):
		undo_redo.undo()
	elif event.is_action_pressed("ui_redo"):
		undo_redo.redo()


func _on_element_delete_pressed(element: Control) -> void:
	undo_redo.create_action("delete")
	undo_redo.add_do_method(elements_container.remove_child.bind(element))
	undo_redo.add_undo_method(elements_container.add_child.bind(element))
	undo_redo.add_undo_method(elements_container.move_child.bind(element, element.get_index()))
	undo_redo.commit_action()


func _on_plus_button_pressed() -> void:
	undo_redo.create_action("add")
	var element: = element_scene.instantiate()
	element.sub_elements_list = sub_elements_list
	element.word = ""
	element.undo_redo = undo_redo
	element.delete_pressed.connect(_on_element_delete_pressed.bind(element))
	element.new_GP_asked.connect(_on_element_new_GP_asked.bind(element))
	element.GPs_updated.connect(_on_GPs_updated)
	undo_redo.add_do_method(elements_container.add_child.bind(element))
	undo_redo.add_do_method(elements_container.move_child.bind(element, 0))
	undo_redo.add_undo_method(elements_container.remove_child.bind(element))
	undo_redo.commit_action()
	element.edit_mode()


func _on_element_new_GP_asked(ind: int, element) -> void:
	in_new_gp_mode = true
	new_gp_asked_element = element
	new_gp_asked_ind = ind
	new_gp.edit_mode()


func set_in_new_gp_mode(p_in_new_gp_mode: bool) -> void:
	in_new_gp_mode = p_in_new_gp_mode
	new_gp_layer.visible = in_new_gp_mode


func _on_gp_list_element_validated() -> void:
	new_gp.insert_in_database()
	if new_gp.has_method("update_lesson"):
		new_gp.update_lesson()
	in_new_gp_mode = false
	create_sub_elements_list()
	for element in elements_container.get_children():
		element.sub_elements_list = sub_elements_list
	new_gp_asked_element.new_gp_asked_added(new_gp_asked_ind, new_gp.id)


func _on_GPs_updated() -> void:
	create_sub_elements_list()
	for element in elements_container.get_children():
		element.sub_elements_list = sub_elements_list


func _on_save_button_pressed() -> void:
	for element in elements_container.get_children():
		element.insert_in_database()
	Database.db.query(_get_query())
	var result: = Database.db.query_result
	for e in result:
		var found: = false
		for element in elements_container.get_children():
			if " ".join(element.gp_ids) == e[_e.sub_table_id + "s"] and element.word == e[_e.table_graph_column]:
				found = true
				break
		if not found:
			Database.db.delete_rows(_e.table, "ID=%s" % e[_e.table_graph_column + "Id"])
	undo_redo.clear_history()



func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://sources/language_tool/prof_tool_menu.tscn")


func _reorder_by(property_name: String) -> void:
	var c: = elements_container.get_children()
	c.sort_custom(sorting_function.bind(property_name))
	for e in elements_container.get_children():
		elements_container.remove_child(e)
	for e in c:
		elements_container.add_child(e)


func sorting_function(a, b, property_name) -> bool:
	return a.get(property_name) < b.get(property_name)


func _on_list_title_add_pressed() -> void:
	_on_plus_button_pressed()


func _on_list_title_back_pressed() -> void:
	_on_back_button_pressed()


func _on_list_title_new_search(new_text: String) -> void:
	for e in elements_container.get_children():
		e.visible = e.word.begins_with(new_text)


func _on_list_title_save_pressed() -> void:
	_on_save_button_pressed()


func _on_lesson_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("left_click"):
		_reorder_by("lesson")


func _on_word_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("left_click"):
		_reorder_by(_e.table_graph_column.to_lower())


func _on_list_title_import_path_selected(path: String, match_to_file: bool) -> void:
	var file: = FileAccess.open(path, FileAccess.READ)
	var line: = file.get_csv_line()
	if line.size() < 1 or line[0] != "ORTHO" and line[1] != "GPMATCH":
		error_label.text = "Column names should be ORTHO, GPMATCH"
		return
	var all_data = {}
	while not file.eof_reached():
		line = file.get_csv_line()
		if line.size() < 2:
			continue
		_e._try_to_complete_from_word(line[0])
		all_data[line[0]] = true
	get_tree().reload_current_scene()
	
	# delete elements that are not in file
	if match_to_file:
		var query: = "Select * FROM Words"
		Database.db.query(query)
		var result: = Database.db.query_result
		for e in result:
			if not e.Word in all_data:
				Database.db.delete_rows("Words", "ID=%s" % e.ID)
		
