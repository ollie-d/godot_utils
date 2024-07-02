extends Node
# test3
signal physics_timer_completed(name)

var original_win_size

# Dict to store physics timers
var physics_timers = {}

var rng


func _ready():
	# Set up RNG
	randomize()
	rng = RandomNumberGenerator.new()
	rng.randomize()
	print("Random Number: ", rng.randf_range(0.0, 1.0))


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
func load_text(filename):
	return FileAccess.open(filename, FileAccess.READ).get_as_text()


# Function to parse 2D CSVs and return 2D Array
func load_csv_to_array(filename):
	var return_data = []
	var raw_data = FileAccess.open(filename, FileAccess.READ)
	while !raw_data.eof_reached():
		return_data.append(raw_data.get_csv_line())
	return return_data


func pix_to_font_size(pix):
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


func _physics_process(delta):
	# The clock of physics_process should be set in `Params`
	if physics_timers.size() > 0:
		for key in physics_timers.keys():
			physics_timers[key] -= 1
			if physics_timers[key] <= 0:
				emit_signal("physics_timer_completed", key)
				physics_timers.erase(key)


func physics_wait(timer_name: String, frame_delay: int):
	# Wait for a certain number of frames using `_physics_process()`
	#TODO: Re-write this using Engine.get_physics_frames()?
	physics_timers[timer_name] = frame_delay
	await self.physics_timer_completed == timer_name
	pass


func log_x(input, base):
	return log(input) / log(base)


func R_A(f):
	# f is freq, this formula is from wikipedia
	# https://en.wikipedia.org/wiki/A-weighting
	# Note: the sqrt does not encapsulate the final addition
	var numerator = pow(12194, 2) * pow(f, 4)
	var denominator = ((pow(f, 2) + pow(20.6, 2)) + 
	sqrt((pow(f, 2) + pow(107.7, 2)) * (pow(f, 2) + pow(737.9, 2))) * 
	(pow(f, 2) + pow(12194, 2)))
	return numerator / denominator


func A_weight(f):
	# f is freq, this formula is from wikipedia
	# https://en.wikipedia.org/wiki/A-weighting
	return (20*log_x(R_A(f), 10)) - (20*log_x(R_A(1000), 10))


func free_application():
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	get_tree().quit()


func arrays_equal(arr1: Array, arr2: Array, err=0.001) -> bool:
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


func array_sum(array: Array):
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
