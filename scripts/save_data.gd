class_name OrbitSaveData
extends RefCounted
## Typed serialization boundary; dictionary schema/version remains backward compatible.
static func snapshot(state: Dictionary, active: Dictionary) -> Dictionary:
	var result := state.duplicate()
	result.session = active
	return result
