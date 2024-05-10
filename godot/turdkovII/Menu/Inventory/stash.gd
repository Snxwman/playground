class_name Stash extends Node

signal spawn_item_request()

@onready var stash_sgc_scene = preload("res://Menu/Inventory/Slotgrid/sgc_stash.tscn")

@onready var vbox = $VBoxContainer

var stash_sgc: StashSGC

func _ready():
	stash_sgc = stash_sgc_scene.instantiate()
	vbox.add_child(stash_sgc)


func _process(_delta):
	pass


func _on_spawn_item_pressed():
	emit_signal("spawn_item_request")


func _on_add_row_pressed():
	stash_sgc.slotgrid.add_space_to_slotgrid(Vector2i(0, 1))


func _on_add_col_pressed():
	stash_sgc.slotgrid.add_space_to_slotgrid(Vector2i(1, 0))

	
func _on_del_row_pressed():
	stash_sgc.slotgrid.remove_space_from_slotgrid(Vector2i(0, 1))


func _on_del_col_pressed():
	stash_sgc.slotgrid.remove_space_from_slotgrid(Vector2i(1, 0))

