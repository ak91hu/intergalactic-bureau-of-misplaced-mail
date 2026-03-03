class_name AlgorithmBase
extends RefCounted

# Every subclass MUST declare: var _initialized: bool = false
# GraphManager checks _initialized to decide initialize() vs advance()
var _initialized: bool = false


func initialize(_graph_data: Dictionary, _start_node: String) -> Dictionary:
	return {}


func advance(_graph_data: Dictionary) -> Dictionary:
	return {}


func is_complete() -> bool:
	return false


func get_name() -> String:
	return ""


func get_structure_label() -> String:
	return ""


func get_welcome_message() -> String:
	return ""
