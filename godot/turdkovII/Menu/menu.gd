class_name Menu extends Node

#const items = ["backpack", "bullet", "grenade", "helmet", "knife", "plate_carrier", "rifle"]
const items = ["backpack", "plate_carrier"]

@onready var debug_menu_scene = preload("res://Menu/Debug/debug_menu.tscn")
@onready var debug_menu_container = $DebugMenuContainer

@onready var stash_screen_scene = preload("res://Menu/Inventory/stash_screen.tscn")
@onready var item_scene = preload("res://Menu/Item/item.tscn")

@onready var held_item_container = $HeldItemContainer
@onready var subinventory_container = $SubinventoryContainer
@onready var stash_screen_container = $ScreenContainer/StashScreenContainer

var registered_slotgrids: Array[Slotgrid]

var hovered_slotgrid: Slotgrid
var last_hovered_slotgrid: Slotgrid
var hovered_slot: Slot
var last_hovered_slot: Slot
var hovered_item: Item

var held_item: Item = null
var slots_under_held_item: Array[Slot] = []
var can_place_held_item: bool = false


func _input(event):
	if event.is_action_pressed("quit"):
		get_tree().quit()
	elif event.is_action_pressed("pick_place_item"):
		if hovered_slot and held_item:
			place_item()
		elif hovered_item:
			pick_item()
	elif event.is_action_pressed("open_subinventory"):
		if hovered_item:
			open_subinventory(hovered_item)
	elif event.is_action_pressed("open_debug_menu"):
		open_debug_menu()


func _ready():
	var stash_screen = stash_screen_scene.instantiate()
	stash_screen_container.add_child(stash_screen)
	
	register_new_slotgrid(stash_screen.get_slotgrid())
	stash_screen.stash.spawn_item_request.connect(_on_spawn_item_request)


func _process(_delta):
	pass
	

func _on_mouse_entered_slot(slot: Slot):
	print("entered " + str(slot.slotgrid_coord))
	
	last_hovered_slotgrid = hovered_slotgrid
	hovered_slotgrid = slot.parent_slotgrid
	last_hovered_slot = hovered_slot
	hovered_slot = slot
	
	if hovered_slot != null and hovered_slot.stored_item != null:
		hovered_item = hovered_slot.stored_item
	else:
		hovered_item = null
		
	if held_item != null:
		slots_under_held_item = hovered_slotgrid.get_slots_under_item(held_item, hovered_slot)
		can_place_held_item = hovered_slotgrid.can_place(held_item, slots_under_held_item)
		
	#if hovered_slot != last_hovered_slot:
	if hovered_slotgrid != last_hovered_slotgrid and last_hovered_slotgrid != null:
		last_hovered_slotgrid.redraw_highlights()
		
	redraw_highlights(hovered_slotgrid)
	

func _on_mouse_exited_slot(slot: Slot):
	#print("exited " + str(slot.slotgrid_coord))
		
	if hovered_slot == slot:  # Cant be hovering the slot we just exited
		last_hovered_slotgrid = hovered_slotgrid
		hovered_slotgrid = null
		last_hovered_slot = hovered_slot
		hovered_slot = null
		hovered_item = null
		
		slots_under_held_item = []
		can_place_held_item = false
		
		redraw_highlights(last_hovered_slotgrid)
		
	
func _on_spawn_item_request():
	if not held_item:
		var item = item_scene.instantiate()
		held_item_container.add_child(item)
		
		item.spawn_with_random_stats(items.pick_random())
		item.item_rotated.connect(_on_item_rotated)

		held_item = item
		item.selected = true
	
	
func _on_item_rotated():
	slots_under_held_item = hovered_slotgrid.get_slots_under_item(held_item, hovered_slot)
	redraw_highlights(hovered_slotgrid)
	
	
func place_item():
	held_item_container.remove_child(held_item)
	hovered_slotgrid.place_item(held_item, hovered_slot, slots_under_held_item)
	held_item = null
	redraw_highlights(hovered_slotgrid)
	

func pick_item():
	held_item = hovered_slotgrid.pick_item(hovered_slot)
	held_item_container.add_child(held_item)
	redraw_highlights(hovered_slotgrid)
	
	
func redraw_highlights(slotgrid: Slotgrid):
	var highlight_color = Slot.Highlights.CLEAR
	
	# Reset the entire slotgrid
	for row_container in slotgrid.slotgrid_container.get_children():
		for slot in row_container.get_children():
			if slot.highlighted:
				slot.set_highlight(highlight_color)
	
	if held_item and hovered_slot:
		highlight_color = Slot.Highlights.CAN_PLACE if can_place_held_item else Slot.Highlights.CANT_PLACE
		
		for slot in slots_under_held_item:
			slot.set_highlight(highlight_color)


func open_subinventory(item: Item):
	item.open_subinventory()
	register_new_slotgrid(item.get_subinventory_slotgrid())

	
func register_new_slotgrid(slotgrid: Slotgrid):
	if not registered_slotgrids.has(slotgrid):
		slotgrid.slotgrid_geometry_changed.connect(connect_slot_signals)
		connect_slot_signals(slotgrid)
		registered_slotgrids.push_back(slotgrid)
	
	
func connect_slot_signals(slotgrid):
	for slot in slotgrid.get_all_slots():
		if not slot.is_connected("mouse_entered_slot", _on_mouse_entered_slot):
			slot.mouse_entered_slot.connect(_on_mouse_entered_slot)
		if not slot.is_connected("mouse_exited_slot", _on_mouse_exited_slot):
			slot.mouse_exited_slot.connect(_on_mouse_exited_slot)

		
#func register_new_slotgrids():
	#var slotgrids = get_all_slotgrids_in_tree()
	#for slotgrid in slotgrids:
		#if not registered_slotgrids.has(slotgrid):
			#for slot in slotgrid.get_all_slots():
				#slot.mouse_entered_slot.connect(_on_mouse_entered_slot)
				#slot.mouse_exited_slot.connect(_on_mouse_exited_slot)
	#
		#registered_slotgrids.push_back(slotgrid)
	#
	#
#func findByClass(node: Node, className: String, result: Array) -> void:
	#if node.is_class(className):
		#result.push_back(node)
	#for child in node.get_children():
		#findByClass(child, className, result)
#
#
#func get_all_slotgrids_in_tree() -> Array:
	#var slotgrids = []
	#findByClass(self, "Slotgrid", slotgrids)
	#print(str(slotgrids))
	#return slotgrids


func open_debug_menu():
	if debug_menu_scene.DEBUG:
		var debug_menu = debug_menu_scene.instantiate()
		debug_menu_container.add_child(debug_menu)

