extends Node


const SOUND_BUS := 1
const MUSIC_BUS := 2

enum Types {FOLLOWER, ARTIFACT, WEALTH, SUSPICION, INVESTIGATOR}
const TYPE_NAMES := ["follower", "artifact", "wealth", "suspicion", "investigator"]
var DRAGGABLE_TYPES := [Types.FOLLOWER, Types.ARTIFACT, Types.WEALTH, Types.SUSPICION]

enum AssignmentTypes {GENERIC, ARTIFACT_QUEST}

const COLOR_PREVIEW := Color(0.5, 0.5, 0.5)
const COLOR_BAD := Color(1.0, 0.0, 0.0)


func choice(array: Array):
	return array[randi() % len(array)]


func percent(fraction: float) -> int:
	return int(round(fraction * 100.0))


func plural(string: String, count: int) -> String:
	if abs(count) == 1:
		return string
	# Special cases
	match string.to_lower():
		"wealth":
			return string
		"suspicion":
			return string
	return "%ss" % string


func delta(amount: int) -> String:
	if amount > 0:
		return "+%d" % amount
	return "%d" % amount


func get_unique_random_numbers(count: int, max_value: int) -> Array:
	var values := {}
	while len(values) < count:
		values[randi() % max_value] = 0
	return values.keys()


func array_to_prose(array: Array) -> String:
	if len(array) == 1:
		return array[0]
	if len(array) == 2:
		return "%s and %s" % [array[0], array[1]]
	return "%s and %s" % [", ".join(array.slice(0, -2)), array[-1]]
