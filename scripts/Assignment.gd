extends PanelContainer


export var text: String
export var progress := 0
export var max_progress: int
export var allowed_types: Array
export var texture: Texture = null

export var autohide := false
export var raid := false
export var risk := 0
export var max_death_chance := 0.0
export var min_death_chance := 0.0
# TODO list of delta objects
export var follower_delta := 0
export var artifact_delta := 0
export var suspicion_delta := 0

var assignees := []


onready var area: Container = find_node("AssignmentArea")
onready var label: RichTextLabel = find_node("Label")
onready var texture_container: Container = find_node("TextureContainer")
onready var texture_rect: TextureRect = find_node("TextureRect")
onready var progress_bar: ProgressBar = find_node("ProgressBar")


func get_death_chance() -> float:
	if self.risk == 0:
		return 0.0
	if self.risk < 0.0:
		return self.max_death_chance
	var effective_assignees := max(0, len(self.assignees) - 1)
	var actual_risk := max(0, self.risk - effective_assignees)
	var death_chance := (self.max_death_chance - self.min_death_chance) * float(actual_risk) / float(self.risk)
	return self.min_death_chance + death_chance


func update_label() -> void:
	self.label.clear()

	if self.raid:
		self.label.push_color(Global.COLOR_BAD)
	self.label.add_text(self.text)
	if self.raid:
		self.label.pop()

	if self.max_progress > 0:
		self.label.add_text(" (")
		if len(self.assignees) > 0:
			self.label.push_color(Global.COLOR_PREVIEW)
			self.label.add_text("%d+" % len(self.assignees))
			self.label.pop()
		self.label.add_text("%d/%d) " % [self.progress, self.max_progress])

	if self.risk > 0 and len(self.assignees) > 0:
		self.label.push_color(Global.COLOR_BAD)
		self.label.add_text("%d%% Chance of Death " % Global.percent(self.get_death_chance()))
		self.label.pop()

	var previews := []
	if self.follower_delta != 0:
		previews.append("%s %s" % [
				Global.delta(self.follower_delta),
				Global.plural("Follower", self.follower_delta),
			]
		)

	if self.artifact_delta != 0:
		previews.append("%s %s" % [
				Global.delta(self.artifact_delta),
				Global.plural("Artifact", self.artifact_delta),
			]
		)

	if self.suspicion_delta != 0:
		previews.append("%s %s" % [
				Global.delta(self.suspicion_delta),
				"Suspicion",
			]
		)

	if len(previews) > 0:
		self.label.push_color(Global.COLOR_PREVIEW)
		self.label.add_text(", ".join(previews))
		self.label.pop()


func set_text(text: String) -> void:
	self.text = text
	self.update_label()


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
	self.update_label()


func set_max_progress(max_progress: int) -> void:
	self.max_progress = max_progress
	self.progress_bar.max_value = self.max_progress
	self.set_progress(min(self.progress, self.max_progress))
	if self.max_progress == 0:
		self.progress_bar.hide()
	else:
		self.progress_bar.show()
	self.update_label()


func add_assignee(assignee: Node) -> void:
	self.area.add_child(assignee)
	self.assignees.append(assignee)
	self.update_label()
	if len(self.assignees) > 0:
		self.show()

func remove_assignee(assignee: Node) -> void:
	self.area.remove_child(assignee)
	self.assignees.erase(assignee)
	self.update_label()
	if self.autohide and len(self.assignees) == 0:
		self.hide()


func can_drop_data(position: Vector2, data) -> bool:
	return data.type in self.allowed_types


func drop_data(position: Vector2, data) -> void:
	var assignee = data
	assignee.get_assignment().remove_assignee(assignee)
	self.add_assignee(assignee)


func _ready():
	self.set_text(text)
	self.set_texture(texture)
	self.set_max_progress(self.max_progress)
	self.set_progress(self.progress)
