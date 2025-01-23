extends Node2D

@onready var initial_fill = %p2d_initial_fill

@export var initial_color: Color
@export var final_color: Color
@export var radius: float # Note: this is the final radius of their full shape, not the true final radius

var win_w: float
var win_h: float

# Called when the node enters the scene tree for the first time.
func _ready():
	var win_size = get_viewport().get_window().size
	win_w = win_size[0]
	win_h = win_size[1]
	
	# Add these points to the initial fill polygon
	initial_fill.color = initial_color
	var vertices: PackedVector2Array
	vertices.append(Vector2(0, 0))
	vertices.append(Vector2(0, win_h))
	vertices.append(Vector2(win_w, win_h))
	vertices.append(Vector2(win_w, 0))
	
	initial_fill.polygon = vertices
	
	# Create our growing polygons
	var num_rows = ceil(win_h/(2*radius))
	var num_cols = ceil(win_w/(2*radius))
	for i in range(num_cols):
		for j in range(num_rows):
			var pos = Vector2((i*radius*2) + radius, (j*radius*2) + radius)
			create_poly(final_color, radius, pos, 24)
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	#create_poly(radius, Vector2(win_w/2, win_h/2))


func create_poly(color: Color, radius: float, position: Vector2 = Vector2(0, 0),num_faces: float = 32) -> Polygon2D:
	var new_poly: Polygon2D = Polygon2D.new()
	new_poly.polygon = utils.generate_nsided_polygon(radius, num_faces)
	self.add_child(new_poly)
	new_poly.position = position
	new_poly.color = color
	return new_poly
