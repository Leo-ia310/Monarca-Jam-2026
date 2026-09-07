extends Node

const ROUTE_A := "A"
const ROUTE_B := "B"
const ROUTE_C := "C"

var answer_counts := {
	ROUTE_A: 0,
	ROUTE_B: 0,
	ROUTE_C: 0
}


func reset() -> void:
	answer_counts[ROUTE_A] = 0
	answer_counts[ROUTE_B] = 0
	answer_counts[ROUTE_C] = 0


func record_answer(answer_index: int) -> void:
	match answer_index:
		0:
			answer_counts[ROUTE_A] += 1
		1:
			answer_counts[ROUTE_B] += 1
		_:
			answer_counts[ROUTE_C] += 1


func get_dominant_route() -> String:
	var route := ROUTE_A
	var best_count := int(answer_counts[ROUTE_A])
	for candidate in [ROUTE_B, ROUTE_C]:
		var count := int(answer_counts[candidate])
		if count > best_count:
			route = candidate
			best_count = count
	return route


func is_final_a() -> bool:
	return int(answer_counts[ROUTE_A]) > int(answer_counts[ROUTE_B]) and int(answer_counts[ROUTE_A]) > int(answer_counts[ROUTE_C])
