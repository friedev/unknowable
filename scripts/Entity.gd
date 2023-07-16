extends Control
class_name Entity


signal drag
signal drop
signal cancel
signal request(entity)


# TODO capitalize constants
# https://www.victorians.co.uk/victorian-names
const male_first_names := ["Albert", "Alexander", "Alfred", "Algernon", "Allen", "Ambrose", "Andrew", "Anthony", "Archibald", "Archie", "Arthur", "Aubrey", "August", "Augustine", "Augustus", "Basil", "Ben", "Benjamin", "Bernard", "Bert", "Bertram", "Carl", "Cecil", "Cedric", "Charles", "Charley", "Charlie", "Chester", "Clarence", "Claude", "Clement", "Clifford", "Clyde", "Cornelius", "Cuthbert", "Cyril", "Daniel", "David", "Donald", "Douglas", "Duncan", "Earl", "Ebenezer", "Ed", "Eddie", "Edgar", "Edmund", "Edward", "Edwin", "Elmer", "Ernest", "Eugene", "Eustace", "Evan", "Everett", "Ewart", "Felix", "Fergus", "Floyd", "Francis", "Frank", "Franklin", "Fred", "Frederick", "Geoffrey", "George", "Gerald", "Gilbert", "Grover", "Guy", "Harold", "Harry", "Harvey", "Henry", "Herbert", "Herman", "Horace", "Howard", "Hubert", "Hugh", "Hugo", "Humphrey", "Ira", "Isaac", "Ivan", "Ivor", "Jack", "Jacob", "James", "Jasper", "Jessie", "Jim", "Joe", "John", "Jonathan", "Joseph", "Julian", "Julius", "Kenneth", "Laurence", "Lawrence", "Lee", "Leo", "Leonard", "Leopold", "Leroy", "Leslie", "Lewis", "Lionel", "Llewellyn", "Lloyd", "Louis", "Luther", "Malcolm", "Marion", "Martin", "Maurice", "Maxwell", "Michael", "Miles", "Montague", "Neville", "Nigel", "Oliver", "Oscar", "Otto", "Owen", "Patrick", "Paul", "Percival", "Percy", "Peter", "Philip", "Ralph", "Randolph", "Ray", "Raymond", "Reginald", "Reuben", "Richard", "Robert", "Roderick", "Roger", "Roy", "Rufus", "Rupert", "Sam", "Samuel", "Septimus", "Sidney", "Silas", "Simeon", "Stanley", "Stephen", "Theodore", "Thomas", "Timothy", "Tom", "Valentine", "Vernon", "Victor", "Vincent", "Walter", "Warren", "Wilfred", "Will", "William", "Willie"]
const female_first_names := ["Ada", "Addie", "Adelaide", "Adeline", "Agatha", "Agnes", "Alice", "Alma", "Amanda", "Amelia", "Amy", "Anna", "Anne", "Annie", "Augusta", "Beatrice", "Bertha", "Bessie", "Blanche", "Caroline", "Carrie", "Catherine", "Cecilia", "Cecily", "Charlotte", "Clara", "Clarissa", "Clementina", "Constance", "Cora", "Cordelia", "Daisy", "Delia", "Della", "Dora", "Dorcas", "Doris", "Dorothea", "Dorothy", "Edith", "Edna", "Effie", "Eliza", "Elizabeth", "Ella", "Ellen", "Elsie", "Emily", "Emma", "Emmeline", "Esther", "Ethel", "Etta", "Eugenie", "Eva", "Eveline", "Flora", "Florence", "Frances", "Freda", "Georgia", "Georgina", "Gertrude", "Gladys", "Grace", "Gwendoline", "Harriet", "Hattie", "Hazel", "Helen", "Helena", "Henrietta", "Hetty", "Hilda", "Honor", "Ida", "Irene", "Iris", "Isabel", "Ivy", "Jane", "Jemima", "Jennie", "Jenny", "Jessie", "Josephine", "Julia", "Kate", "Katherine", "Kathleen", "Kathryn", "Katie", "Laura", "Lavinia", "Leah", "Lena", "Lillian", "Lillie", "Lily", "Lizzie", "Lottie", "Louisa", "Louise", "Lucy", "Lula", "Lulu", "Lydia", "Mabel", "Mae", "Maggie", "Mamiev", "Margaret", "Marguerite", "Marie", "Marion", "Marjorie", "Martha", "Mary", "Matilda", "Maude", "May", "Mercy", "Mildred", "Millicent", "Minnie", "Mollie", "Myrtle", "Nancy", "Nannie", "Nellie", "Nettie", "Nora", "Olive", "Patience", "Pauline", "Pearl", "Phoebe", "Phyllis", "Priscilla", "Prudence", "Rachel", "Rebecca", "Rhoda", "Rosa", "Rose", "Rosetta", "Rosina", "Ruby", "Ruth", "Sadie", "Sallie", "Sarah", "Selina", "Stella", "Susan", "Susannah", "Susie", "Sylvia", "Tabitha", "Theodora", "Theresa", "Ursula", "Victoria", "Viola", "Violet", "Wilhelmina", "Willie", "Winifred"]
# https://victorian-era.org/victorian-era-last-names.html
const last_names := ["Allen", "Davis", "Jackson", "Morris", "Thompson", "Baker", "Edwards", "James", "Parker", "Turner", "Bennett", "Evans", "Johnson", "Phillips", "Walker", "Brown", "Green", "Jones", "Price", "Ward", "Carter", "Griffiths", "King", "Roberts", "Watson", "Clark", "Hall", "Lee", "Robinson", "White", "Clarke", "Harris", "Lewis", "Shaw", "Williams", "Cook", "Harrison", "Martin", "Smith", "Wilson", "Cooper", "Hill", "Moore", "Taylor", "Wood", "Davies", "Hughes", "Morgan", "Thomas", "Wright"]
const god_start_consonants := ["n", "r", "t", "z", "j", "zh", "l", "x", "k", "kl", "ch", "tch", "cth", "th", "ts", "tz", "kt", "q", "g", "kn", "gn", "d", "sh"]
const god_consonants := ["n", "r", "t", "z", "j", "zh", "l", "x", "xl", "xh", "lh", "k", "kl", "lk", "lth", "rth", "ch", "tch", "cth", "th", "ts", "tz", "kt", "q", "dk", "dz", "g", "kn", "gn", "d", "sh"]
const god_vowels := ["u", "a", "o", "i", "iu", "ia"]
const artifact_rings := ["Ring", "Band", "Bracer"]
const artifact_staves := ["Staff", "Wand", "Rod", "Scepter"]
const artifact_blades := ["Blade", "Sword", "Dagger", "Knife"]
const artifact_amulets := ["Amulet", "Medallion", "Orb", "Eye", "Heart"]
const artifact_crowns := ["Crown", "Circlet", "Crest"]
const artifact_adjectives := ["Ravening", "Ethereal", "Undying", "Burning", "Frozen", "Crying", "Bleeding", "Darkening", "Ensorcelled", "Envenoming", "Infinite", "Eternal", "Summoning", "Astral", "Unseen", "Hollow", "Midnight", "Serpentine", "Ineffable", "Atlantean", "Hyperborean", "Lemurian", "Cyclopean", "Unceasing", "Chilling", "Brutal", "Stygian"]
const artifact_nouns := ["Souls", "Blood", "Flame", "Time", "Death", "Shadows", "Eternity", "Undeath", "Night", "Madness", "Chaos", "Beyond", "Secrets", "Thorns", "Tears", "Sorrow", "Pain", "Despair", "Infinity", "Frost", "Hatred", "Bone"]

# TODO generalize artifact types as a dict/list of objects so fewer variables are needed
const suspicion_texture := preload("res://sprites/entities/suspicion.png")
const wealth_texture := preload("res://sprites/entities/wealth.png")
const artifact_ring_textures := [preload("res://sprites/entities/artifacts/artifact1.png")]
const artifact_staff_textures := [preload("res://sprites/entities/artifacts/artifact2.png")]
const artifact_blade_textures := [preload("res://sprites/entities/artifacts/artifact3.png")]
const artifact_amulet_textures := [preload("res://sprites/entities/artifacts/artifact4.png")]
const artifact_crown_textures := [preload("res://sprites/entities/artifacts/artifact5.png")]
const male_textures := [preload("res://sprites/entities/followers/male_face1.png"), preload("res://sprites/entities/followers/male_face2.png")]
const female_textures := [preload("res://sprites/entities/followers/female_face1.png"), preload("res://sprites/entities/followers/female_face2.png")]
const investigator_textures := [preload("res://sprites/entities/investigator.png")]

var type: int
var text := ""
var texture: Texture2D = null
var slot: Node = null
var tooltip_dirty := false

@onready var label: Label = %Label
@onready var texture_rect: TextureRect = %TextureRect


func update_tooltip() -> void:
	var type_name: String = Global.TYPE_NAMES[self.type]
	if self.text.nocasecmp_to(type_name) == 0:
		self.tooltip_text = self.text
	else:
		self.tooltip_text = "%s, %s" % [self.text, type_name]


func set_text(text: String) -> void:
	self.text = text
	if self.label != null:
		self.label.text = self.text
	self.tooltip_dirty = true


func set_texture(texture: Texture2D) -> void:
	self.texture = texture
	if self.texture_rect != null:
		self.texture_rect.texture = texture


func set_type(type: int) -> void:
	self.type = type
	self.tooltip_dirty = true


func generate_male_name() -> String:
	return "%s %s" % [Global.choice(male_first_names), Global.choice(last_names)]


func generate_female_name() -> String:
	return "%s %s" % [Global.choice(self.female_first_names), Global.choice(last_names)]


func generate_god_name() -> String:
	var morphemes := []
	var vowel := randi() % 2 == 0
	for x in range(5 + randi() % 2):
		if len(morphemes) > 0 and randi() % 4 == 0:
			if randi() % 3 == 0:
				morphemes.append("-")
				vowel = randi() % 2 == 0
			else:
				morphemes.append("'")
				vowel = not vowel
		if vowel:
			morphemes.append(Global.choice(self.god_vowels))
			vowel = false
		else:
			if len(morphemes) == 0:
				morphemes.append(Global.choice(self.god_start_consonants))
			else:
				morphemes.append(Global.choice(self.god_consonants))
			vowel = true
	return "".join(morphemes).capitalize()


func generate_artifact_name(artifact_object: String) -> String:
	if randi() % 2 == 0:
		return "%s of %s" % [artifact_object, self.generate_god_name()]
	else:
		if randi() % 2 == 0:
			return "%s %s" % [Global.choice(self.artifact_adjectives), artifact_object]
		else:
			return "%s of %s" % [artifact_object, Global.choice(self.artifact_nouns)]


func _make_suspicion() -> void:
	self.set_text("Suspicion")
	self.set_texture(self.suspicion_texture)


func _make_wealth() -> void:
	self.set_text("Wealth")
	self.set_texture(self.wealth_texture)


func _make_follower():
	if randi() % 2 == 0:
		self.set_text(self.generate_male_name())
		self.set_texture(Global.choice(male_textures))
	else:
		self.set_text(self.generate_female_name())
		self.set_texture(Global.choice(self.female_textures))


func _make_artifact() -> void:
	var artifact_object: String
	match randi() % 5:
		0:
			artifact_object = Global.choice(self.artifact_rings)
			self.set_texture(Global.choice(self.artifact_ring_textures))
		1:
			artifact_object = Global.choice(self.artifact_staves)
			self.set_texture(Global.choice(self.artifact_staff_textures))
		2:
			artifact_object = Global.choice(self.artifact_blades)
			self.set_texture(Global.choice(self.artifact_blade_textures))
		3:
			artifact_object = Global.choice(self.artifact_amulets)
			self.set_texture(Global.choice(self.artifact_amulet_textures))
		4:
			artifact_object = Global.choice(self.artifact_crowns)
			self.set_texture(Global.choice(self.artifact_crown_textures))
	self.set_text(self.generate_artifact_name(artifact_object))


func _make_investigator():
	# TODO more investigator sprites
	self.set_text(self.generate_male_name())
	self.set_texture(Global.choice(investigator_textures))


func make_type(type: int) -> void:
	self.set_type(type)
	match type:
		Global.Types.SUSPICION:
			self._make_suspicion()
		Global.Types.WEALTH:
			self._make_wealth()
		Global.Types.FOLLOWER:
			self._make_follower()
		Global.Types.ARTIFACT:
			self._make_artifact()
		Global.Types.INVESTIGATOR:
			self._make_investigator()

func create_preview() -> Control:
	var preview: Container = self.duplicate()
	# Wrap preview in a parent Control node
	# The Control's position is set to the mouse, but we can offset the entity
	var parent := Control.new()
	parent.add_child(preview)
	preview.position = -preview.size / 2
	return parent


func _get_drag_data(position: Vector2):
	if not self.type in Global.DRAGGABLE_TYPES:
		return null
	self.emit_signal("drag")
	self.set_drag_preview(self.create_preview())
	self.hide()
	self.slot.empty.show()
	self.slot.assignment.slots_dirty = true
	return self


func _notification(notification) -> void:
	match notification:
		NOTIFICATION_DRAG_END:
			if self.is_drag_successful():
				self.emit_signal("drop")
			else:
				self.emit_signal("cancel")
			self.slot.empty.hide()
			self.show()
			self.slot.assignment.slots_dirty = true


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.is_pressed():
			self.emit_signal("request", self)


func _ready() -> void:
	if self.text != "" and self.text != null:
		self.set_text(self.text)
	if self.texture != null:
		self.set_texture(self.texture)


func _process(delta: float) -> void:
	if self.tooltip_dirty:
		self.update_tooltip()
		self.tooltip_dirty = false
