class_name Slot extends Control


signal request


var allowed_types: Array
var from_template := false
var progress := 1
var required := false
var consumed := false
var entity: Entity = null
var assignment: Node = null

@onready var empty: Control = %Empty
@onready var label: Label = %Label
@onready var consumed_texture: TextureRect = %ConsumedTexture
@onready var required_texture: TextureRect = %RequiredTexture


func set_required(required: bool) -> void:
	self.required = required
	self.required_texture.visible = self.required


func set_consumed(consumed: bool) -> void:
	self.consumed = consumed
	self.consumed_texture.visible = self.consumed


func set_allowed_types(allowed_types: Array) -> void:
	self.allowed_types = allowed_types
	var allowed_type_names := []
	for allowed_type in self.allowed_types:
		allowed_type_names.append(Global.TYPE_NAMES[allowed_type].capitalize())
	self.label.text = "/".join(allowed_type_names)


func add_entity(entity: Entity) -> void:
	self.empty.hide()
	self.entity = entity
	self.add_child(self.entity)
	self.entity.slot = self
	self.assignment.slots_dirty = true
	self.assignment.label_dirty = true


func remove_entity() -> Entity:
	var entity = self.entity
	self.entity.slot = null
	self.remove_child(self.entity)
	self.entity = null
	self.empty.show()
	self.assignment.slots_dirty = true
	self.assignment.label_dirty = true
	return entity


func _can_drop_data(position: Vector2, data) -> bool:
	# TODO allow dropping on top of an entity to swap them, or return to storage
	var entity: Entity = data
	return (
		self.entity == null
		or self.entity == entity
	) and entity.type in self.allowed_types


func _drop_data(position: Vector2, data) -> void:
	var entity = data
	if entity != self.entity:
		entity.slot.remove_entity()
		self.add_entity(entity)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.is_pressed():
			self.assignment.send_request(self)


func _ready():
	self.set_required(self.required)
	self.set_consumed(self.consumed)
	self.set_allowed_types(self.allowed_types)
