extends Node

signal oxygen_changed(value: float)
signal jumpscare_triggered(cat_name: String)

@export_range(0, 20) var red_level: int
@export_range(0, 20) var green_level: int
@export_range(0.0, 20.0, 0.1) var oxygen_loss_rate: float = 8.0
@export_range(0.0, 20.0, 0.1) var oxygen_recovery_rate: float = 3.5
@export_range(0.0, 100.0, 0.1) var danger_threshold: float = 60.0

var oxygen: float = 100.0
var _active_pressure: float = 0.0
var _cats: Dictionary = {
	"Red": {"ai": 0.0, "proximity": 0.0},
	"Green": {"ai": 0.0, "proximity": 0.0},
	"Negro": {"ai": 0.0, "proximity": 0.0},
	"Blanquito": {"ai": 0.0, "proximity": 0.0}
}

func _ready() -> void:
	randomize()
	_initialize_char_levels()
	set_process(true)
	oxygen_changed.emit(oxygen)

func _initialize_char_levels() -> void:
	$Red.ai_level = red_level
	$Green.ai_level = green_level
	_cats["Red"]["ai"] = float(red_level) / 20.0
	_cats["Green"]["ai"] = float(green_level) / 20.0
	# Los otros 2 gatos quedan activos para completar los 4 animatrónicos
	_cats["Negro"]["ai"] = clamp((float(red_level) + 4.0) / 20.0, 0.25, 1.0)
	_cats["Blanquito"]["ai"] = clamp((float(green_level) + 2.0) / 20.0, 0.25, 1.0)

func _process(delta: float) -> void:
	_update_cat_pressure(delta)
	_update_oxygen(delta)

func _update_cat_pressure(delta: float) -> void:
	_active_pressure = 0.0
	for cat_name in _cats.keys():
		var cat_data: Dictionary = _cats[cat_name]
		var ai_factor: float = float(cat_data["ai"])
		var advance_chance: float = lerp(0.2, 1.1, ai_factor) * delta
		if randf() < advance_chance:
			cat_data["proximity"] = clamp(float(cat_data["proximity"]) + randf_range(7.0, 16.0) * ai_factor, 0.0, 100.0)
		else:
			cat_data["proximity"] = clamp(float(cat_data["proximity"]) - randf_range(1.5, 4.0) * delta, 0.0, 100.0)
		
		if float(cat_data["proximity"]) >= danger_threshold:
			_active_pressure += (float(cat_data["proximity"]) - danger_threshold) / (100.0 - danger_threshold)
		
		if float(cat_data["proximity"]) >= 99.9:
			jumpscare_triggered.emit(cat_name)
			_reset_cat(cat_name)
		
		_cats[cat_name] = cat_data

func _update_oxygen(delta: float) -> void:
	var previous_oxygen: float = oxygen
	if _active_pressure > 0.0:
		oxygen -= oxygen_loss_rate * _active_pressure * delta
	else:
		oxygen += oxygen_recovery_rate * delta
	
	oxygen = clamp(oxygen, 0.0, 100.0)
	if not is_equal_approx(previous_oxygen, oxygen):
		oxygen_changed.emit(oxygen)

func repel_left_cat() -> void:
	# Botón 1 (mano izquierda): frena al gato más cercano
	var target_cat: String = ""
	var highest_proximity: float = 0.0
	for cat_name in _cats.keys():
		var proximity: float = float(_cats[cat_name]["proximity"])
		if proximity > highest_proximity:
			highest_proximity = proximity
			target_cat = cat_name
	
	if target_cat.is_empty():
		return
	
	var cat_data: Dictionary = _cats[target_cat]
	cat_data["proximity"] = max(float(cat_data["proximity"]) - 45.0, 0.0)
	_cats[target_cat] = cat_data

func _reset_cat(cat_name: String) -> void:
	var cat_data: Dictionary = _cats[cat_name]
	cat_data["proximity"] = randf_range(0.0, 20.0)
	_cats[cat_name] = cat_data
