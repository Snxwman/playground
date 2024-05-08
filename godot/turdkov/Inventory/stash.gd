class_name Stash extends Control

const STASH_WIDTH: int = 12
const STASH_LINES: int = 8
const STASH_GEOMETRY: Vector2i = Vector2i(STASH_WIDTH, STASH_LINES)
const STASH_MAX_SIZE: Vector2i = Vector2i(12, 16)
const SLOT_SIZE_PX = 64

# DEBUG
#const items = ["backpack", "bullet", "grenade", "helmet", "knife", "plate_carrier", "rifle"]
const items = ["backpack", "plate_carrier"]

@onready var slotgrid_scene = preload("res://Inventory/slotgrid.tscn")
@onready var item_scene = preload("res://Items/item.tscn")
@onready var slotgrid_container = $VBoxContainer/SlotgridContainer

var slotgrid: Slotgrid
var hovered_slotgrid: Slotgrid

func _input(event):
	pass

func _ready():
	slotgrid = slotgrid_scene.instantiate().duplicate()
	slotgrid_container.add_child(slotgrid)
	slotgrid.setup_scene(STASH_GEOMETRY, STASH_MAX_SIZE)
	#slotgrid.slotgrid_entered.connect(_on_mouse_entered_slotgrid)
	#slotgrid.slotgrid_exited.connect(_on_mouse_exited_slotgrid)
	slotgrid.open_subinventory.connect(_on_open_subinventory)
	
	for row in slotgrid.slotgrid_container.get_children():
		for slot in row.get_children():
			slot.slot_entered.connect(_on_mouse_entered_slot)
			slot.slot_exited.connect(_on_mouse_exited_slot)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_mouse_entered_slot(slot):
	print("entered " + str(slot.slotgrid_location))
	
	if hovered_slotgrid != slot.parent_slotgrid:
		print("exiting old slotgrid: " + str(hovered_slotgrid))
		hovered_slotgrid = slot.parent_slotgrid
		print("entered new slotgrid: " + str(hovered_slotgrid))
		
	hovered_slotgrid.last_hovered_slot = hovered_slotgrid.hovered_slot
	hovered_slotgrid.hovered_slot = slot
		
	if hovered_slotgrid.hovered_slot != null and hovered_slotgrid.hovered_slot.item_stored != null:
		hovered_slotgrid.hovered_item = hovered_slotgrid.hovered_slot.item_stored
	else:
		hovered_slotgrid.hovered_item = null
	
	print("hovered_slotgrid item: " + str(hovered_slotgrid.item_held))
	print("slotgrid item: " + str(slotgrid.item_held))
	if hovered_slotgrid.item_held or slotgrid.item_held:
		if slotgrid.item_held:
			hovered_slotgrid.item_held = slotgrid.item_held
			
		hovered_slotgrid.slots_under_item = hovered_slotgrid.get_slots_under_item()
		hovered_slotgrid.can_place = hovered_slotgrid.item_can_fit()
		print(str(hovered_slotgrid.slots_under_item))
		print(str(hovered_slotgrid.can_place))
		
	if hovered_slotgrid.last_hovered_slot != hovered_slotgrid.hovered_slot:
		hovered_slotgrid.redraw_highlights()
			
func _on_mouse_exited_slot(slot):
	# If hovered_slot is the one being exited, then unset it.
	# This prevents unsetting hovered_slot when _on_slot_mouse_entered sets a new hovered slot before this signal fires.
	#print("exited " + str(slot.slotgrid_location))
	if hovered_slotgrid.hovered_slot == slot:
		hovered_slotgrid.hovered_slot = null
		hovered_slotgrid.can_place = false
	
		hovered_slotgrid.redraw_highlights()

#func _on_mouse_entered_slotgrid(slotgrid: Slotgrid):
	#print("entered slotgrid: " + str(slotgrid))
	#hovered_slotgrid = slotgrid

#func _on_mouse_exited_slotgrid(slotgrid: Slotgrid):
	#print("exited slotgrid: " + str(slotgrid))
	#hovered_slotgrid = null

func _on_spawn_button_pressed():
	if not slotgrid.item_held:
		var item = item_scene.instantiate()
		slotgrid.item_container.add_child(item)
		
		item.spawn_with_random_stats(items.pick_random())
		item.selected = true
		item.item_rotated.connect(slotgrid._on_item_rotated)
	
		slotgrid.item_held = item
		
func _on_open_subinventory(item):
	var maybe_subinvntory_slotgrid = item.open_subinventory()
	
	if maybe_subinvntory_slotgrid is Slotgrid:
		for row in maybe_subinvntory_slotgrid.slotgrid_container.get_children():
			for slot in row.get_children():
				slot.slot_entered.connect(_on_mouse_entered_slot)
				slot.slot_exited.connect(_on_mouse_exited_slot)
	
func _on_add_row_pressed():
	slotgrid.add_space_to_slotgrid(Vector2i(0, 1))

func _on_add_column_pressed():
	slotgrid.add_space_to_slotgrid(Vector2i(1, 0))
	
func _on_remove_row_pressed():
	slotgrid.remove_space_from_slotgrid(Vector2i(0, 1))

func _on_remove_column_pressed():
	slotgrid.remove_space_from_slotgrid(Vector2i(1, 0))
