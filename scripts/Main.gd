extends Control


const TEXT_WIN := "The conjunction is at hand.\n\nThrough secretive and tireless search, you have gathered %d artifacts. Harnessing their ancient energies, you tear a rift in the planes, whenceforth cometh eldritch beings of ineffable might.\n\nVICTORY?"
const TEXT_LOSE_TURN_LIMIT := "The conjunction is at hand.\n\nDespite your unshakeable devotion, you could not gather enough artifacts in time. The stars in their cosmic dance align once in a brief, majestic formation, but it is all for naught.\n\nFAILURE..."
const TEXT_LOSE_NO_FOLLOWERS := "The last of your followers has fallen. With none to perform the summoning rites, the conjunction passes quietly. The gods shall sleep for another millenium.\n\nFAILURE..."
const TEXT_LOSE_SURRENDER := "Reluctantly, you submit yourself and your accomplices to arrest. Many years will pass as you languish in the cold, stone jails of the Watch, wistfully watching the constellations whirl from behind iron bars.\n\nFAILURE..."
const TEXT_RAID := "The wolves are at the door.\n\nYour conjurations and clandestine operations were not as well concealed as you had hoped. Investigators from the Watch have picked up your trail. A truncheon knocks upon the door of your secret chamber and ultimatums are shouted.\n\nHow shall you respond?"

const raid_costs := {
	Global.Types.FOLLOWER: 2,
	Global.Types.ARTIFACT: 1,
}
var raid_losses := {
	Global.Types.FOLLOWER: [],
	Global.Types.ARTIFACT: [],
}

var turn := 0
const max_turn := 52
var assignments := []
var is_game_over := false

const assignment_scene := preload("res://scenes/Assignment.tscn")
const slot_scene := preload("res://scenes/Slot.tscn")
const entity_scene := preload("res://scenes/Entity.tscn")

const investigation_texture := preload("res://sprites/investigation.png")
const recruit_texture := preload("res://sprites/recruit.png")
const work_texture := preload("res://sprites/work.png")
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
onready var sound_button: Button = self.find_node("SoundButton")
onready var music_button: Button = self.find_node("MusicButton")
onready var fullscreen_button: Button = self.find_node("FullscreenButton")

onready var drag_sound: AudioStreamPlayer = self.find_node("DragSound")
onready var drop_sound: AudioStreamPlayer = self.find_node("DropSound")
onready var cancel_sound: AudioStreamPlayer = self.find_node("CancelSound")
onready var end_turn_sound: AudioStreamPlayer = self.find_node("EndTurnSound")
onready var music: AudioStreamPlayer = self.find_node("Music")


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


func destroy_resource(type: int) -> void:
	var assignment: Node = self.default_assignments[type]
	var slot: Node = assignment.slots[0]
	if slot.entity != null:
		var entity: Node = slot.entity
		slot.remove_entity()
		entity.queue_free()
		assignment.update_slots()


func change_resource(type: int, delta: int) -> void:
	for _i in range(abs(delta)):
		if delta < 0:
			self.destroy_resource(type)
		else:
			self.create_entity(type)


func get_slots() -> Array:
	var slots := []
	for assignment in self.assignments:
		for slot in assignment.slots:
			slots.append(slot)
	return slots


func get_entities() -> Dictionary:
	var entities := {}
	for type in Global.Types.values():
		entities[type] = []
	for slot in self.get_slots():
		if slot.entity != null:
			entities[slot.entity.type].append(slot.entity)
	return entities


func create_assignment(text: String) -> Node:
	var assignment = self.assignment_scene.instance()
	assignment.name = "%sAssignment" % text.replace(" ", "_")
	assignment.text = text
	self.assignments.append(assignment)
	self.assignment_container.add_child(assignment)
	return assignment


func set_raid_option(
	button: Button,
	entities: Dictionary,
	type: int,
	cost: int,
	option_text: String
) -> void:
	if len(entities[type]) >= cost:
		button.disabled = false
		var indices := Global.get_unique_random_numbers(cost, len(entities[type]))
		self.raid_losses[type].clear()
		var entity_names := []
		for i in indices:
			var entity = entities[type][i]
			self.raid_losses[type].append(entity)
			entity_names.append(entity.text)

		button.text = "%s: lose %s" % [
			option_text,
			Global.array_to_prose(entity_names),
		]
	else:
		button.disabled = true
		button.text = "%s (requires %d %s)" % [
			option_text,
			cost,
			Global.plural(Global.TYPE_NAMES[type], cost),
		]

func raid() -> void:
	self.popup_label.text = self.TEXT_RAID
	self.popup_spacer.show()
	self.popup_button1.show()
	self.popup_button2.show()
	self.popup_button3.show()

	var entities := self.get_entities()

	self.set_raid_option(
		self.popup_button1,
		entities,
		Global.Types.FOLLOWER,
		2,
		"Offer scapegoats"
	)

	self.set_raid_option(
		self.popup_button2,
		entities,
		Global.Types.ARTIFACT,
		1,
		"Invoke artifact"
	)

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
	var assignment: Node
	var slot: Node

	assignment = self.create_assignment("Investigation")
	assignment.set_max_progress(10)
	assignment.raid = true
	slot = self.slot_scene.instance()
	slot.allowed_types = [Global.Types.SUSPICION]
	slot.consumed = false
	assignment.template_slot = slot
	assignment.set_texture(self.investigation_texture)
	assignment.label_dirty = true
	assignment.update_slots()
	assignment.hide()
	self.default_assignments[Global.Types.SUSPICION] = assignment

	assignment = self.create_assignment("Wealth")
	slot = self.slot_scene.instance()
	slot.allowed_types = [Global.Types.WEALTH]
	slot.consumed = false
	assignment.template_slot = slot
	assignment.label_dirty = true
	assignment.update_slots()
	assignment.hide()
	self.default_assignments[Global.Types.WEALTH] = assignment

	assignment = self.create_assignment("Artifacts")
	slot = self.slot_scene.instance()
	slot.allowed_types = [Global.Types.ARTIFACT]
	slot.consumed = false
	assignment.template_slot = slot
	assignment.label_dirty = true
	assignment.update_slots()
	assignment.hide()
	self.default_assignments[Global.Types.ARTIFACT] = assignment

	assignment = self.create_assignment("Idle")
	slot = self.slot_scene.instance()
	slot.allowed_types = [Global.Types.FOLLOWER]
	slot.consumed = false
	assignment.template_slot = slot
	assignment.label_dirty = true
	assignment.update_slots()
	self.default_assignments[Global.Types.FOLLOWER] = assignment

	assignment = self.create_assignment("Recruit follower")
	assignment.set_texture(self.recruit_texture)
	assignment.set_max_progress(3)
	assignment.type_deltas = {
		Global.Types.FOLLOWER: +1,
		Global.Types.SUSPICION: +1,
	}
	slot = self.slot_scene.instance()
	slot.allowed_types = [Global.Types.FOLLOWER]
	slot.consumed = false
	assignment.template_slot = slot
	assignment.label_dirty = true
	assignment.update_slots()

	assignment = self.create_assignment("Work")
	assignment.set_texture(self.work_texture)
	assignment.set_max_progress(2)
	assignment.type_deltas = {
		Global.Types.WEALTH: +1,
	}
	slot = self.slot_scene.instance()
	slot.allowed_types = [Global.Types.FOLLOWER]
	slot.consumed = false
	assignment.template_slot = slot
	assignment.label_dirty = true
	assignment.update_slots()

	assignment = self.create_assignment("Seek artifact")
	assignment.set_texture(self.seek_texture)
	assignment.set_max_progress(12)
	assignment.type_deltas = {
		Global.Types.ARTIFACT: +1,
		Global.Types.SUSPICION: +2,
	}
	assignment.risk = 4
	assignment.max_death_chance = 1.00
	assignment.min_death_chance = 0.20
	slot = self.slot_scene.instance()
	slot.allowed_types = [Global.Types.FOLLOWER]
	slot.consumed = false
	assignment.template_slot = slot
	assignment.label_dirty = true
	assignment.update_slots()

	assignment = self.create_assignment("Bribe the Watch")
	assignment.set_texture(self.conceal_texture)
	assignment.set_max_progress(1)
	assignment.type_deltas = {
		Global.Types.SUSPICION: -1,
	}
	slot = self.slot_scene.instance()
	slot.allowed_types = [Global.Types.WEALTH]
	slot.consumed = true
	assignment.template_slot = slot
	assignment.label_dirty = true
	assignment.update_slots()


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
	self.create_entity(Global.Types.FOLLOWER)


func _init():
	randomize()


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
			for type in assignment.type_deltas:
				self.change_resource(type, assignment.type_deltas[type] * completions)
			for slot in assignment.slots:
				if slot.consumed and slot.entity != null:
					slot.remove_entity().queue_free()
			entities = assignment.get_entities()
		if randf() < assignment.get_death_chance() and len(entities) > 0:
			var entity: Node = Global.choice(entities)
			entity.slot.remove_entity()
			entity.queue_free()

	var entities := self.get_entities()

	# TODO multiple raids
	if raids > 0:
		self.raid()

	if self.turn + 1 == self.max_turn:
		var artifact_count = len(entities[Global.Types.ARTIFACT])
		if artifact_count >= 5:
			self.game_over(self.TEXT_WIN % artifact_count)
		else:
			self.game_over(self.TEXT_LOSE_TURN_LIMIT)
	else:
		self.set_turn(self.turn + 1)

	if len(entities[Global.Types.FOLLOWER]) == 0:
		self.game_over(self.TEXT_LOSE_NO_FOLLOWERS)


func destroy_raid_losses(type: int) -> void:
	for entity in self.raid_losses[type]:
		entity.slot.remove_entity()
		entity.queue_free()


func _on_PopupButton1_pressed():
	popup.hide()
	if self.is_game_over:
		self.start()
	else:
		self.destroy_raid_losses(Global.Types.FOLLOWER)
		if len(self.get_entities()[Global.Types.FOLLOWER]) == 0:
			self.game_over(self.TEXT_LOSE_SURRENDER)


func _on_PopupButton2_pressed():
	popup.hide()
	if self.is_game_over:
		self.get_tree().quit()
	else:
		self.destroy_raid_losses(Global.Types.ARTIFACT)


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
	AudioServer.set_bus_mute(Global.SOUND_BUS, not self.sound_button.pressed)


func _on_MusicButton_pressed():
	AudioServer.set_bus_mute(Global.MUSIC_BUS, not self.music_button.pressed)


func _on_FullscreenButton_pressed():
	OS.window_fullscreen = self.fullscreen_button.pressed


func _on_QuitButton_pressed():
	get_tree().quit()
