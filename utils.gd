# General utils singleton for my projects. At some point it might make sense
# to have multiple of these seperated by scope, but for now having a single
# autoload that I use in all of my projects sounds easier.
#
#TODO
# 1. Add basic functionality of an `await X or Y` and `await X and Y`.
#    https://github.com/godotengine/godot-proposals/issues/6243#issuecomment-1419495665

extends Node

signal fps_initialized

var original_win_size
var physics_timers := {}
var process_timers := {}
var rng: RandomNumberGenerator
var avg_delta: float
var avg_delta_ms: float
var half_delta: float
var half_delta_ms: float
var fps: float = -9


func _ready():
	# Set up RNG
	randomize()
	rng = RandomNumberGenerator.new()
	rng.randomize()


func _physics_process(delta):
	if physics_timers.size() > 0:
		for key in physics_timers.keys():
			physics_timers[key] -= 1
			if physics_timers[key] <= 0:
				emit_signal(key)
				physics_timers.erase(key)


func _process(delta):
	if (fps < 0) and (Engine.get_frames_drawn() >= 200):
		fps = Engine.get_frames_per_second()
		avg_delta = 1.0/fps
		half_delta = avg_delta/2.0
		avg_delta_ms = avg_delta*1000.0
		half_delta_ms = half_delta*1000.0
		emit_signal("fps_initialized")
	elif process_timers.size() > 0:
		for key in process_timers.keys():
			process_timers[key] -= (delta*1000.0)
			if process_timers[key] <= half_delta_ms: # i.e. round()
				emit_signal(key)
				process_timers.erase(key)


func wait(delay_ms: float, timer_name: String = '') -> void:
	if timer_name == '':
		timer_name = str(randf())
	process_timers[timer_name] = delay_ms
	add_signal(timer_name)
	await Signal(self, timer_name)


func physics_wait(frame_delay: int, timer_name: String = '') -> void:
	if timer_name == '':
		timer_name = str(randf())
	physics_timers[timer_name] = frame_delay
	add_signal(timer_name)
	await Signal(self, timer_name)


# Function to generate n-sided polygons such as fixation circle
func generate_nsided_polygon(radius: float, num_sides: int, position: Vector2) -> PackedVector2Array:
	# Function from SanderVanhove (https://ask.godotengine.org/81776/)
	var angle_delta: float = (PI * 2) / num_sides
	var vector: Vector2 = Vector2(radius, 0)
	var polygon: PackedVector2Array

	for _i in num_sides:
		polygon.append(vector + position)
		vector = vector.rotated(angle_delta)

	return polygon


# Function to calculate visual degrees per pixel
func deg_per_px(height_cm: float, distance_cm: float, resolution: int) -> float:
	# Translation of https://osdoc.cogsci.nl/3.3/visualangle/
	return rad_to_deg(atan2(0.5*height_cm, distance_cm) / (0.5 * resolution))


# Function to convert pixels -> visual degrees
func pix_to_deg(height_cm: float, distance_cm: float, resolution: int, size_in_px: int) -> float:
	# Translation of https://osdoc.cogsci.nl/3.3/visualangle/
	return size_in_px * deg_per_px(height_cm, distance_cm, resolution)


# Function to convert visual degrees -> pixels
func deg_to_pix(height_cm: float, distance_cm: float, resolution: int, size_in_deg: float) -> int:
	# Translation of https://osdoc.cogsci.nl/3.3/visualangle/
	return roundi(size_in_deg / deg_per_px(height_cm, distance_cm, resolution))


# Convert milliseconds to frames using `roundi()`
func ms_to_frames(time_ms: float, refresh_rate: float) -> int:
	return roundi(time_ms / (1000 / refresh_rate))


# Function to simply load a file and return contents as text
func load_text(filename: String) -> String:
	return FileAccess.open(filename, FileAccess.READ).get_as_text()


# Function to parse 2D CSVs and return 2D Array
func load_csv_to_array(filename: String) -> Array:
	var return_data = []
	var raw_data = FileAccess.open(filename, FileAccess.READ)
	while !raw_data.eof_reached():
		return_data.append(raw_data.get_csv_line())
	return return_data


func pix_to_font_size(pix: float) -> float:
	# Approximate the conversion from pixels to font size (with Open Sans)
	# Here are the numbers I got
	#TODO: find a better formula at some point
	#124/172 == 0.7209302325581395
	# 119/164 == 0.725609756097561
	# 113/156 == 0.7243589743589744
	# 101/140 == 0.7214285714285714
	# 92/128 ==0.71875
	# 73/100 == 0.73
	# 46/64 == 0.71875
	# 24/32 == 0.75
	# 17/24 == 0.7083333333333333
	# 13/18 == 0.7222222222222222
	# Average := 0.7240383089998802
	return roundi(pix / 0.724)


func log_x(input: float, base: float) -> float:
	return log(input) / log(base)


func R_A(f: float) -> float:
	# f is freq, this formula is from wikipedia
	# https://en.wikipedia.org/wiki/A-weighting
	# Note: the sqrt does not encapsulate the final addition
	var numerator = pow(12194, 2) * pow(f, 4)
	var denominator = ((pow(f, 2) + pow(20.6, 2)) + 
	sqrt((pow(f, 2) + pow(107.7, 2)) * (pow(f, 2) + pow(737.9, 2))) * 
	(pow(f, 2) + pow(12194, 2)))
	return numerator / denominator


func A_weight(f: float) -> float:
	# f is freq, this formula is from wikipedia
	# https://en.wikipedia.org/wiki/A-weighting
	return (20*log_x(R_A(f), 10)) - (20*log_x(R_A(1000), 10))


func free_application() -> void:
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	get_tree().quit()


func arrays_equal(arr1: Array, arr2: Array, err: float = 0.001) -> bool:
	# If error is 0, check if it's exactly the same
	if err == 0:
		return arr1.hash() == arr2.hash()
	
	# Otherwise, check each element against the error/epsilon allowance
	if len(arr1) != len(arr2):
		return false
	for i in range(len(arr1)):
		if arr1[i] - arr2[i] > err:
			return false
	return true


func array_sum(array: Array) -> float:
	var sum := 0.0
	for i in array:
		sum += i
	return sum


func randf_range_array(from: float, to: float, length: int) -> Array:
	var arr = []
	for i in range(length):
		arr.append(rng.randf_range(from, to))
	return arr


func randi_range_array(from: int, to: int, length: int) -> Array:
	var arr = []
	for i in range(length):
		arr.append(rng.randi_range(from, to))
	return arr


func mean(array: Array) -> float:
	return float(array_sum(array)) / float(len(array))


func variance(array: Array) -> float:
	var sum: float = 0.0
	var mean = mean(array)
	for a in array:
		sum += pow(a-mean, 2)
	return sum / (len(array)-1)


func std(array: Array) -> float:
	# Standard deviation
	return pow(variance(array), 0.5)


func add_signal(sig: String, props: Array = []) -> void:
	if !self.has_signal(sig):
		add_user_signal(sig, props)


func fade_in(node: Node, property: String, animation_time_ms: float) -> void:
	var tween_in = get_tree().create_tween()
	tween_in.tween_property(node, property, 1.0, animation_time_ms/1000.0)


func fade_out(node: Node, property: String, animation_time_ms: float) -> void:
	var tween_out = get_tree().create_tween()
	tween_out.tween_property(node, property, 0.0, animation_time_ms/1000.0)
