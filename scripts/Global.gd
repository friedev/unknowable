extends Node


enum {FOLLOWER, ARTIFACT, SUSPICION}
var ALL_TYPES := [FOLLOWER, ARTIFACT, SUSPICION]
var TYPE_NAMES := ["follower", "artifact", "suspicion"]

const COLOR_PREVIEW := Color(0.5, 0.5, 0.5)
const COLOR_BAD := Color(1.0, 0.0, 0.0)


func choice(array: Array):
	return array[randi() % len(array)]


func percent(fraction: float) -> int:
	return int(round(fraction * 100.0))


func plural(string: String, count: int) -> String:
	if abs(count) != 1:
		return "%ss" % string
	return string


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
