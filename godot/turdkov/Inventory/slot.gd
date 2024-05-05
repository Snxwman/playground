class_name Slot extends Control

@onready var highlight = $SlotHighlight

var slotgrid_index: int
var slotgrid_location: Vector2
var is_hovering = false

enum States {DEFAULT, OCCUPIED, EMPTY}
var state = States.DEFAULT
var item_stored: Item = null
var current_stack_size: int = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
	#if get_global_rect().has_point(get_global_mouse_position()):
		#if not is_hovering:
			#is_hovering = true
			#emit_signal("slot_entered", self)
	#elif is_hovering:
		#is_hovering = false
		#emit_signal("slot_exited", self)			
	
func set_highlight_color(slot_state = States.DEFAULT):
	match slot_state:
		States.DEFAULT:
			highlight.color = Color(Color.BLACK, 0.0)
		States.OCCUPIED:
			highlight.color = Color(Color.DARK_RED, 0.2)
		States.EMPTY:
			highlight.color = Color(Color.DARK_GREEN, 0.2)
