class_name Item extends Control

signal item_rotated(item)

const SLOT_SIZE_PX = 64
const DEG_90 = deg_to_rad(90)

const INSURED_COLOR = Color("04acec", 0.9)
const DEFAULT_BORDER_COLOR = Color("#cccccc", 0.9)
const BORDER_OFFSET = 2

@onready var slotgrid_scene = preload("res://Inventory/slotgrid.tscn")
@onready var subinventory_container_scene = preload("res://Inventory/subinventory.tscn")

# Item ui components
@onready var item_interior = $Interior
@onready var item_background = $Interior/ItemBackground
@onready var item_border = $ItemBorder
@onready var unequippable_filter = $Interior/UnequippableFilter
@onready var item_icon = $Interior/HBoxContainer/ItemDetails/ItemIconMargin/Icon
@onready var special_icon_container = $Interior/HBoxContainer/ItemDetails/MarginContainer
@onready var subinventory_container = $SubinventoryContainer
# Item stats
@onready var durability_bar = $Interior/HBoxContainer/DurabilityBar
@onready var short_name_label = $Interior/HBoxContainer/ItemDetails/ShortName
@onready var trade_value_label = $Interior/HBoxContainer/ItemDetails/TradeValue
@onready var capacity_label = $Interior/HBoxContainer/ItemDetails/Capacity
# Special statuses
@onready var insured_icon = $Interior/HBoxContainer/ItemDetails/MarginContainer/VBoxContainer/InsuredIcon
@onready var looted_icon = $Interior/HBoxContainer/ItemDetails/MarginContainer/VBoxContainer/LootedIcon

# References
var item_id: String
var instance_id: String
var item_resource_data: ItemData

# Item stats
var durability
var capacity
var trade_value: int  # TODO: Turn into a struct that tracks that modifiers of trade value
var insured = false
var looted = false

# Item state
var selected = false
var rotated = false
var equippable = true
var occupied_slots = []
var subinventory_open = false
var item_info_open = false

# Called when the node enters the scene tree for the first time.
#func _ready():
	#var items = ["backpack", "bullet", "grenade", "helmet", "knife", "plate_carrier", "rifle"]
	#spawn_with_random_stats(items.pick_random())
	#selected = true

func _input(event):
	if event.is_action_pressed("rotate") and selected:
		rotate_scene()
	
	if Input.is_action_just_pressed("close_window"):
		close_subinventory()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	if selected:  # Follow mouse while selected
		global_position = get_global_mouse_position()

func spawn(item_resource_id: String):
	item_resource_data = load("res://Items/" + item_resource_id + ".tres")

	durability = item_resource_data.max_durability
	capacity = item_resource_data.default_capacity
	trade_value = calculate_trade_value()
	
	setup_scene()
	connect("subinventory_closed", close_subinventory)

func spawn_with_random_stats(item_resource_id: String):
	item_resource_data = load("res://Items/" + item_resource_id + ".tres")
	
	insured = true if randi_range(1,100) <= 20 else false
	looted = true if randi_range(1,100) <= 40 else false
	durability = randi_range(0, item_resource_data.max_durability)
	capacity = randi_range(0, item_resource_data.max_capacity)
	trade_value = calculate_trade_value()
	
	setup_scene()

func load_from_save():
	pass
		
func setup_scene():
	var item_size = Vector2i(get_slot_width() * SLOT_SIZE_PX, get_slot_height() * SLOT_SIZE_PX)
	
	item_interior.size = item_size - Vector2i(BORDER_OFFSET, BORDER_OFFSET)
	item_border.size = item_size
	unequippable_filter.size = item_size
	item_background.set_pivot_offset(Vector2i(get_slot_height()/2, get_slot_height()/2))

	item_icon.texture = item_resource_data.icon
	short_name_label.text = item_resource_data.short_name
	trade_value_label.text = "$ " + str(trade_value)
	
	unequippable_filter.visible = true if not equippable else false
	looted_icon.visible = true if looted else false
	
	if item_resource_data.has_capacity:
		capacity_label.text = str(item_resource_data.default_capacity) + "/" + str(item_resource_data.max_capacity)
	else:
		capacity_label.visible = false
	
	if item_resource_data.has_durability:
		durability_bar.max_value = item_resource_data.max_durability
		durability_bar.value = durability
	else:
		durability_bar.visible = false

	if insured:
		item_border.border_color = INSURED_COLOR
		insured_icon.visible = true
	else:
		item_border.border_color = DEFAULT_BORDER_COLOR
		insured_icon.visible = false
	
func rotate_scene():
	# Ignore rotation for square items
	if item_resource_data.slot_geometry[0] == item_resource_data.slot_geometry[1]:
		return
	
	rotated = true if not rotated else false
	
	if rotated:
		item_interior.rotation = DEG_90
		item_border.rotation = DEG_90
		item_interior.position = Vector2i(get_slot_width() * SLOT_SIZE_PX, 0)
		item_border.position = Vector2i(get_slot_width() * SLOT_SIZE_PX, 0)
		
		#special_icon_container.rotation = -DEG_90
		#short_name_label.rotation = -DEG_90
		#capacity_label.rotation = -DEG_90
		#trade_value_label.rotation = -DEG_90
		##special_icon_container.position = Vector2(0, 0)
		##short_name_label.position = Vector2(0, 0)
		##capacity_label.position = Vector2(0, 0)
		##trade_value_label.position = Vector2(0, 0)
		#special_icon_container.set_anchors_preset(Control.PRESET_BOTTOM_LEFT, true)
		#short_name_label.set_anchors_preset(Control.PRESET_TOP_LEFT, true)
		#capacity_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT, true)
		#trade_value_label.set_anchors_preset(Control.PRESET_TOP_RIGHT, true)
	else:
		item_interior.rotation = 0
		item_border.rotation = 0
		item_interior.position = Vector2i(0, 0)
		item_border.position = Vector2i(0, 0)
		
		#special_icon_container.rotation = 0
		#short_name_label.rotation = 0
		#capacity_label.rotation = 0
		#trade_value_label.rotation = 0
		##special_icon_container.position = Vector2(0, 0)
		##short_name_label.position = Vector2(0, 0)
		##capacity_label.position = Vector2(0, 0)
		##trade_value_label.position = Vector2(0, 0)
		#special_icon_container.set_anchors_preset(Control.PRESET_TOP_LEFT, true)
		#short_name_label.set_anchors_preset(Control.PRESET_TOP_RIGHT, true)
		#capacity_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT, true)
		#trade_value_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT, true)
		
		
	emit_signal("item_rotated", self)

func get_slot_width():
	return item_resource_data.slot_geometry[0] if not rotated else item_resource_data.slot_geometry[1]	

func get_slot_height():
	return item_resource_data.slot_geometry[1] if not rotated else item_resource_data.slot_geometry[0]

func calculate_trade_value():
	var demand_modifier: float = 1.0
	var is_looted_modifier: float = 1.0 + (0.15 * int(looted))
	var is_insured_modifier: float = 1.0 + (0.2 * int(insured))
	var is_equippable_modifier: float = 1.0 - (0.7 * int(not equippable))
	
	var current_durability_modifier: float
	if item_resource_data.has_durability:
		var percent = (float(durability) / float(item_resource_data.max_durability))
		current_durability_modifier = percent if percent < 0.9 else 1.0
	else:
		current_durability_modifier = 1.0
		
	var calculated_trade_value = (
		item_resource_data.base_trade_value *
		current_durability_modifier * 
		demand_modifier * 
		is_looted_modifier * 
		is_insured_modifier *
		is_equippable_modifier
	)
	#print("---")
	#print("Base Trade Value: " + str(item_resource_data.base_trade_value))
	#print("Durability: " + str(current_durability_modifier))
	#print("Demand: " + str(demand_modifier))
	#print("Looted: " + str(is_looted_modifier))
	#print("Insured: " + str(is_insured_modifier))
	#print("Equippable: " + str(is_equippable_modifier))
	#print("---")
	return int(calculated_trade_value / 100)
	
func open_subinventory():
	if not item_resource_data.has_internal_storage:
		return
	
	if subinventory_container.get_child_count() != 0:  # Scene has already been instantiated and setup 
		subinventory_container.visible = true
	else:
		var subinventory = subinventory_container_scene.instantiate()
		subinventory_container.add_child(subinventory)
		subinventory.setup_scene(self)
		subinventory.close_subinventory.connect(close_subinventory)
		
func close_subinventory():
	subinventory_container.visible = false
