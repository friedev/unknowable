class_name Main extends Control

const TEXT_WIN := "The conjunction is at hand.\n\nThrough secretive and tireless search, you have gathered %d artifacts. Harnessing their ancient energies, you tear a rift in the planes, whenceforth cometh eldritch beings of ineffable might.\n\nVICTORY?"
const TEXT_LOSE_TURN_LIMIT := "The conjunction is at hand.\n\nDespite your unshakeable devotion, you could not gather enough artifacts in time. The stars in their cosmic dance align once in a brief, majestic formation, but it is all for naught.\n\nFAILURE..."
const TEXT_LOSE_NO_FOLLOWERS := "The last of your followers has fallen. With none to perform the summoning rites, the conjunction passes quietly. The gods shall sleep for another millenium.\n\nFAILURE..."
const TEXT_LOSE_SURRENDER := "Reluctantly, you submit yourself and your accomplices to arrest. Many years will pass as you languish in the cold, stone jails of the Watch, wistfully watching the constellations whirl from behind iron bars.\n\nFAILURE..."
const TEXT_RAID := "The wolves are at the door.\n\nYour conjurations and clandestine operations were not as well concealed as you had hoped. Investigators from the Watch have picked up your trail. A truncheon knocks upon the door of your secret chamber and ultimatums are shouted.\n\nHow shall you respond?"

var raid_losses := {}

var turn := 0
const max_turn := 52
var assignments := []
var is_game_over := false

@export var assignment_scene: PackedScene
@export var slot_scene: PackedScene
@export var entity_scene: PackedScene

const rumors_texture := preload("res://sprites/assignments/rumors.png")
const investigation_texture := preload("res://sprites/assignments/investigation.png")
const recruit_texture := preload("res://sprites/assignments/recruit.png")
const work_texture := preload("res://sprites/assignments/work.png")
const seek_texture := preload("res://sprites/assignments/seek.png")
const conceal_texture := preload("res://sprites/assignments/conceal.png")
const research_texture := preload("res://sprites/assignments/research.png")

var default_assignments := {}

@onready var turn_label: Label = %TurnLabel
@onready var assignment_container1: Container = %AssignmentContainer1
@onready var assignment_container2: Container = %AssignmentContainer2
@onready var popup: Control = %Popup
@onready var popup_label: Label = %PopupLabel
@onready var popup_spacer: Label = %PopupSpacer
@onready var popup_button1: Button = %PopupButton1
@onready var popup_button2: Button = %PopupButton2
@onready var popup_button3: Button = %PopupButton3
@onready var quit_button: Button = %QuitButton
@onready var sound_button: Button = %SoundButton
@onready var music_button: Button = %MusicButton
@onready var fullscreen_button: Button = %FullscreenButton

@onready var drag_sound: AudioStreamPlayer = %DragSound
@onready var drop_sound: AudioStreamPlayer = %DropSound
@onready var cancel_sound: AudioStreamPlayer = %CancelSound
@onready var end_turn_sound: AudioStreamPlayer = %EndTurnSound
@onready var music: AudioStreamPlayer = %Music


func set_turn(turn: int) -> void:
	self.turn = clamp(0, turn, max_turn)
	turn_label.text = "Week %d of %d" % [self.turn + 1, max_turn]


func create_entity(type: int) -> Entity:
	var entity: Entity = entity_scene.instantiate()
	entity.make_type(type)
	entity.connect("drag", Callable(self, "_on_Entity_drag"))
	entity.connect("drop", Callable(self, "_on_Entity_drop"))
	entity.connect("cancel", Callable(self, "_on_Entity_cancel"))
	entity.connect("request", Callable(self, "_on_Entity_request"))
	return entity


func add_entity(entity: Entity) -> void:
	var assignment: Assignment = default_assignments[entity.type]
	# TODO make this process less fragile by adding an add_entity to assignment
	assignment.add_entity(entity)


func destroy_resource(type: int) -> void:
	var assignment: Assignment = default_assignments[type]
	var slot: Slot = assignment.slots[0]
	if slot.entity != null:
		var entity: Entity = slot.entity
		slot.remove_entity()
		entity.queue_free()
		assignment.update_slots()


func change_resource(type: int, delta: int) -> void:
	for _i in range(abs(delta)):
		if delta < 0:
			destroy_resource(type)
		else:
			add_entity(create_entity(type))


func return_entity(entity: Entity) -> void:
	entity.slot.remove_entity()
	add_entity(entity)


func get_slots() -> Array:
	var slots := []
	for assignment in assignments:
		for slot in assignment.slots:
			slots.append(slot)
	return slots


func get_entities() -> Dictionary:
	var entities := {}
	for type in Global.Types.values():
		entities[type] = []
	for slot in get_slots():
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
		if type in raid_losses:
			raid_losses[type].clear()
		else:
			raid_losses[type] = []
		var entity_names := []
		for i in indices:
			var entity = entities[type][i]
			raid_losses[type].append(entity)
			entity_names.append(entity.text)

		# Reverted from a version that named all entities
		button.text = "%s: lose %d %s" % [
			option_text,
			cost,
			Global.plural(Global.TYPE_NAMES[type], cost),
		]
	else:
		button.disabled = true
		button.text = "%s (requires %d %s)" % [
			option_text,
			cost,
			Global.plural(Global.TYPE_NAMES[type], cost),
		]

func raid() -> void:
	popup_label.text = TEXT_RAID
	popup_spacer.show()
	popup_button1.show()
	popup_button2.show()
	popup_button3.show()

	var entities := get_entities()

	set_raid_option(
		popup_button1,
		entities,
		Global.Types.FOLLOWER,
		10,
		"Offer scapegoats"
	)

	set_raid_option(
		popup_button2,
		entities,
		Global.Types.WEALTH,
		10,
		"Pay ransom"
	)

	popup_button3.disabled = false
	popup_button3.text = "Turn yourselves in: GAME OVER"

	popup.show()


func game_over(text: String):
	is_game_over = true
	popup_label.text = text
	popup_button1.text = "Restart"
	popup_button2.text = "Quit"
	popup_button1.disabled = false
	popup_button2.disabled = false
	popup_spacer.show()
	popup_button1.show()
	popup_button2.visible = OS.get_name() != "Web"
	popup_button3.hide()
	popup.show()


func destroy_assignment(assignment: Assignment) -> void:
	for entity in assignment.get_entities():
		return_entity(entity)
	assignments.erase(assignment)
	assignment.queue_free()


func create_assignment(
	type := Global.AssignmentTypes.GENERIC,
	container := assignment_container2
) -> Assignment:
	var assignment = assignment_scene.instantiate()
	assignments.append(assignment)
	container.add_child(assignment)
	assignment.connect("request", Callable(self, "_on_Assignment_request"))

	assignment.type = type
	match type:
		Global.AssignmentTypes.ARTIFACT_QUEST:
			var artifact := create_entity(Global.Types.ARTIFACT)
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
			assignment.set_template_slot(slot_scene.instantiate())
			assignment.template_slot.allowed_types = [Global.Types.FOLLOWER]
			assignment.label_dirty = true
			assignment.update_slots()
	return assignment


func create_assignments():
	var assignment: Assignment
	var slot: Slot

	assignment = create_assignment(
		Global.AssignmentTypes.GENERIC,
		assignment_container1
	)
	assignment.set_text("Investigation")
	assignment.set_max_progress(10)
	assignment.raid = true
#	slot = slot_scene.instantiate()
#	slot.consumed = true
#	slot.allowed_types = [Global.Types.SUSPICION]
#	assignment.add_slot(slot)
	assignment.set_template_slot(slot_scene.instantiate())
	assignment.template_slot.allowed_types = [Global.Types.SUSPICION]
	assignment.set_texture(investigation_texture)
	assignment.label_dirty = true
	assignment.update_slots()
	assignment.hide()
	default_assignments[Global.Types.SUSPICION] = assignment

#	assignment = create_assignment(
#		Global.AssignmentTypes.GENERIC,
#		assignment_container1
#	)
#	assignment.set_text("Rumors")
#	assignment.set_max_progress(20)
#	assignment.type_deltas = {
#		Global.Types.INVESTIGATOR: +1,
#	}
#	slot = slot_scene.instantiate()
#	slot.consumed = true
#	slot.allowed_types = [Global.Types.SUSPICION]
#	assignment.add_slot(slot)
#	assignment.set_template_slot(slot_scene.instantiate())
#	assignment.template_slot.allowed_types = [Global.Types.SUSPICION]
#	assignment.set_texture(rumors_texture)
#	assignment.label_dirty = true
#	assignment.update_slots()
#	assignment.hide()
#	default_assignments[Global.Types.SUSPICION] = assignment
#
#	assignment = create_assignment(
#		Global.AssignmentTypes.GENERIC,
#		assignment_container1
#	)
#	assignment.set_text("Investigation")
#	assignment.set_max_progress(10)
#	assignment.raid = true
#	assignment.set_template_slot(slot_scene.instantiate())
#	assignment.template_slot.allowed_types = [Global.Types.INVESTIGATOR]
#	assignment.template_slot.consumed = true
#	assignment.set_texture(investigation_texture)
#	assignment.label_dirty = true
#	assignment.update_slots()
#	assignment.hide()
#	default_assignments[Global.Types.INVESTIGATOR] = assignment

	assignment = create_assignment(
		Global.AssignmentTypes.GENERIC,
		assignment_container1
	)
	assignment.set_text("Wealth")
	assignment.set_template_slot(slot_scene.instantiate())
	assignment.template_slot.allowed_types = [Global.Types.WEALTH]
	assignment.label_dirty = true
	assignment.update_slots()
	assignment.hide()
	default_assignments[Global.Types.WEALTH] = assignment

	assignment = create_assignment(
		Global.AssignmentTypes.GENERIC,
		assignment_container1
	)
	assignment.set_text("Artifacts")
	assignment.set_template_slot(slot_scene.instantiate())
	assignment.template_slot.allowed_types = [Global.Types.ARTIFACT]
	assignment.label_dirty = true
	assignment.update_slots()
	assignment.hide()
	default_assignments[Global.Types.ARTIFACT] = assignment

	assignment = create_assignment(
		Global.AssignmentTypes.GENERIC,
		assignment_container1
	)
	assignment.set_text("Idle")
	assignment.set_template_slot(slot_scene.instantiate())
	assignment.template_slot.allowed_types = [Global.Types.FOLLOWER]
	assignment.label_dirty = true
	assignment.update_slots()
	default_assignments[Global.Types.FOLLOWER] = assignment

	assignment = create_assignment()
	assignment.set_text("Recruit follower")
	assignment.set_texture(recruit_texture)
	assignment.set_max_progress(3)
	assignment.max_slots = 9
	assignment.type_deltas = {
		Global.Types.FOLLOWER: +1,
		Global.Types.SUSPICION: +1,
	}
	assignment.set_template_slot(slot_scene.instantiate())
	assignment.template_slot.allowed_types = [Global.Types.FOLLOWER]
	assignment.label_dirty = true
	assignment.update_slots()

	assignment = create_assignment()
	assignment.set_text("Work")
	assignment.set_texture(work_texture)
	assignment.set_max_progress(2)
	assignment.max_slots = 10
	assignment.type_deltas = {
		Global.Types.WEALTH: +1,
	}
	assignment.set_template_slot(slot_scene.instantiate())
	assignment.template_slot.allowed_types = [Global.Types.FOLLOWER]
	assignment.label_dirty = true
	assignment.update_slots()

	assignment = create_assignment()
	assignment.set_text("Research artifacts")
	assignment.set_texture(research_texture)
	assignment.set_max_progress(8)
	assignment.gained_assignments = [Global.AssignmentTypes.ARTIFACT_QUEST]
	assignment.set_template_slot(slot_scene.instantiate())
	assignment.template_slot.allowed_types = [Global.Types.FOLLOWER]
	assignment.label_dirty = true
	assignment.update_slots()

	assignment = create_assignment()
	assignment.set_text("Bribe the Watch")
	assignment.set_texture(conceal_texture)
	assignment.set_max_progress(1)
	slot = slot_scene.instantiate()
	slot.progress = 1
	slot.required = true
	slot.consumed = true
	slot.allowed_types = [Global.Types.WEALTH]
	assignment.add_slot(slot)
	slot = slot_scene.instantiate()
	slot.progress = 0
	slot.required = true
	slot.consumed = true
	slot.allowed_types = [Global.Types.SUSPICION]
	assignment.add_slot(slot)
	assignment.label_dirty = true
	assignment.update_slots()


func start():
	for assignment in assignments:
		for slot in assignment.slots:
			if slot.entity != null:
				slot.entity.queue_free()
			slot.queue_free()
		assignment.queue_free()
	assignments.clear()
	is_game_over = false
	set_turn(0)
	create_assignments()
	add_entity(create_entity(Global.Types.FOLLOWER))


func _init():
	randomize()


func _ready():
	music.play(0.0)
	if OS.get_name() == "Web":
		quit_button.hide()
		fullscreen_button.button_pressed = false
	start()


func _on_EndTurnButton_pressed():
	if popup.visible:
		return

	end_turn_sound.play()

	var type_deltas := {}
	for type in Global.Types.values():
		type_deltas[type] = 0
	var raids := 0
	var i := 0
	while i < len(assignments):
		var assignment: Assignment = assignments[i]
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
					create_assignment(assignment_type)

			for entity in assignment.gained_entities:
				add_entity(entity)

			for type in assignment.type_deltas:
				type_deltas[type] += assignment.type_deltas[type] * completions

			for slot in assignment.slots:
				if slot.consumed and slot.entity != null:
					slot.remove_entity().queue_free()
			entities = assignment.get_entities()

			if assignment.exhausts:
				destroy_assignment(assignment)
				continue
		i += 1

	for type in type_deltas:
		change_resource(type, type_deltas[type])

	var entities := get_entities()

	# TODO multiple raids
	if raids > 0:
		raid()

	if turn + 1 == max_turn:
		var artifact_count = len(entities[Global.Types.ARTIFACT])
		if artifact_count >= 5:
			game_over(TEXT_WIN % artifact_count)
		else:
			game_over(TEXT_LOSE_TURN_LIMIT)
	else:
		set_turn(turn + 1)

	if len(entities[Global.Types.FOLLOWER]) == 0:
		game_over(TEXT_LOSE_NO_FOLLOWERS)


func destroy_raid_losses(type: int) -> void:
	for entity in raid_losses[type]:
		entity.slot.remove_entity()
		entity.queue_free()


func _on_PopupButton1_pressed():
	popup.hide()
	# TODO don't hard code this
	if is_game_over:
		start()
	else:
		destroy_raid_losses(Global.Types.FOLLOWER)
		if len(get_entities()[Global.Types.FOLLOWER]) == 0:
			game_over(TEXT_LOSE_SURRENDER)


func _on_PopupButton2_pressed():
	popup.hide()
	# TODO don't hard code this
	if is_game_over:
		get_tree().quit()
	else:
		destroy_raid_losses(Global.Types.WEALTH)


func _on_PopupButton3_pressed():
	popup.hide()
	# TODO don't hard code this
	game_over(TEXT_LOSE_SURRENDER)


func _on_Entity_drag():
	drag_sound.play()


func _on_Entity_drop():
	drop_sound.play()


func _on_Entity_cancel():
	cancel_sound.play()


func _on_Entity_request(entity: Entity):
	if entity.slot.assignment == default_assignments[entity.type]:
		cancel_sound.play()
	else:
		return_entity(entity)
		drop_sound.play()


func _on_Assignment_request(slot: Slot):
	if not slot.assignment in default_assignments.values():
		for type in slot.allowed_types:
			var assignment: Assignment = default_assignments[type]
			for i in range(len(assignment.slots) - 1, -1, -1):
				var source_slot: Slot = assignment.slots[i]
				var entity: Entity = source_slot.entity
				if entity != null:
					source_slot.remove_entity()
					slot.add_entity(entity)
					drag_sound.play()
					return
	cancel_sound.play()


func _on_SoundButton_pressed():
	AudioServer.set_bus_mute(Global.SOUND_BUS, not sound_button.button_pressed)


func _on_MusicButton_pressed():
	AudioServer.set_bus_mute(Global.MUSIC_BUS, not music_button.button_pressed)


func _on_FullscreenButton_pressed():
	get_window().mode = Window.MODE_EXCLUSIVE_FULLSCREEN if (fullscreen_button.pressed) else Window.MODE_WINDOWED


func _on_QuitButton_pressed():
	get_tree().quit()
