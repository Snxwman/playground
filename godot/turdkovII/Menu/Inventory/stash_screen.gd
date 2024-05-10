class_name StashScreen extends Container

@onready var stash_scene = preload("res://Menu/Inventory/stash.tscn")

@onready var root_node = $"."

var stash: Stash

func _ready():
	stash = stash_scene.instantiate()
	root_node.add_child(stash)
	

func _process(_delta):
	pass


func get_slotgrid() -> Slotgrid:
	return stash.stash_sgc.slotgrid
