class_name Slotgrid extends ScrollContainer

signal slot_entered(slot)
signal slot_exited(slot)

signal item_placed()
signal item_picked()

const SLOT_SIZE_PX = 64

@onready var slot_scene = preload("res://Inventory/slot.tscn")
@onready var item_scene = preload("res://Items/item.tscn")
@onready var scroll_container = $"."
@onready var slotgrid_container = $SlotGrid

var slotgrid = []
var slotgrid_width
var slotgrid_height

var last_hovered_slot: Slot
var hovered_slot: Slot = null
var focused_slot: Slot = null
var hovered_item: Item = null
var focused_item: Item = null

var item_held: Item = null
var slots_under_item = []

var can_place: bool = false

func _input(event):
	if Input.is_action_just_pressed("place_item"):
		if hovered_slot:
			place_item() if item_held else pick_item()
	elif Input.is_action_just_pressed("open_subinventory"):
		print(str(hovered_item))
		if hovered_item != null:
			hovered_item.open_subinventory()
	
	if event is InputEventMouseMotion:
		var mouse_pos = scroll_container.get_local_mouse_position()
		last_hovered_slot = hovered_slot
		hovered_slot = slotgrid_container.get_child(
			int(mouse_pos[0] / SLOT_SIZE_PX) + 
			int(mouse_pos[1] / SLOT_SIZE_PX) * slotgrid_width
		)
		if last_hovered_slot != hovered_slot:
			emit_signal("slot_exited", last_hovered_slot)
			emit_signal("slot_entered", hovered_slot)

func _ready():
	pass

func _process(delta):
	pass
	
func _on_item_rotated(item):
	slots_under_item = get_slots_under_item()
	redraw_highlights()
	
func _on_mouse_entered_slot(slot):
	#print("Entered slot (" + str(hovered_slot.slotgrid_location[0]) + ", " + str(hovered_slot.slotgrid_location[1]) + ")")
	
	hovered_slot = slot
	if hovered_slot != null and hovered_slot.item_stored != null:
		hovered_item = hovered_slot.item_stored
	else:
		hovered_item = null
	
	if item_held:
		slots_under_item = get_slots_under_item()
		can_place = item_can_fit()
		
	redraw_highlights()
			
func _on_mouse_exited_slot(slot):
	#print("Exited slot (" + str(hovered_slot.slotgrid_location[0]) + ", " + str(hovered_slot.slotgrid_location[1]) + ")")
	# If hovered_slot is the one being exited, then unset it.
	# This prevents unsetting hovered_slot when _on_slot_mouse_entered sets a new hovered slot before this signal fires.
	if hovered_slot == slot:
		hovered_slot = null
		can_place = false
		
	redraw_highlights()
	
func create_slotgrid(geometry: Vector2 = Vector2(12, 12)):
	slotgrid_width = geometry[0]
	slotgrid_height = geometry[1]
	
	scroll_container.size = Vector2(slotgrid_width * SLOT_SIZE_PX, slotgrid_height * SLOT_SIZE_PX)
	slotgrid_container.columns = slotgrid_width
	
	for row in range(0, slotgrid_height):
		#var slotgrid_row_node = Control.new()
		var slotgrid_row = []
		
		for col in range(0, slotgrid_width):
			var slot = create_slot(col, row)
			#slotgrid_row_node.add_child(slot)
			slotgrid_container.add_child(slot)
			slotgrid_row.push_back(slot)
		
		#slotgrid_container.add_child(slotgrid_row_node)
		slotgrid.push_back(slotgrid_row)
		
	slot_entered.connect(_on_mouse_entered_slot)
	slot_exited.connect(_on_mouse_exited_slot)

func create_slot(col, row):
	var slot: Slot = slot_scene.instantiate()
	slot.slotgrid_index = row*12 + col
	slot.slotgrid_location = Vector2(col, row)
	
	return slot

# TODO: finish
func add_space_to_slotgrid(new_space: Vector2i):
	# new_space is an int vector denoting the number of (columns, rows) to add to the slotgrid.
	if new_space[0] < 1 or new_space[1] < 1:
		return
		
	if new_space[0] == 0:
		add_rows_to_slotgrid(new_space[1])
	elif new_space[1] == 0:
		add_columns_to_slotgrid(new_space[0])
	else:
		pass

# TODO: finish
func add_rows_to_slotgrid(rows: int):
	for row in range(0, rows):
		for col in range(0, slotgrid_width):
			var slot = create_slot(col, row)

# TODO: finish	
func add_columns_to_slotgrid(cols: int):
	for row in range(0, slotgrid_height):
		for col in range(0, cols):
			var slot = create_slot(col, row)

func redraw_highlights():
	# Reset the entire slotgrid
	for slot in slotgrid_container.get_children().filter(func(child): return true if child is Slot else false):
		slot.set_highlight_color(slot.States.DEFAULT)
	
	if item_held and hovered_slot:
		if can_place:
			for slot in slots_under_item:
				slot.set_highlight_color(slot.States.EMPTY)
		else:
			for slot in slots_under_item:
				slot.set_highlight_color(slot.States.OCCUPIED)	
	
func get_slots_under_item():
	var slots = []
	var item_width = item_held.get_slot_width()
	var item_height = item_held.get_slot_height()
	
	# No hovered_slot set, outside of slotgrid
	if hovered_slot == null:
		return []
	
	# Check that the slots_under_item are all within the slotgrid
	if hovered_slot.slotgrid_location[0] + item_width > slotgrid_width:
		return []
	elif hovered_slot.slotgrid_location[1] + item_height > slotgrid_height:
		return []
	
	var offset = hovered_slot.slotgrid_index
	for row in range(0, item_height):
		for col in range(0, item_width):
			#slots.push_back(slotgrid.get_child(col + (row * slotgrid_width) + offset))
			slots.push_back(slotgrid_container.get_child(col + (row * slotgrid_width) + offset))
	
	return slots

func item_can_fit():
	for slot in slots_under_item:
		if slot.state == slot.States.OCCUPIED:
			if slot.item_stored.item_resource_data.item_id != item_held.item_resource_data.item_id:
				return false
			elif slot.current_stack_size == slot.item_stored.item_resource_data.max_stack_size:
				return false
			# BUG: needs a check that item can stack before eveluating stack size
			elif slot.current_stack_size + item_held.current_stack_size > slot.item_stored.item_resource_data.max_stack_size:
				return false
	return true
				
func place_item():
	can_place = item_can_fit()
	if not can_place:
		return
	
	item_held.occupied_slots = slots_under_item
	for slot in slots_under_item:
		slot.state = slot.States.OCCUPIED
		slot.item_stored = item_held
		slot.current_stack_size += 1
	
	#var offset_col = hovered_slot.slotgrid_col * SLOT_SIZE_PX
	#var offset_row = hovered_slot.slotgrid_row * SLOT_SIZE_PX
	item_held.position = Vector2(hovered_slot.slotgrid_location[0] * SLOT_SIZE_PX, hovered_slot.slotgrid_location[1] * SLOT_SIZE_PX)
	item_held.selected = false
	
	item_held = null
	emit_signal("slot_entered", hovered_slot)
				
func pick_item():
	if hovered_item == null:
		return
		
	item_held = hovered_slot.item_stored
	var item_previously_occupied_slots = item_held.occupied_slots
	slots_under_item = get_slots_under_item()
	item_held.occupied_slots = []
	
	for item_slot in item_previously_occupied_slots:
		item_slot.state = item_slot.States.EMPTY
		item_slot.item_stored = null
		item_slot.current_stack_size = 0
		
	item_held.selected = true
	can_place = item_can_fit()
	redraw_highlights()
