class_name Stash extends Control

const STASH_WIDTH: int = 12
const STASH_LINES: int = 45
const STASH_GEOMETRY: Vector2 = Vector2(STASH_WIDTH, STASH_LINES)
const SLOT_SIZE_PX = 64

# DEBUG
const items = ["backpack", "bullet", "grenade", "helmet", "knife", "plate_carrier", "rifle"]

@onready var slotgrid_scene = preload("res://Inventory/slotgrid.tscn")
@onready var item_scene = preload("res://Items/item.tscn")
@onready var slotgrid_container = $VBoxContainer/SlotgridContainer

var slotgrid: Slotgrid

func _input(event):
	pass

func _ready():
	slotgrid = slotgrid_scene.instantiate()
	slotgrid_container.add_child(slotgrid)
	slotgrid.create_slotgrid(STASH_GEOMETRY)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_spawn_button_pressed():
	if not slotgrid.item_held:
		var item = item_scene.instantiate()
		slotgrid.slotgrid_container.add_child(item)
		
		item.spawn_with_random_stats(items.pick_random())
		item.selected = true
		item.item_rotated.connect(slotgrid._on_item_rotated)
	
		slotgrid.item_held = item
		
	

