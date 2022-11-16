extends Control


const TEXT_WIN := "The conjunction is at hand.\n\nThrough secretive and tireless search, you have gathered %d artifacts. Harnessing their ancient energies, you tear a rift in the planes, whenceforth cometh eldritch beings of ineffable might.\n\nVICTORY?"
const TEXT_LOSE_TURN_LIMIT := "The conjunction is at hand.\n\nDespite your unshakeable devotion, you could not gather enough artifacts in time. The stars in their cosmic dance align once in a brief, majestic formation, but it is all for naught.\n\nFAILURE..."
const TEXT_LOSE_NO_FOLLOWERS := "The last of your followers has fallen. With none to perform the summoning rites, the conjunction passes quietly. The gods shall sleep for another millenium.\n\nFAILURE..."
const TEXT_LOSE_SURRENDER := "Reluctantly, you submit yourself and your accomplices to arrest. Many years will pass as you languish in the cold, stone jails of the Watch, wistfully watching the constellations whirl from behind iron bars.\n\nFAILURE..."
const TEXT_RAID := "The wolves are at the door.\n\nYour conjurations and clandestine operations were not as well concealed as you had hoped. Investigators from the Watch have picked up your trail. A truncheon knocks upon the door of your secret chamber and ultimatums are shouted.\n\nHow shall you respond?"

const raid_follower_cost := 2
const raid_artifact_cost := 1
var raid_artifacts_lost := []
var raid_followers_lost := []

var turn := 0
const max_turn := 52
var assignments := []
var is_game_over := false

const assignment_scene := preload("res://scenes/Assignment.tscn")
const entity_scene := preload("res://scenes/Entity.tscn")

const investigation_texture := preload("res://sprites/investigation.png")
const recruit_texture := preload("res://sprites/recruit.png")
const seek_texture := preload("res://sprites/seek.png")
const conceal_texture := preload("res://sprites/conceal.png")

var default_assignments := {}

onready var turn_label: Label = self.find_node("TurnLabel")
onready var assignment_container: Container = self.find_node("AssignmentContainer")
onready var popup: Popup = self.find_node("Popup")
onready var popup_label: Label = self.find_node("PopupLabel")
onready var popup_spacer: Label = self.find_node("PopupSpacer")
onready var popup_button1: Button = self.find_node("PopupButton1")
onready var popup_button2: Button = self.find_node("PopupButton2")
onready var popup_button3: Button = self.find_node("PopupButton3")
onready var quit_button: Button = self.find_node("QuitButton")
onready var fullscreen_button: Button = self.find_node("FullscreenButton")

onready var drag_sound: AudioStreamPlayer = self.find_node("DragSound")
onready var drop_sound: AudioStreamPlayer = self.find_node("DropSound")
onready var cancel_sound: AudioStreamPlayer = self.find_node("CancelSound")
onready var end_turn_sound: AudioStreamPlayer = self.find_node("EndTurnSound")
onready var music: AudioStreamPlayer = self.find_node("Music")


func get_suspicion() -> int:
	return len(self.default_assignment[Global.SUSPICION].get_entities())


func set_turn(turn: int) -> void:
	self.turn = clamp(0, turn, self.max_turn)
	self.turn_label.text = "Week %d of %d" % [self.turn + 1, self.max_turn]


func create_entity(type: int) -> void:
	var entity := self.entity_scene.instance()
	var assignment: Node = self.default_assignments[type]

	# TODO make this process less fragile by adding an add_entity to assignment
	assignment.slots[-1].add_entity(entity)
	assignment.update_slots()

	entity.make_type(type)
	entity.connect("drag", self, "_on_Entity_drag")
	entity.connect("drop", self, "_on_Entity_drop")
	entity.connect("cancel", self, "_on_Entity_cancel")


func remove_suspicion() -> void:
	var slot: Node = self.default_assignments[Global.SUSPICION].slots[0]
	if slot.entity != null:
		var entity: Node = slot.entity
		slot.remove_entity()
		entity.queue_free()


func change_suspicion(suspicion: int) -> void:
	for _i in range(abs(suspicion)):
		if suspicion < 0:
			self.remove_suspicion()
		else:
			self.create_entity(Global.SUSPICION)


func _enter_tree():
	randomize()


func get_slots() -> Array:
	var slots := []
	for assignment in self.assignments:
		for slot in assignment.slots:
			slots.append(slot)
	return slots


func get_entities() -> Dictionary:
	var entities := {}
	for type in Global.ALL_TYPES:
		entities[type] = []
	for slot in self.get_slots():
		if slot.entity != null:
			entities[slot.entity.type].append(slot.entity)
	return entities


func create_assignment(text: String, allowed_types: Array) -> Node:
	var assignment = self.assignment_scene.instance()
	assignment.name = "%sAssignment" % text.replace(" ", "_")
	assignment.text = text
	assignment.allowed_types = allowed_types
	self.assignments.append(assignment)
	self.assignment_container.add_child(assignment)
	return assignment


func raid() -> void:
	self.popup_label.text = self.TEXT_RAID
	self.popup_spacer.show()
	self.popup_button1.show()
	self.popup_button2.show()
	self.popup_button3.show()

	var entities := self.get_entities()

	# TODO refactor resources so both options can be extracted to a method
	var scapegoats := Global.plural("scapegoat", self.raid_follower_cost)
	if len(entities[Global.FOLLOWER]) > self.raid_follower_cost:
		self.popup_button1.disabled = false

		var indices := Global.get_unique_random_numbers(
			self.raid_follower_cost,
			len(entities[Global.FOLLOWER])
		)

		self.raid_followers_lost.clear()
		var follower_names := []
		for i in indices:
			var follower = entities[Global.FOLLOWER][i]
			self.raid_followers_lost.append(follower)
			follower_names.append(follower.text)

		self.popup_button1.text = "Offer %s: lose %s" % [
			scapegoats,
			Global.array_to_prose(follower_names),
		]
	else:
		self.popup_button1.disabled = true
		self.popup_button1.text = "Offer %s (requires %d spare %s)" % [
			scapegoats,
			self.raid_follower_cost,
			Global.plural("follower", self.raid_follower_cost),
		]

	if len(entities[Global.ARTIFACT]) >= self.raid_artifact_cost:
		self.popup_button2.disabled = false

		var indices := Global.get_unique_random_numbers(
			self.raid_artifact_cost,
			len(entities[Global.ARTIFACT])
		)

		self.raid_artifacts_lost.clear()
		var artifact_names := []
		for i in indices:
			var artifact = entities[Global.ARTIFACT][i]
			self.raid_artifacts_lost.append(artifact)
			artifact_names.append(artifact.text)

		self.popup_button2.text = "Bribe the Watch: lose %s" % Global.array_to_prose(artifact_names)
	else:
		self.popup_button2.disabled = true
		self.popup_button2.text = "Bribe the Watch (requires %d %s)" % [
			self.raid_artifact_cost,
			Global.plural("artifact", self.raid_artifact_cost),
		]

	self.popup_button3.disabled = false
	self.popup_button3.text = "Surrender: GAME OVER"

	self.popup.popup_centered()


func game_over(text: String):
	self.is_game_over = true
	self.popup_label.text = text
	self.popup_button1.text = "Restart"
	self.popup_button2.text = "Quit"
	self.popup_button1.disabled = false
	self.popup_button2.disabled = false
	self.popup_spacer.show()
	self.popup_button1.show()
	self.popup_button2.visible = OS.get_name() != "HTML5"
	self.popup_button3.hide()
	self.popup.popup_centered()


func create_assignments():
	var assignment

	assignment = self.create_assignment("Investigation", [Global.SUSPICION])
	assignment.set_texture(self.investigation_texture)
	assignment.set_max_progress(10)
	assignment.raid = true
	assignment.hide()
	assignment.label_dirty = true
	self.default_assignments[Global.SUSPICION] = assignment

	assignment = self.create_assignment("Artifacts", [Global.ARTIFACT])
	assignment.autohide = true
	assignment.hide()
	assignment.label_dirty = true
	self.default_assignments[Global.ARTIFACT] = assignment

	assignment = self.create_assignment("Idle", [Global.FOLLOWER])
	assignment.label_dirty = true
	self.default_assignments[Global.FOLLOWER] = assignment

	assignment = self.create_assignment("Recruit follower", [Global.FOLLOWER])
	assignment.set_texture(self.recruit_texture)
	assignment.set_max_progress(3)
	assignment.follower_delta = 1
	assignment.suspicion_delta = 1
	assignment.label_dirty = true

	assignment = self.create_assignment("Seek artifact", [Global.FOLLOWER])
	assignment.set_texture(self.seek_texture)
	assignment.set_max_progress(12)
	assignment.artifact_delta = 1
	assignment.suspicion_delta = 2
	assignment.risk = 4
	assignment.max_death_chance = 1.00
	assignment.min_death_chance = 0.20
	assignment.label_dirty = true

	assignment = self.create_assignment("Quell suspicion", [Global.FOLLOWER])
	assignment.set_texture(self.conceal_texture)
	assignment.set_max_progress(4)
	assignment.suspicion_delta = -1
	assignment.risk = 4
	assignment.max_death_chance = 0.25
	assignment.min_death_chance = 0.05
	assignment.label_dirty = true


func start():
	for assignment in self.assignments:
		for slot in assignment.slots:
			if slot.entity != null:
				slot.entity.queue_free()
			slot.queue_free()
		assignment.queue_free()
	self.assignments.clear()
	self.is_game_over = false
	self.set_turn(0)
	self.create_assignments()
	self.create_entity(Global.FOLLOWER)


func _ready():
	self.music.play(0.0)
	if OS.get_name() == "HTML5":
		self.quit_button.hide()
		self.fullscreen_button.pressed = false
	start()


func _on_EndTurnButton_pressed():
	self.end_turn_sound.play()

	var raids := 0
	for assignment in self.assignments:
		var entities: Array = assignment.get_entities()
		if assignment.max_progress == 0 or len(entities) == 0:
			continue
		var new_progress := len(entities)
		var total_progress: int = assignment.progress + new_progress
		var completions: int = total_progress / assignment.max_progress
		assignment.set_progress(total_progress % assignment.max_progress)
		if completions > 0:
			if assignment.raid:
				raids += completions
			self.change_suspicion(assignment.suspicion_delta * completions)
			if assignment.follower_delta != 0 or assignment.artifact_delta != 0:
				for _i in range(completions):
					for _j in range(assignment.follower_delta):
						self.create_entity(Global.FOLLOWER)
					for _j in range(assignment.artifact_delta):
						self.create_entity(Global.ARTIFACT)
		if randf() < assignment.get_death_chance():
			var entity: Node = Global.choice(entities)
			entity.slot.remove_entity()
			entity.queue_free()

	var entities := self.get_entities()

	# TODO multiple raids
	if raids > 0:
		self.raid()

	if self.turn + 1 == self.max_turn:
		var artifact_count = len(entities[Global.ARTIFACT])
		if artifact_count >= 5:
			self.game_over(self.TEXT_WIN % artifact_count)
		else:
			self.game_over(self.TEXT_LOSE_TURN_LIMIT)
	else:
		self.set_turn(self.turn + 1)

	if len(entities[Global.FOLLOWER]) == 0:
		self.game_over(self.TEXT_LOSE_NO_FOLLOWERS)


func _on_PopupButton1_pressed():
	popup.hide()
	if self.is_game_over:
		self.start()
	else:
		for follower in self.raid_followers_lost:
			follower.slot.remove_entity()
			follower.queue_free()


func _on_PopupButton2_pressed():
	popup.hide()
	if self.is_game_over:
		self.get_tree().quit()
	else:
		for artifact in self.raid_artifacts_lost:
			artifact.slot.remove_entity()
			artifact.queue_free()


func _on_PopupButton3_pressed():
	popup.hide()
	self.game_over(self.TEXT_LOSE_SURRENDER)


func _on_Entity_drag():
	self.drag_sound.play()


func _on_Entity_drop():
	self.drop_sound.play()


func _on_Entity_cancel():
	self.cancel_sound.play()


func _on_SoundButton_pressed():
	AudioServer.set_bus_mute(Global.SOUND_BUS, not AudioServer.is_bus_mute(Global.SOUND_BUS))


func _on_MusicButton_pressed():
	AudioServer.set_bus_mute(Global.MUSIC_BUS, not AudioServer.is_bus_mute(Global.MUSIC_BUS))


func _on_QuitButton_pressed():
	get_tree().quit()


func _on_FullscreenButton_pressed():
	OS.window_fullscreen = !OS.window_fullscreen
