class_name Slotgrid extends ScrollContainer

signal slotgrid_entered(slotgrid)
signal slotgrid_exited(slotgrid)
signal slot_entered(slot)
signal slot_exited(slot)
signal open_subinventory(item)

signal item_placed()
signal item_picked()

const SLOT_SIZE_PX = 64

@onready var slot_scene = preload("res://Inventory/slot.tscn")
@onready var item_scene = preload("res://Items/item.tscn")
@onready var scroll_container = $"."
@onready var slotgrid_container = $SlotgridContainer
@onready var item_container = $ItemContainer

var scroll_container_max_size: Vector2i

var slotgrid_width: int = 0
var slotgrid_height: int = 0

var last_hovered_slot: Slot = null
var hovered_slot: Slot = null
var hovered_item: Item = null

var focused_slot: Slot = null
var focused_item: Item = null

var item_held: Item = null
var slots_under_item = []

var can_place: bool = false

func _input(event):
	if Input.is_action_just_pressed("place_item"):
		if hovered_slot:
			place_item() if item_held else pick_item()
	elif Input.is_action_just_pressed("open_subinventory"):
		if hovered_item != null:
			emit_signal("open_subinventory", hovered_item)

func _ready():
	pass

func _process(delta):
	pass
	
func _on_item_rotated(item):
	slots_under_item = get_slots_under_item()
	redraw_highlights()
	
func _on_mouse_entered_slotgrid():
	emit_signal("slotgrid_entered", self)

func _on_mouse_exited_slotgrid():
	emit_signal("slotgrid_exited", self)
	
func _on_mouse_entered_slot(slot):
	print("entered " + str(slot.slotgrid_location))
	
	last_hovered_slot = hovered_slot
	hovered_slot = slot
		
	if hovered_slot != null and hovered_slot.item_stored != null:
		hovered_item = hovered_slot.item_stored
	else:
		hovered_item = null
	
	if item_held:
		slots_under_item = get_slots_under_item()
		can_place = item_can_fit()
		
	if last_hovered_slot != hovered_slot:
		redraw_highlights()
			
func _on_mouse_exited_slot(slot):
	#print("Exited slot (" + str(hovered_slot.slotgrid_location[0]) + ", " + str(hovered_slot.slotgrid_location[1]) + ")")
	# If hovered_slot is the one being exited, then unset it.
	# This prevents unsetting hovered_slot when _on_slot_mouse_entered sets a new hovered slot before this signal fires.
	print("exited " + str(slot.slotgrid_location))
	if hovered_slot == slot:
		hovered_slot = null
		can_place = false
	
	redraw_highlights()
	
func setup_scene(geometry: Vector2i, max_size = Vector2i(6, 6)):
	scroll_container_max_size = Vector2i(max_size[0] * SLOT_SIZE_PX, max_size[1] * SLOT_SIZE_PX)
	create_slotgrid(geometry)
	scroll_container.size = Vector2i(get_slotgrid_width_pixels(), get_slotgrid_height_pixels())

func resize_slotgrid_container():
	for slotgrid_row_container in slotgrid_container.get_children().filter(func(child): return true if child is GridContainer else false):
		slotgrid_row_container.columns = slotgrid_width
	
	scroll_container.size = Vector2i(
		min(get_slotgrid_width_pixels(), scroll_container_max_size[0]) + int(SLOT_SIZE_PX/3), 
		min(get_slotgrid_height_pixels(), scroll_container_max_size[1]) + int(SLOT_SIZE_PX/3)
	)

func create_slotgrid(geometry: Vector2i):
	add_space_to_slotgrid(geometry)
	resize_slotgrid_container()

func create_slotgrid_row(cols, row):
	var slotgrid_row = GridContainer.new()
	slotgrid_row.add_theme_constant_override("h_separation", 0)
	slotgrid_row.add_theme_constant_override("v_separation", 0)
	
	for col in range(0, cols):
		slotgrid_row.add_child(create_slot(col, row))
	
	return slotgrid_row

func create_slot(col, row):
	var slot: Slot = slot_scene.instantiate()
	slot.slotgrid_index = 0
	slot.slotgrid_location = Vector2i(col, row)
	slot.slot_entered.connect(_on_mouse_entered_slot)
	slot.slot_exited.connect(_on_mouse_exited_slot)
	return slot

func add_space_to_slotgrid(cols_rows: Vector2i):
	# new_space is an int vector denoting the number of (columns, rows) to add to the slotgrid.
	if cols_rows[0] < 0 or cols_rows[1] < 0 or cols_rows == Vector2i(0, 0):
		return
		
	if cols_rows[1] > 0:
		add_rows_to_slotgrid(cols_rows[1])
	
	if cols_rows[0] > 0:
		add_columns_to_slotgrid(cols_rows[0])
		
	resize_slotgrid_container()

func add_rows_to_slotgrid(rows: int):
	for row in range(0, rows):
		var slotgrid_row = create_slotgrid_row(slotgrid_width, slotgrid_container.get_child_count())
		slotgrid_container.add_child(slotgrid_row)

	slotgrid_height += rows

func add_columns_to_slotgrid(cols: int):
	for row in range(0, slotgrid_container.get_child_count()):
		var row_container = slotgrid_container.get_child(row)
		for col in range(0, cols):
			var slot = create_slot(row_container.get_child_count(), row)
			row_container.add_child(slot)
	
	slotgrid_width += cols

func remove_space_from_slotgrid(cols_rows: Vector2i):
	if cols_rows[0] < 0 or cols_rows[1] < 0 or cols_rows == Vector2i(0, 0):
		return
		
	if cols_rows[1] > 0:
		remove_rows_from_slotgrid(cols_rows[1])
		
	if cols_rows[0] > 0:
		remove_columns_from_slotgrid(cols_rows[0])
		
	resize_slotgrid_container()

# Currently, an all or nothing operation
func remove_rows_from_slotgrid(rows: int):
	var rows_to_delete = []
	var can_delete = true
	
	if rows > slotgrid_height:  # Attempting to remove more rows than exist
		return
	
	# Collect all the rows to delete
	for i in range(0, rows):
		if not can_delete:  # Stop looping if we already know we cant remove the row
			break
			
		var row = slotgrid_container.get_child(slotgrid_container.get_child_count() - 1)
		rows_to_delete.push_back(row)
		
		# Check that no slot in the row is occupied
		for slot in row.get_children():
			if slot.state == Slot.States.OCCUPIED:
				can_delete = false
				break
		
	if can_delete:
		for row in rows_to_delete:
			remove_child(row)
			row.queue_free()
	
		
		slotgrid_height -= rows  # Only update the height if we actually delete rows
	
# Currently, an all or nothing operation
func remove_columns_from_slotgrid(cols: int):
	var slots_to_delete = []
	var can_delete = true
	
	if cols > slotgrid_width:  # Attempting to remove more columns than exist
		return
	
	# Collect all the slots to delete
	for row in slotgrid_container.get_children():
		if not can_delete:  # Stop looping if we already know we cant remove the columns
			break
		
		for col in range(0, cols):
			var slot = row.get_child(row.get_child_count() - 1)
			slots_to_delete.push_back(slot)
			
			if slot.state == Slot.States.OCCUPIED:  # Check that the slot isnt occupied
				can_delete = false
				break
		
	if can_delete:
		for slot in slots_to_delete:	
			remove_child(slot)
			slot.queue_free()
		
		slotgrid_width -= cols  # Only update the width if we actually delete columns
	
func get_slots_under_item():
	var slots = []
	var held_item_width = item_held.get_slot_width()
	var held_item_height = item_held.get_slot_height()
	var hovered_slot_col = hovered_slot.slotgrid_location[0]
	var hovered_slot_row = hovered_slot.slotgrid_location[1]
	
	# No hovered_slot set, outside of slotgrid
	if hovered_slot == null:
		return slots
	
	# Check that slots will all be within the slotgrid
	if hovered_slot_col + held_item_width > slotgrid_width:
		return slots
	elif hovered_slot_row + held_item_height > slotgrid_height:
		return slots
	
	for row in range(0, held_item_height):
		var slotgrid_row_container = slotgrid_container.get_child(hovered_slot_row + row)
		for col in range(0, held_item_width):
			slots.push_back(slotgrid_row_container.get_child(hovered_slot_col + col))
	
	return slots

# FIXME: gross
func item_can_fit():
	for slot in slots_under_item:
		# The slot is storing an item and it is stackable
		if slot.state == Slot.States.OCCUPIED:
			if slot.item_stored.item_resource_data.item_id != item_held.item_resource_data.item_id:
				return false  # Items are not the same type of item
			elif slot.item_stored.item_resource_data.stackable:
				if slot.current_stack_size == slot.item_stored.item_resource_data.max_stack_size:
					return false  # Slot is already storing max stacksize
				elif slot.current_stack_size + item_held.current_stack_size > slot.item_stored.item_resource_data.max_stack_size:
					return false  # Placing would put slot over max stacksize
			else:
				return false

	return true

func redraw_highlights():
	var highlight_color = Slot.States.DEFAULT
	
	# Reset the entire slotgrid
	for row_container in slotgrid_container.get_children():
		for slot in row_container.get_children().filter(func(child): return true if child is Slot else false):
			if slot.highlighted:
				slot.set_highlight_color(highlight_color)
	
	if item_held and hovered_slot:
		highlight_color = Slot.States.EMPTY if can_place else Slot.States.OCCUPIED
		
		for slot in slots_under_item:
			slot.set_highlight_color(highlight_color)

# TODO: manually set item's mouse filter
func place_item():
	can_place = item_can_fit()
	if not can_place:
		return
	
	for slot in slots_under_item:
		slot.state = slot.States.OCCUPIED
		slot.item_stored = item_held
		slot.current_stack_size += 1
			
	item_held.position = Vector2i(
		hovered_slot.slotgrid_location[0] * SLOT_SIZE_PX, 
		hovered_slot.slotgrid_location[1] * SLOT_SIZE_PX
	)
	item_held.occupied_slots = slots_under_item
	item_held.selected = false
	
	item_held = null
	emit_signal("slot_entered", hovered_slot)

# TODO: manually set item's mouse filter
func pick_item():
	if hovered_item == null:
		return
		
	item_held = hovered_slot.item_stored
	var item_previously_occupied_slots = item_held.occupied_slots
	slots_under_item = get_slots_under_item()
	item_held.occupied_slots = []
	
	for item_slot in item_previously_occupied_slots:
		item_slot.state = item_slot.States.DEFAULT
		item_slot.item_stored = null
		item_slot.current_stack_size = 0
		
	item_held.selected = true
	can_place = item_can_fit()
	redraw_highlights()

func get_slotgrid_width_pixels():
	return slotgrid_width * SLOT_SIZE_PX
	
func get_slotgrid_height_pixels():
	return slotgrid_height * SLOT_SIZE_PX

func get_slotgrid_container_width_pixels():
	# ONLY USE FOR DEBUGING
	# Should always return the same as get_slotgrid_width_pixels.
	# Difference in return values should indicate that slotgrid_width was not updated properly
	if slotgrid_container.get_child_count() > 0:  # No rows in the slotgrid
		return slotgrid_container.get_child(0).get_child_count() * SLOT_SIZE_PX
	else:
		return 0
		
func get_slotgrid_container_height_pixels():
	# ONLY USE FOR DEBUGING
	# Should always return the same as get_slotgrid_height_pixels.
	# Difference in return values should indicate that slotgrid_height was not updated properly
	if slotgrid_container.get_child_count() > 0:  # No rows in the slotgrid
		return slotgrid_container.get_child(0).get_child_count() * SLOT_SIZE_PX
	else:
		return 0

