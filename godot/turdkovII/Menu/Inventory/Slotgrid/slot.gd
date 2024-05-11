class_name Slot extends Node

signal mouse_entered_slot(slot)
signal mouse_exited_slot(slot)
signal mouse_clicked_slot(slot, modifier_keys)
signal mouse_double_clicked_slot(slot)
signal mouse_began_drag_on_slot(slot)
signal mouse_ended_drag_on_slot(slot)

static var DEFAULT_SLOT_SIZE_PX := 64

const COLOR_CLEAR := Color(Color.BLACK, 0.0)
const COLOR_CAN_PLACE := Color(Color.DARK_GREEN, 0.2)
const COLOR_CAN_PLACE_PARTIAL := Color(Color.DARK_GOLDENROD, 0.2)
const COLOR_CANT_PLACE := Color(Color.DARK_RED, 0.2)

@onready var root_node = $"."
@onready var border_node = $Border
@onready var background_node = $Border/MarginContainer/Background
@onready var highlight_node = $Highlight

enum Highlights {
	CLEAR,
	CAN_PLACE,
	CAN_PLACE_PARTIAL,
	CANT_PLACE,
}

enum States {
	EMPTY,
	OCCUPIED,
	BLOCKED
}

var slot_size_px: Vector2i = Vector2i(DEFAULT_SLOT_SIZE_PX, DEFAULT_SLOT_SIZE_PX)
var parent_slotgrid: Slotgrid
var slotgrid_coord: Vector2i

var state: States = States.EMPTY
var highlighted: bool = false
var highlight: Highlights = Highlights.CLEAR

var filtered: bool = false
var filters: Array = []

var stored_item: Item = null
var current_stack_size: int = 0

func _ready():
	pass


func _process(_delta):
	pass


func _on_mouse_entered_slot():
	mouse_entered_slot.emit(self)
	
	
func _on_mouse_exited_slot():
	mouse_exited_slot.emit(self)
	
	
#func _on_mouse_clicked_slot(slot):
	#"mouse_clicked_slot.emit(self)
	#
	#
#func _on_mouse_double_clicked_slot(slot):
	#mouse_double_clicked_slot.emit(self)
	#
	#
#func _on_mouse_began_drag_on_slot(slot):
	#mouse_began_drag_on_slot.emit(self)
	#
	#
#func _on_mouse_ended_drag_on_slot(slot):
	#mouse_ended_drag_on_slot.emit(self)
	
	
func sync():
	sync_ui()
	sync_world()
	

func sync_ui():
	match highlight:
		Highlights.CLEAR:
			highlight_node.color = COLOR_CLEAR
		Highlights.CAN_PLACE:
			highlight_node.color = COLOR_CAN_PLACE
		Highlights.CAN_PLACE_PARTIAL:
			highlight_node.color = COLOR_CAN_PLACE_PARTIAL
		Highlights.CANT_PLACE:
			highlight_node.color = COLOR_CANT_PLACE


func sync_world():
	pass


func setup_scene():
	root_node.set_custom_minimum_size(slot_size_px)
	border_node.set_custom_minimum_size(slot_size_px)
	highlight_node.set_custom_minimum_size(slot_size_px)


func create_slot(parent: Slotgrid = null, coord: Vector2i = Vector2i(0, 0)):
	parent_slotgrid = parent
	slotgrid_coord = coord
	
	setup_scene()
	sync()
	
	
func update_slot_size(size: Vector2i):
	slot_size_px = size
	setup_scene()
	
	
func update_filters(_filters: Array = []):
	if _filters:
		filtered = true
		filters = _filters
	else:
		filtered = false
		filters = []
			

func set_highlight(highlight_variant: Highlights):
	highlighted = false if highlight_variant == Highlights.CLEAR else true
	highlight = highlight_variant
	sync()
			
			
func set_state(state_variant: States):
	state = state_variant


func can_accept_item(_item: Item) -> bool:
	return true


func add_stored_item(item: Item):
	state = States.OCCUPIED
	stored_item = item
	#current_stack_size += item.current_stack_size

	
func add_stored_item_partial(_item: Item):
	pass


func remove_stored_item():
	state = Slot.States.EMPTY
	stored_item = null
	current_stack_size = 0


func get_slot_size() -> Vector2i:
	return slot_size_px


func get_slot_position() -> Vector2i:
	return Vector2i(
		self.position[0],
		self.get_parent().position[1]
	)
