class_name StashSGC extends Control

const DEFAULT_STASH_COLS = 12
const DEFAULT_STASH_LINES = 45
const DEFAULT_STASH_GEOMETRY = Vector2i(DEFAULT_STASH_COLS, DEFAULT_STASH_LINES)

const DEFAULT_SLOT_SIZE_PX = 64
const DEFAULT_IMPLIED_LINE_TO_SHOW = 0.4
const DEFAULT_STASH_LINES_TO_SHOW = 18 + DEFAULT_IMPLIED_LINE_TO_SHOW
const DEFAULT_STASH_MARGIN = 4

@onready var slotgrid_scene = preload("res://Menu/Inventory/Slotgrid/slotgrid.tscn")

@onready var root_node = $"."
@onready var background_node = $ColorRect
@onready var slotgrid_container = $ColorRect/MarginContainer

var slotgrid: Slotgrid

# Called when the node enters the scene tree for the first time.
func _ready():
	setup_scene()
	
	slotgrid = slotgrid_scene.instantiate()
	slotgrid_container.add_child(slotgrid)

	slotgrid.create_slotgrid(DEFAULT_STASH_GEOMETRY)


func _process(_delta):
	pass


func setup_scene():
	var minimum_size = Vector2i(
		(DEFAULT_STASH_COLS * DEFAULT_SLOT_SIZE_PX) + (DEFAULT_STASH_COLS - 1) + (DEFAULT_STASH_MARGIN * 2),
		(DEFAULT_STASH_LINES_TO_SHOW * DEFAULT_SLOT_SIZE_PX) + (DEFAULT_STASH_COLS - 1) + (DEFAULT_STASH_MARGIN * 2),
	)
	
	root_node.set_custom_minimum_size(minimum_size)
	background_node.set_custom_minimum_size(minimum_size)
	
	slotgrid_container.add_theme_constant_override("margin_top", DEFAULT_STASH_MARGIN)
	slotgrid_container.add_theme_constant_override("margin_right", DEFAULT_STASH_MARGIN)
	slotgrid_container.add_theme_constant_override("margin_bottom", DEFAULT_STASH_MARGIN)
	slotgrid_container.add_theme_constant_override("margin_left", DEFAULT_STASH_MARGIN)
