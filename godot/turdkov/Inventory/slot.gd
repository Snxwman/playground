class_name Slot extends Control

signal slot_entered(slot)
signal slot_exited(slot)

@onready var highlight = $SlotHighlight

var slotgrid_index: int
var slotgrid_location: Vector2i
var is_hovering = false

enum States {DEFAULT, OCCUPIED, EMPTY}
var state = States.DEFAULT
var highlighted = false
var item_stored: Item = null
var current_stack_size: int = 0

var filtered = null
var filters = []

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func set_highlight_color(slot_state = States.DEFAULT):
	match slot_state:
		States.DEFAULT:
			#print("setting default " + str(slotgrid_location))
			highlight.color = Color(Color.BLACK, 0.0)
			highlighted = false
		States.OCCUPIED:
			#print("setting occupied " + str(slotgrid_location))
			highlight.color = Color(Color.DARK_RED, 0.2)
			highlighted = true
		States.EMPTY:
			#print("setting free " + str(slotgrid_location))
			highlight.color = Color(Color.DARK_GREEN, 0.2)
			highlighted = true

func _on_mouse_entered_slot():
	emit_signal("slot_entered", self)

func _on_mouse_exited_slot():
	#if not self.get_global_rect().has_point(get_global_mouse_position()):
	emit_signal("slot_exited", self)
