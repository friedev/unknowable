extends CenterContainer


export var allowed_types: Array

# TODO consider using an entity to visually represent an empty slot
onready var empty: Node = self.find_node("Empty")
onready var label: Label = self.find_node("Label")
onready var texture_rect: TextureRect = self.find_node("TextureRect")

var entity: Node = null
var assignment: Node = null


func set_allowed_types(allowed_types: Array) -> void:
	self.allowed_types = allowed_types
	var allowed_type_names := []
	for allowed_type in self.allowed_types:
		allowed_type_names.append(Global.TYPE_NAMES[allowed_type].capitalize())
	self.label.text = "/".join(allowed_type_names)


func add_entity(entity: Node) -> void:
	self.empty.hide()
	self.entity = entity
	self.add_child(self.entity)
	self.entity.slot = self
	self.assignment.slots_dirty = true


func remove_entity() -> void:
	self.entity.slot = null
	self.remove_child(self.entity)
	self.entity = null
	self.empty.show()
	self.assignment.slots_dirty = true


func can_drop_data(position: Vector2, data) -> bool:
	var entity: Node = data
	return (
		self.entity == null
		or self.entity == entity
	) and entity.type in self.allowed_types


func drop_data(position: Vector2, data) -> void:
	var entity = data
	if entity != self.entity:
		entity.slot.remove_entity()
		self.add_entity(entity)