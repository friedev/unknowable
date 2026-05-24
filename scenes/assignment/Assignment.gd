class_name Assignment
extends Control

signal request(slot)

@export var text: String
@export var texture: Texture2D = null
@export var autohide := false
@export var expanded := true

@export var type: Global.AssignmentTypes
@export var max_progress: int
@export var max_slots := -1
@export var raid := false
@export var exhausts := false
@export var risk := 0
@export var max_death_chance := 0.0
@export var min_death_chance := 0.0
var type_deltas := { }
var gained_assignments := []
var gained_entities := []
var template_slot: Slot = null
var slots := []

var progress := 0
var label_dirty := false
var slots_dirty := false

@onready var slot_container: Container = %SlotContainer
@onready var label: RichTextLabel = %Label
@onready var texture_container: Container = %TextureContainer
@onready var texture_rect: TextureRect = %TextureRect
@onready var progress_bar: ProgressBar = %ProgressBar
@onready var expanded_container: Container = %ExpandedContainer
@onready var template_container: Control = %TemplateContainer


func get_entities() -> Array:
	var entities := []
	for slot in slots:
		if slot.entity != null:
			entities.append(slot.entity)
	return entities


func get_death_chance() -> float:
	if risk == 0:
		return 0.0
	if risk < 0.0:
		return max_death_chance
	var effective_entities: int = max(0, len(get_entities()) - 1)
	var actual_risk: int = max(0, risk - effective_entities)
	var death_chance := (max_death_chance - min_death_chance) * float(actual_risk) / float(risk)
	return min_death_chance + death_chance


func get_added_progress() -> int:
	var added_progress := 0
	for slot in slots:
		if slot.entity != null:
			added_progress += slot.progress
		elif slot.required:
			return 0
	return added_progress


func update_label() -> void:
	var entities := get_entities()

	label.clear()

	if raid:
		label.push_color(Global.COLOR_BAD)
	label.add_text(text)
	if raid:
		label.pop()

	if max_progress > 0:
		label.add_text(" (")
		var added_progress := get_added_progress()
		if added_progress > 0:
			label.push_color(Global.COLOR_PREVIEW)
			label.add_text("%d+" % added_progress)
			label.pop()
		label.add_text("%d/%d) " % [progress, max_progress])
	else:
		label.add_text(" (%d) " % len(entities))

	if risk != 0 and len(entities) > 0:
		label.push_color(Global.COLOR_BAD)
		label.add_text("%d%% Chance of Death " % Global.percent(get_death_chance()))
		label.pop()

	var previews := []
	for type in Global.Types.values():
		var delta = type_deltas.get(type)
		if delta != null and delta != 0:
			previews.append(
				"%s %s" % [
					Global.delta(delta),
					Global.plural(Global.TYPE_NAMES[type].capitalize(), delta),
				],
			)

	if len(previews) > 0:
		label.push_color(Global.COLOR_PREVIEW)
		label.add_text(", ".join(previews))
		label.pop()


func set_text(text: String) -> void:
	self.text = text
	label_dirty = true


func set_texture(texture: Texture2D) -> void:
	self.texture = texture
	if texture != null:
		texture_rect.texture = texture
		texture_container.show()
	else:
		texture_container.hide()


func set_expanded(expanded: bool) -> void:
	self.expanded = expanded
	expanded_container.visible = expanded


func set_progress(progress: int) -> void:
	self.progress = min(progress, max_progress)
	progress_bar.value = self.progress
	label_dirty = true


func set_max_progress(max_progress: int) -> void:
	self.max_progress = max_progress
	progress_bar.max_value = max_progress
	set_progress(min(progress, max_progress))
	if max_progress == 0:
		progress_bar.hide()
	else:
		progress_bar.show()
	label_dirty = true


func set_template_slot(template_slot: Slot) -> void:
	self.template_slot = template_slot
	template_container.add_child(template_slot)


func update_slots() -> void:
	if template_slot == null:
		return

	var empty_slots := 0
	for slot in slots:
		if slot.from_template and slot.empty.visible:
			empty_slots += 1
	if empty_slots > 1 or (
		empty_slots == 1
		and not slots[-1].empty.visible
	):
		var i := 0
		while i < len(slots):
			var slot: Slot = slots[i]
			if slot.from_template and slot.entity == null:
				remove_slot(slot)
				slot.queue_free()
				empty_slots -= 1
			else:
				i += 1
	if empty_slots == 0 and (max_slots < 0 or len(slots) < max_slots):
		create_slot()


func create_slot() -> void:
	# as of 75742ac, duplicate isn't duplicating fields, so manually copy them
	var slot: Slot = template_slot.duplicate()
	slot.from_template = true
	slot.progress = template_slot.progress
	slot.required = template_slot.required
	slot.consumed = template_slot.consumed
	slot.allowed_types = template_slot.allowed_types.duplicate()
	add_slot(slot)


func add_slot(slot: Slot) -> void:
	slots.append(slot)
	slot_container.add_child(slot)
	slot.assignment = self
	label_dirty = true
	show()


func remove_slot(slot: Slot) -> void:
	slot.assignment = null
	slots.erase(slot)
	slot_container.remove_child(slot)
	label_dirty = true
	if autohide and len(slots) == 0:
		hide()


func add_entity(entity: Entity) -> void:
	var success := false
	for slot in slots:
		if slot.entity == null and entity.type in slot.allowed_types:
			slot.add_entity(entity)
			success = true
			break
	assert(success)
	update_slots()
	show()


func send_request(slot: Slot) -> void:
	emit_signal("request", slot)


func _ready() -> void:
	set_text(text)
	set_texture(texture)
	set_max_progress(max_progress)
	set_progress(progress)


func _process(delta: float) -> void:
	if slots_dirty:
		update_slots()
		slots_dirty = false
	if label_dirty:
		update_label()
		label_dirty = false
