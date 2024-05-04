class_name Hideout extends Control

@onready var stash_scene = preload("res://Inventory/stash.tscn")
@onready var stash_container = $HBoxContainer

func _input(event):
	if event.is_action_pressed("quit"):
		get_tree().quit()

func _ready():
	pass
