extends RefCounted
## Builder lifetime follows the page. No host/page reference cycle (host is a Node).
var host: Control

func _init(page_host: Control) -> void:
	host = page_host

func build() -> void:
	pass

func teardown() -> void:
	# Discover page-owned node references, including new fields added in the future.
	for property in host.get_property_list():
		if property.type != TYPE_OBJECT or not (property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE): continue
		var value: Variant = host.get(property.name)
		if is_instance_valid(value) and value is Node and host.content.is_ancestor_of(value):
			host.set(property.name,null)
