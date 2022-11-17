extends PanelContainer


export var text: String
export var progress := 0
export var max_progress: int
export var texture: Texture = null

export var autohide := false
export var raid := false
export var risk := 0
export var max_death_chance := 0.0
export var min_death_chance := 0.0
export var type_deltas := {}

var slots := []
var template_slot: Node = null

var label_dirty := false
var slots_dirty := false

onready var slot_container: Container = self.find_node("SlotContainer")
onready var label: RichTextLabel = self.find_node("Label")
onready var texture_container: Container = self.find_node("TextureContainer")
onready var texture_rect: TextureRect = self.find_node("TextureRect")
onready var progress_bar: ProgressBar = self.find_node("ProgressBar")


func get_entities() -> Array:
	var entities := []
	for slot in self.slots:
		if slot.entity != null:
			entities.append(slot.entity)
	return entities


func get_death_chance() -> float:
	if self.risk == 0:
		return 0.0
	if self.risk < 0.0:
		return self.max_death_chance
	var effective_entities := max(0, len(self.get_entities()) - 1)
	var actual_risk := max(0, self.risk - effective_entities)
	var death_chance := (self.max_death_chance - self.min_death_chance) * float(actual_risk) / float(self.risk)
	return self.min_death_chance + death_chance


func update_label() -> void:
	var entities := self.get_entities()

	self.label.clear()

	if self.raid:
		self.label.push_color(Global.COLOR_BAD)
	self.label.add_text(self.text)
	if self.raid:
		self.label.pop()

	if self.max_progress > 0:
		self.label.add_text(" (")
		if len(entities) > 0:
			self.label.push_color(Global.COLOR_PREVIEW)
			self.label.add_text("%d+" % len(entities))
			self.label.pop()
		self.label.add_text("%d/%d) " % [self.progress, self.max_progress])

	if self.risk != 0 and len(entities) > 0:
		self.label.push_color(Global.COLOR_BAD)
		self.label.add_text("%d%% Chance of Death " % Global.percent(self.get_death_chance()))
		self.label.pop()

	var previews := []
	for type in Global.Types.values():
		var delta = self.type_deltas.get(type)
		if delta != null and delta != 0:
			previews.append("%s %s" % [
					Global.delta(delta),
					Global.plural(Global.TYPE_NAMES[type].capitalize(), delta),
				]
			)

	if len(previews) > 0:
		self.label.push_color(Global.COLOR_PREVIEW)
		self.label.add_text(", ".join(previews))
		self.label.pop()


func set_text(text: String) -> void:
	self.text = text
	self.label_dirty = true


func set_texture(texture: Texture) -> void:
	self.texture = texture
	if texture != null:
		self.texture_rect.texture = texture
		self.texture_container.show()
	else:
		self.texture_container.hide()


func set_progress(progress: int) -> void:
	self.progress = min(progress, self.max_progress)
	self.progress_bar.value = self.progress
	self.label_dirty = true


func set_max_progress(max_progress: int) -> void:
	self.max_progress = max_progress
	self.progress_bar.max_value = self.max_progress
	self.set_progress(min(self.progress, self.max_progress))
	if self.max_progress == 0:
		self.progress_bar.hide()
	else:
		self.progress_bar.show()
	self.label_dirty = true


func update_slots() -> void:
	if self.template_slot == null:
		return

	var empty_slots := 0
	for slot in self.slots:
		if slot.empty.visible:
			empty_slots += 1
	if empty_slots > 1 or (
		empty_slots == 1
		and not self.slots[-1].empty.visible
	):
		var i := 0
		while i < len(self.slots):
			var slot: Node = self.slots[i]
			if slot.entity == null:
				self.remove_slot(slot)
				slot.queue_free()
				empty_slots -= 1
			else:
				i += 1
	if empty_slots == 0:
		self.create_slot()


func create_slot() -> void:
	self.add_slot(self.template_slot.duplicate())


func add_slot(slot: Node) -> void:
	self.slots.append(slot)
	self.slot_container.add_child(slot)
	slot.assignment = self
	self.label_dirty = true
	self.show()


func remove_slot(slot: Node) -> void:
	slot.assignment = null
	self.slots.erase(slot)
	self.slot_container.remove_child(slot)
	self.label_dirty = true
	if self.autohide and len(self.slots) == 0:
		self.hide()


func _ready():
	self.set_text(text)
	self.set_texture(texture)
	self.set_max_progress(self.max_progress)
	self.set_progress(self.progress)


func _process(delta: float) -> void:
	if self.slots_dirty:
		self.update_slots()
		self.slots_dirty = false
	if self.label_dirty:
		self.update_label()
		self.label_dirty = false
