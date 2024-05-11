class_name Item extends Control

signal item_rotated(item)

const DEG_90 = deg_to_rad(90)

const INSURED_COLOR = Color("04acec", 0.9)
const DEFAULT_BORDER_COLOR = Color("#8C9BAB", 0.9)
const BORDER_OFFSET = 2

@onready var slotgrid_scene = preload("res://Menu/Inventory/Slotgrid/slot.tscn")
@onready var slot_scene = preload("res://Menu/Inventory/Slotgrid/slot.tscn")
@onready var subinventory_scene = preload("res://Menu/Inventory/subinventory.tscn")
@onready var subinventory_sgc_scene = preload("res://Menu/Inventory/Slotgrid/sgc_subinventory.tscn")

# Item ui components
@onready var root_node = $"."
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
var item_resource_data: ItemResource

# Item stats
var durability
var capacity
var trade_value: int  # TODO: Turn into a struct that tracks that modifiers of trade value
var insured = false
var looted = false

# Item state
var occupied_slots: Array[Slot] = []
var selected: bool = false
var placed: bool = false
var rotated: bool = false
var equippable: bool = true
var subinventory_open: bool = false
var subinventory_geometry = null
var item_info_open: bool = false

var subinventory_sgc: SubinventorySGC

var mouse_inside_item: bool = false
var mouse_inside_slot: Slot

func _ready():
	pass


func _input(event):
	#if event is InputEventMouseMotion and mouse_inside_item and placed:
		#for slot in occupied_slots:
			#if slot.get_global_rect().has_point(event.position) and slot != mouse_inside_slot:
				#mouse_inside_slot = slot
				#slot.mouse_entered_slot.emit(slot)
	
	if event.is_action_pressed("rotate") and selected:
		rotate_scene()
		item_rotated.emit()
	elif event.is_action_pressed("close_window"):
		close_subinventory()
		

func _process(_delta):
	if selected:  # Follow mouse while selected
		global_position = get_global_mouse_position()


#func _on_mouse_entered_item():
	#mouse_inside_item = true
	
	
#func _on_mouse_exited_item():
	#mouse_inside_item = false
	#mouse_inside_slot = null


func sync():
	sync_ui()
	sync_world()
	
	
func sync_ui():
	#root_node.mouse_filter = MOUSE_FILTER_STOP if placed else MOUSE_FILTER_IGNORE
	pass
		
		
func sync_world():
	pass
	
	
func setup_scene():
	var item_size = Vector2i(get_slot_width() * Slot.DEFAULT_SLOT_SIZE_PX, get_slot_height() * Slot.DEFAULT_SLOT_SIZE_PX)
	
	root_node.set_custom_minimum_size(item_size)
	
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
	

func spawn(item_resource_id: String):
	item_resource_data = load("res://Menu/Item/Items/" + item_resource_id + ".tres")
	
	durability = item_resource_data.max_durability
	capacity = item_resource_data.default_capacity
	trade_value = calculate_trade_value()
	
	connect("subinventory_closed", close_subinventory)
	setup_scene()
	sync()


func spawn_with_random_stats(item_resource_id: String):
	item_resource_data = load("res://Menu/Item/Items/" + item_resource_id + ".tres")
	
	insured = true if randi_range(1,100) <= 20 else false
	looted = true if randi_range(1,100) <= 40 else false
	if item_resource_data.has_durability:
		durability = randi_range(0, item_resource_data.max_durability)
	if item_resource_data.has_capacity:
		capacity = randi_range(0, item_resource_data.max_capacity)
	trade_value = calculate_trade_value()
	
	if item_resource_data.has_internal_storage:
		var item_class = load("res://Menu/Item/Items/" + item_resource_id + ".gd")
		subinventory_geometry = item_class.internal_slotgrid_geometry
	
	setup_scene()
	sync()


func load_from_save():
	pass


func set_placed(slots_under_item: Array[Slot]):
	placed = true
	selected = false
	occupied_slots = slots_under_item
	sync() 
	

func set_picked():
	placed = false
	selected = true
	occupied_slots = []
	sync()


func set_position_to_slot(origin_slot: Slot):
	self.position = origin_slot.get_slot_position()
	
	
func rotate_scene():
	# Ignore rotation for square items
	if item_resource_data.slot_geometry[0] == item_resource_data.slot_geometry[1]:
		return
	
	rotated = true if not rotated else false
	
	if rotated:
		item_interior.rotation = DEG_90
		item_border.rotation = DEG_90
		item_interior.position = Vector2i(get_slot_width() * Slot.DEFAULT_SLOT_SIZE_PX, 0)
		item_border.position = Vector2i(get_slot_width() * Slot.DEFAULT_SLOT_SIZE_PX, 0)
	else:
		item_interior.rotation = 0
		item_border.rotation = 0
		item_interior.position = Vector2i(0, 0)
		item_border.position = Vector2i(0, 0)
		
	item_rotated.emit(self)


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
		var subinventory = subinventory_sgc_scene.instantiate()
		subinventory_container.add_child(subinventory)
		subinventory.setup_scene(self)
		subinventory.close_subinventory.connect(close_subinventory)
		
		return subinventory.slotgrid_container.get_child(0)
	
		
func close_subinventory():
	subinventory_container.visible = false


func get_subinventory_slotgrid():
	return subinventory_container.get_child(0).get_child(0).get_child(1).get_child(0)
