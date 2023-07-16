class_name DropdownArea extends Control

const expanded_texture := preload("res://sprites/ui/dropdown_expanded.png")
const collapsed_texture := preload("res://sprites/ui/dropdown_collapsed.png")

@export var assignment: Assignment

@onready var dropdown_arrow: TextureRect = %DropdownArrow


func set_expanded(expanded: bool) -> void:
	self.assignment.set_expanded(expanded)
	if expanded:
		self.dropdown_arrow.texture = expanded_texture
	else:
		self.dropdown_arrow.texture = collapsed_texture


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.is_pressed():
			self.set_expanded(not self.assignment.expanded)
