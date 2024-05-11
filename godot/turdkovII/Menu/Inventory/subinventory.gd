class_name Subinventory extends Control

signal close_subinventory()

const MAX_SCROLL_CONTAINTER_ROWS = 8
const MAX_SCROLL_CONTAINTER_COLS = 8
const HORIZONTAL_MARGIN = 3 * 2 + 8
const VERTICAL_MARGIN = 3 * 2
const HEADER_HEIGHT = 40

@onready var slotgrid_scene = preload("res://Menu/Inventory/Slotgrid/slotgrid.tscn")

@onready var subinventory_root = $"."
@onready var container_name_label = $VBoxContainer/MarginContainer/HBoxContainer/ItemName
@onready var slotgrid_container = $VBoxContainer/SlotgridContainer


func _ready():
	pass # Replace with function body.


func _process(delta):
	pass		

	
func setup_scene(item: Item):
	container_name_label.text = item.item_resource_data.long_name
	
	var slotgrid = slotgrid_scene.instantiate()
	slotgrid_container.add_child(slotgrid)
	slotgrid.create_slotgrid(item.item_resource_data.internal_slot_geometry)
	
	var slotgrid_container_size = Vector2i(
		min(slotgrid.slotgrid_width, MAX_SCROLL_CONTAINTER_COLS) * slotgrid.SLOT_SIZE_PX,
		min(slotgrid.slotgrid_height, MAX_SCROLL_CONTAINTER_ROWS) * slotgrid.SLOT_SIZE_PX
	)
	
	slotgrid_container.size = slotgrid_container_size
	subinventory_root.size = Vector2i(
		slotgrid_container_size[0] + HORIZONTAL_MARGIN, 
		slotgrid_container_size[1] + VERTICAL_MARGIN + HEADER_HEIGHT
	)


func _on_close_window_pressed():
	get_viewport().set_input_as_handled()
	close_subinventory.emit()
