extends Control
class_name Main


const TEXT_WIN := "The conjunction is at hand.\n\nThrough secretive and tireless search, you have gathered %d artifacts. Harnessing their ancient energies, you tear a rift in the planes, whenceforth cometh eldritch beings of ineffable might.\n\nVICTORY?"
const TEXT_LOSE_TURN_LIMIT := "The conjunction is at hand.\n\nDespite your unshakeable devotion, you could not gather enough artifacts in time. The stars in their cosmic dance align once in a brief, majestic formation, but it is all for naught.\n\nFAILURE..."
const TEXT_LOSE_NO_FOLLOWERS := "The last of your followers has fallen. With none to perform the summoning rites, the conjunction passes quietly. The gods shall sleep for another millenium.\n\nFAILURE..."
const TEXT_LOSE_SURRENDER := "Reluctantly, you submit yourself and your accomplices to arrest. Many years will pass as you languish in the cold, stone jails of the Watch, wistfully watching the constellations whirl from behind iron bars.\n\nFAILURE..."
const TEXT_RAID := "The wolves are at the door.\n\nYour conjurations and clandestine operations were not as well concealed as you had hoped. Investigators from the Watch have picked up your trail. A truncheon knocks upon the door of your secret chamber and ultimatums are shouted.\n\nHow shall you respond?"

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

const rumors_texture := preload("res://sprites/assignments/rumors.png")
const investigation_texture := preload("res://sprites/assignments/investigation.png")
const recruit_texture := preload("res://sprites/assignments/recruit.png")
const work_texture := preload("res://sprites/assignments/work.png")
const seek_texture := preload("res://sprites/assignments/seek.png")
const conceal_texture := preload("res://sprites/assignments/conceal.png")
const research_texture := preload("res://sprites/assignments/research.png")

var default_assignments := {}

onready var turn_label: Label = self.find_node("TurnLabel")
onready var assignment_container1: Container = self.find_node("AssignmentContainer1")
onready var assignment_container2: Container = self.find_node("AssignmentContainer2")
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


func create_entity(type: int) -> Entity:
	var entity: Entity = self.entity_scene.instance()
	entity.make_type(type)
	entity.connect("drag", self, "_on_Entity_drag")
	entity.connect("drop", self, "_on_Entity_drop")
	entity.connect("cancel", self, "_on_Entity_cancel")
	entity.connect("request", self, "_on_Entity_request")
	return entity


func add_entity(entity: Entity) -> void:
	var assignment: Assignment = self.default_assignments[entity.type]
	# TODO make this process less fragile by adding an add_entity to assignment
	assignment.add_entity(entity)


func destroy_resource(type: int) -> void:
	var assignment: Assignment = self.default_assignments[type]
	var slot: Slot = assignment.slots[0]
	if slot.entity != null:
		var entity: Entity = slot.entity
		slot.remove_entity()
		entity.queue_free()
		assignment.update_slots()


func change_resource(type: int, delta: int) -> void:
	for _i in range(abs(delta)):
		if delta < 0:
			self.destroy_resource(type)
		else:
			self.add_entity(self.create_entity(type))


func return_entity(entity: Entity) -> void:
	entity.slot.remove_entity()
	self.add_entity(entity)


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


func destroy_assignment(assignment: Assignment) -> void:
	for entity in assignment.get_entities():
		self.return_entity(entity)
	self.assignments.erase(assignment)
	assignment.queue_free()


func create_assignment(
	type := Global.AssignmentTypes.GENERIC,
	container := self.assignment_container2
) -> Assignment:
	var assignment = self.assignment_scene.instance()
	self.assignments.append(assignment)
	container.add_child(assignment)
	assignment.connect("request", self, "_on_Assignment_request")

	assignment.type = type
	match type:
		Global.AssignmentTypes.ARTIFACT_QUEST:
			var artifact := self.create_entity(Global.Types.ARTIFACT)
			assignment.gained_entities.append(artifact)
			assignment.set_text("Seek the %s" % artifact.text)
			assignment.set_texture(artifact.texture)
			# TODO balance quest difficulty with artifact power
			assignment.set_max_progress(randi() % 6 * 2 + 10)
			assignment.exhausts = true
			assignment.type_deltas = {
				Global.Types.WEALTH: max(0, randi() % 6 * 2 - 4),
				Global.Types.SUSPICION: randi() % 4 + 2,
			}
			assignment.risk = randi() % 8 + 3
			assignment.max_death_chance = float(randi() % 6 + 5) * 0.10
			assignment.min_death_chance = float(randi() % 3 + 1) * 0.10
			assignment.set_template_slot(self.slot_scene.instance())
			assignment.template_slot.allowed_types = [Global.Types.FOLLOWER]
			assignment.label_dirty = true
			assignment.update_slots()
	return assignment


func create_assignments():
	var assignment: Assignment
	var slot: Slot

	assignment = self.create_assignment(
		Global.AssignmentTypes.GENERIC,
		self.assignment_container1
	)
	assignment.set_text("Investigation")
	assignment.set_max_progress(10)
	assignment.raid = true
	slot = self.slot_scene.instance()
	slot.consumed = true
	slot.allowed_types = [Global.Types.SUSPICION]
	assignment.add_slot(slot)
	assignment.set_template_slot(self.slot_scene.instance())
	assignment.template_slot.allowed_types = [Global.Types.SUSPICION]
	assignment.set_texture(self.investigation_texture)
	assignment.label_dirty = true
	assignment.update_slots()
	assignment.hide()
	self.default_assignments[Global.Types.SUSPICION] = assignment


#	assignment = self.create_assignment(
#		Global.AssignmentTypes.GENERIC,
#		self.assignment_container1
#	)
#	assignment.set_text("Rumors")
#	assignment.set_max_progress(20)
#	assignment.type_deltas = {
#		Global.Types.INVESTIGATOR: +1,
#	}
#	slot = self.slot_scene.instance()
#	slot.consumed = true
#	slot.allowed_types = [Global.Types.SUSPICION]
#	assignment.add_slot(slot)
#	assignment.set_template_slot(self.slot_scene.instance()
#	assignment.template_slot.allowed_types = [Global.Types.SUSPICION]
#	assignment.set_texture(self.rumors_texture)
#	assignment.label_dirty = true
#	assignment.update_slots()
#	assignment.hide()
#	self.default_assignments[Global.Types.SUSPICION] = assignment
#
#	assignment = self.create_assignment(
#		Global.AssignmentTypes.GENERIC,
#		self.assignment_container1
#	)
#	assignment.set_text("Investigation")
#	assignment.set_max_progress(10)
#	assignment.raid = true
#	assignment.set_template_slot(self.slot_scene.instance()
#	assignment.template_slot.allowed_types = [Global.Types.INVESTIGATOR]
#	assignment.template_slot.consumed = true
#	assignment.set_texture(self.investigation_texture)
#	assignment.label_dirty = true
#	assignment.update_slots()
#	assignment.hide()
#	self.default_assignments[Global.Types.INVESTIGATOR] = assignment

	assignment = self.create_assignment(
		Global.AssignmentTypes.GENERIC,
		self.assignment_container1
	)
	assignment.set_text("Wealth")
	assignment.set_template_slot(self.slot_scene.instance())
	assignment.template_slot.allowed_types = [Global.Types.WEALTH]
	assignment.label_dirty = true
	assignment.update_slots()
	assignment.hide()
	self.default_assignments[Global.Types.WEALTH] = assignment

	assignment = self.create_assignment(
		Global.AssignmentTypes.GENERIC,
		self.assignment_container1
	)
	assignment.set_text("Artifacts")
	assignment.set_template_slot(self.slot_scene.instance())
	assignment.template_slot.allowed_types = [Global.Types.ARTIFACT]
	assignment.label_dirty = true
	assignment.update_slots()
	assignment.hide()
	self.default_assignments[Global.Types.ARTIFACT] = assignment

	assignment = self.create_assignment(
		Global.AssignmentTypes.GENERIC,
		self.assignment_container1
	)
	assignment.set_text("Idle")
	assignment.set_template_slot(self.slot_scene.instance())
	assignment.template_slot.allowed_types = [Global.Types.FOLLOWER]
	assignment.label_dirty = true
	assignment.update_slots()
	self.default_assignments[Global.Types.FOLLOWER] = assignment

	assignment = self.create_assignment()
	assignment.set_text("Recruit follower")
	assignment.set_texture(self.recruit_texture)
	assignment.set_max_progress(3)
	assignment.type_deltas = {
		Global.Types.FOLLOWER: +1,
		Global.Types.SUSPICION: +1,
	}
	assignment.set_template_slot(self.slot_scene.instance())
	assignment.template_slot.allowed_types = [Global.Types.FOLLOWER]
	assignment.label_dirty = true
	assignment.update_slots()

	assignment = self.create_assignment()
	assignment.set_text("Work")
	assignment.set_texture(self.work_texture)
	assignment.set_max_progress(2)
	assignment.type_deltas = {
		Global.Types.WEALTH: +1,
	}
	assignment.set_template_slot(self.slot_scene.instance())
	assignment.template_slot.allowed_types = [Global.Types.FOLLOWER]
	assignment.label_dirty = true
	assignment.update_slots()

	assignment = self.create_assignment()
	assignment.set_text("Research artifacts")
	assignment.set_texture(self.research_texture)
	assignment.set_max_progress(8)
	assignment.gained_assignments = [Global.AssignmentTypes.ARTIFACT_QUEST]
	assignment.set_template_slot(self.slot_scene.instance())
	assignment.template_slot.allowed_types = [Global.Types.FOLLOWER]
	assignment.label_dirty = true
	assignment.update_slots()

	assignment = self.create_assignment()
	assignment.set_text("Bribe the Watch")
	assignment.set_texture(self.conceal_texture)
	assignment.set_max_progress(1)
	slot = self.slot_scene.instance()
	slot.progress = 1
	slot.required = true
	slot.consumed = true
	slot.allowed_types = [Global.Types.WEALTH]
	assignment.add_slot(slot)
	slot = self.slot_scene.instance()
	slot.progress = 0
	slot.required = true
	slot.consumed = true
	slot.allowed_types = [Global.Types.SUSPICION]
	assignment.add_slot(slot)
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
	self.add_entity(self.create_entity(Global.Types.FOLLOWER))


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

	var type_deltas := {}
	for type in Global.Types.values():
		type_deltas[type] = 0
	var raids := 0
	var i := 0
	while i < len(self.assignments):
		var assignment: Assignment = self.assignments[i]
		if assignment.max_progress == 0:
			i += 1
			continue

		var added_progress: int = assignment.get_added_progress()
		if added_progress == 0:
			i += 1
			continue

		var entities: Array = assignment.get_entities()
		var total_progress: int = assignment.progress + added_progress
		var completions: int = total_progress / assignment.max_progress
		assignment.set_progress(total_progress % assignment.max_progress)

		if randf() < assignment.get_death_chance() and len(entities) > 0:
			var entity: Entity = Global.choice(entities)
			entity.slot.remove_entity()
			entity.queue_free()

		if completions > 0:
			if assignment.raid:
				raids += completions

			for _i in range(completions):
				for assignment_type in assignment.gained_assignments:
					self.create_assignment(assignment_type)

			for entity in assignment.gained_entities:
				self.add_entity(entity)

			for type in assignment.type_deltas:
				type_deltas[type] += assignment.type_deltas[type] * completions

			for slot in assignment.slots:
				if slot.consumed and slot.entity != null:
					slot.remove_entity().queue_free()
			entities = assignment.get_entities()

			if assignment.exhausts:
				self.destroy_assignment(assignment)
				continue
		i += 1

	for type in type_deltas:
		self.change_resource(type, type_deltas[type])

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


func _on_Entity_request(entity: Entity):
	if entity.slot.assignment == self.default_assignments[entity.type]:
		self.cancel_sound.play()
	else:
		self.return_entity(entity)
		self.drop_sound.play()


func _on_Assignment_request(slot: Slot):
	if not slot.assignment in self.default_assignments.values():
		for type in slot.allowed_types:
			var assignment: Assignment = self.default_assignments[type]
			for i in range(len(assignment.slots) - 1, -1, -1):
				var source_slot: Slot = assignment.slots[i]
				var entity: Entity = source_slot.entity
				if entity != null:
					source_slot.remove_entity()
					slot.add_entity(entity)
					self.drag_sound.play()
					return
	self.cancel_sound.play()


func _on_SoundButton_pressed():
	AudioServer.set_bus_mute(Global.SOUND_BUS, not self.sound_button.pressed)


func _on_MusicButton_pressed():
	AudioServer.set_bus_mute(Global.MUSIC_BUS, not self.music_button.pressed)


func _on_FullscreenButton_pressed():
	OS.window_fullscreen = self.fullscreen_button.pressed


func _on_QuitButton_pressed():
	get_tree().quit()
