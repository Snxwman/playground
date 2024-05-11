class_name Slotgrid extends Node

signal mouse_entered_slotgrid(slotgrid)
signal mouse_exited_slotgrid(slotgrid)
signal slotgrid_geometry_changed(slotgrid)
signal item_added_to_slotgrid(slotgrid)
signal item_removed_from_slotgrid(slotgrid)
signal item_placed(item, slotgrid, origin_slot)
signal item_picked(item, slotgrid, from_slot)

@onready var slot_scene = preload("res://Menu/Inventory/Slotgrid/slot.tscn")
@onready var item_scene = preload("res://Menu/Item/item.tscn")

@onready var scroll_container = $"."
@onready var slotgrid_container = $SlotgridContainer
@onready var item_container = $ItemContainer

var geometry: Vector2i = Vector2i(0, 0)
var total_slot_count: int
var occupied_slot_count: int

var focused_slot: Slot
var focused_item: Item

var selected_slots: Array[Slot]
var selected_items: Array[Item]

var items_in_slotgrid: Array[Item]
var value_of_items_in_slotgrid: int

func _ready():
	pass


func _process(_delta):
	pass

		
func _on_mouse_entered_slotgrid():
	mouse_entered_slotgrid.emit(self)
	
	
func _on_mouse_exited_slotgrid():
	mouse_exited_slotgrid.emit(self)
		

func sync():
	sync_ui()
	sync_world()


# TODO
func sync_ui():
	pass
	
	
func sync_world():
	pass
	

# TODO
func setup_scene():
	pass
	

func create_slotgrid(_geometry: Vector2i):
	add_space_to_slotgrid(_geometry)
	total_slot_count = geometry[0] * geometry[1]
	
	
func add_space_to_slotgrid(cols_rows: Vector2i):
	# Verify were not adding negative cols or rows, nor adding (0, 0)
	if cols_rows[0] < 0 or cols_rows[1] < 0 or cols_rows == Vector2i(0, 0):
		return
	
	# Adding rows must be done first in case we are adding rows and columns in one call.
	for row in range(0, cols_rows[1]):
		add_row_to_slotgrid()
		
	for col in range(0, cols_rows[0]):
		add_column_to_slotgrid()
		
	sync()
	slotgrid_geometry_changed.emit(self)
	
	
func add_row_to_slotgrid():
	var row_container = GridContainer.new()
	slotgrid_container.add_child(row_container)
	
	row_container.columns = max(1, get_slotgrid_columns())
	row_container.add_theme_constant_override("h_separation", 1)
	
	for col in range(0, get_slotgrid_columns()):
		var slot = slot_scene.instantiate()
		row_container.add_child(slot)
		slot.create_slot(self, Vector2i(col, slotgrid_container.get_child_count() - 1))
	
	increment_slotgrid_geometry_row()
	
	
func add_column_to_slotgrid():
	increment_slotgrid_geometry_column()
	
	for row_index in range(0, slotgrid_container.get_child_count()):
		var row_container: GridContainer = slotgrid_container.get_child(row_index)
		row_container.columns = get_slotgrid_columns()
		
		var slot = slot_scene.instantiate()
		row_container.add_child(slot)
		slot.create_slot(self, Vector2i(row_container.get_child_count() - 1, row_index))
		
	
func remove_space_from_slotgrid(cols_rows: Vector2i):
	# Verify were not removing negative cols or rows, nor adding (0, 0)
	if cols_rows[0] < 0 or cols_rows[1] < 0 or cols_rows == Vector2i(0, 0):
		return
		
	for row in range(0, cols_rows[1]):
		remove_row_from_slotgrid()
		
	for col in range(0, cols_rows[0]):
		remove_column_from_slotgrid()
	
	sync()
	slotgrid_geometry_changed.emit(self)

	
func remove_row_from_slotgrid():
	var can_delete: bool = true
	
	if get_slotgrid_rows() == 0:  # Attempting to remove a row from nothing
		return
		
	var row_container: GridContainer = slotgrid_container.get_children()[get_slotgrid_rows() - 1]
	for slot in row_container.get_children():
		if slot.stored_item != null:
			can_delete = false
			break
			
	if can_delete:
		slotgrid_container.remove_child(row_container)
		row_container.queue_free()
		
		decrement_slotgrid_geometry_row()
	

func remove_column_from_slotgrid():
	var slots_to_delete: Array[Slot] = []
	var can_delete: bool = true
	
	if get_slotgrid_columns() == 0:  # Attempting to remove a column from nothing
		return
		
	for row_container in slotgrid_container.get_children():
		var slot: Slot = row_container.get_child(row_container.get_child_count() - 1)
		
		if slot.stored_item == null:
			slots_to_delete.push_back(slot)
		else:
			can_delete = false
			break
		
	if can_delete:
		for slot in slots_to_delete:
			remove_child(slot)
			slot.queue_free()
			
		decrement_slotgrid_geometry_column()
	

func get_slots_under_item(item: Item, origin_slot: Slot) -> Array[Slot]:
	var slots: Array[Slot] = []
	var item_width = item.get_slot_width()
	var item_height = item.get_slot_height()
	var origin_slot_col = origin_slot.slotgrid_coord[0]
	var origin_slot_row = origin_slot.slotgrid_coord[1]
	
	# Check that slots will all be within the slotgrid
	if origin_slot_col + item_width > get_slotgrid_columns():
		return slots
	elif origin_slot_row + item_height > get_slotgrid_rows():
		return slots
	
	for row in range(0, item_height):
		var slotgrid_row_container = slotgrid_container.get_child(origin_slot_row + row)
		for col in range(0, item_width):
			slots.push_back(slotgrid_row_container.get_child(origin_slot_col + col))
	
	return slots
	

# FIXME: gross and move to Slot.can_accept_item()
# FIXME: Potential race condition is something is auto-placed between calling this and actually placing
func can_place(item: Item, slots_under_item: Array[Slot]) -> bool:
	for slot in slots_under_item:
		# The slot is storing an item and it is stackable
		if slot.state == Slot.States.OCCUPIED:
			if slot.stored_item.item_resource_data.item_id != item.item_resource_data.item_id:
				return false  # Items are not the same type of item
			elif slot.stored_item.item_resource_data.stackable:
				if slot.current_stack_size == slot.stored_item.item_resource_data.max_stack_size:
					return false  # Slot is already storing max stacksize
				elif slot.current_stack_size > slot.stored_item.item_resource_data.max_stack_size:
					return false  # Placing would put slot over max stacksize
			else:
				return false

	return true
	
	
func place_item(item: Item, origin_slot: Slot, slots_under_item: Array[Slot]):
	for slot in slots_under_item:
		slot.add_stored_item(item)
	
	item.set_position_to_slot(origin_slot)
	item.set_placed(slots_under_item)

	item_container.add_child(item)
	
	origin_slot.mouse_entered_slot.emit(origin_slot)
	
	
func pick_item(from_slot: Slot) -> Item:
	var item = from_slot.stored_item
	var last_occupied_slots = item.occupied_slots
	
	item.set_picked()
	
	for slot in last_occupied_slots:
		slot.remove_stored_item()
	
	item_container.remove_child(item)	
	from_slot.mouse_entered_slot.emit(from_slot)
	return item


func get_all_slots() -> Array[Slot]:
	var slots: Array[Slot] = []
	
	for row_container in slotgrid_container.get_children():
		for slot in row_container.get_children():
			slots.push_back(slot)
			
	return slots


func get_items_in_slotgrid() -> Array[Item]:
	var items: Array[Item] = []
	return items


# TODO
func get_value_of_items_in_slotgrid(_currency = "usd") -> int:
	var total_value: int = -1
	return total_value
	

func get_slotgrid_columns() -> int:
	return geometry[0]
	
	
func get_slotgrid_rows() -> int:
	return geometry[1] 
	

func get_slotgrid_width() -> int:
	var width_px: int = get_slotgrid_columns() * slot_scene.get_slot_size()[0]
	return width_px
	

func get_slotgrid_height() -> int:
	var height_px: int = get_slotgrid_rows() * slot_scene.get_slot_size()[1]
	return height_px
	
	
func increment_slotgrid_geometry_column():
	geometry[0] += 1
	
	
func increment_slotgrid_geometry_row():
	geometry[1] += 1

	
func decrement_slotgrid_geometry_column():
	geometry[0] -= 1

	
func decrement_slotgrid_geometry_row(): 
	geometry[1] -= 1	

