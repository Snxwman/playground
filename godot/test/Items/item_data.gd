extends Resource

class_name ItemData

enum ItemType {GEAR, AMMO, WEAPON, PROVISION, MEDICAL, BARTER, MONEY}
enum GearType {BACKPACK, HELMET}
enum AmmoType {}
enum WeaponType {}
enum ProvisionType {FOOD, WATER, SUPPLEMENT, STIM}

@export var icon: Texture2D
@export var item_id: String = ""  # Maybe use int and have ranges for item types?
@export var item_type: ItemType
# TODO: Sub item types (i.e. GEAR:BACKPACK) 
#       maybe - https://github.com/godotengine/godot-proposals/issues/1056

@export var long_name: String = ""
@export var short_name: String = ""
@export_multiline var description: String = ""

@export var weight: int = 1            # Tenths of a pound
@export var base_trade_value: int = 1  # Cents

@export_group("Slot Geometry")
@export var slot_geometry: Vector2 = Vector2(1, 1)
@export_subgroup("Internal Slot Geometry")
@export var has_internal_storage: bool = false
@export var internal_slot_geometry: Vector2 = Vector2(1, 1)

@export_group("Stacking")
@export var stackable: bool = false
@export var max_stack_size: int = 1
@export var default_stack_size: int = 1

@export_group("Durability")
@export var has_durability: bool = false
@export var max_durability: int = 100
@export var default_durability: int = 100
@export_subgroup("Durability Levels")
@export var med_durability: int
@export var low_durability: int

@export_group("Capacity")
@export var has_capacity: bool = false
@export var max_capacity: int = 1
@export var default_capacity: int = 1
@export_subgroup("Capacity Levels")
@export var med_capacity: int
@export var low_capacity: int

