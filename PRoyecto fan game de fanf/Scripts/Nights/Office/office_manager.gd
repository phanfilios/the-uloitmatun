extends Node

@onready var office: Node2D = $Office
@onready var ai_manager: Node = get_node("../CharacterAI")
@onready var oxygen_label: Label = get_node("../HUD/OxygenLabel")

func _ready() -> void:
	if ai_manager.has_signal("oxygen_changed"):
		ai_manager.oxygen_changed.connect(_on_oxygen_changed)
	if ai_manager.has_signal("jumpscare_triggered"):
		ai_manager.jumpscare_triggered.connect(_on_jumpscare_triggered)
	
	var initial_oxygen = ai_manager.get("oxygen")
	if initial_oxygen != null:
		_on_oxygen_changed(float(initial_oxygen))

func _on_area_2d_input_event(_viewport, event, _shape_idx, button_id: int = -1) -> void:
	if not event.is_action_pressed("click_left"):
		return
	
	if not office.can_move:
		return
	
	match button_id:
		1:
			if ai_manager.has_method("repel_left_cat"):
				ai_manager.repel_left_cat()
				print("Botón izquierdo activado: gato repelido")
		_:
			print("Botón %s presionado" % button_id)

func _on_oxygen_changed(value: float) -> void:
	oxygen_label.text = "Oxígeno: %d%%" % int(round(value))
	oxygen_label.modulate = Color(1, 1, 1)
	if value <= 35.0:
		oxygen_label.modulate = Color(1.0, 0.35, 0.35)

func _on_jumpscare_triggered(cat_name: String) -> void:
	print("Jumpscare de %s" % cat_name)
