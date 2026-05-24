class_name DropdownArea
extends Control

@export var expanded_texture: Texture2D
@export var collapsed_texture: Texture2D

@export var assignment: Assignment

@onready var dropdown_arrow: TextureRect = %DropdownArrow


func set_expanded(expanded: bool) -> void:
	assignment.set_expanded(expanded)
	if expanded:
		dropdown_arrow.texture = expanded_texture
	else:
		dropdown_arrow.texture = collapsed_texture


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.is_pressed():
			set_expanded(not assignment.expanded)
