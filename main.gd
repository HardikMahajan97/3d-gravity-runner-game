extends Node3D

# Game state variables
var on_top_platform = false
var is_flipping = false
var flip_progress = 0.0
var game_speed = 2.0
var camera_x = 0.0
var game_over = false
var frame_counter = 0
var score = 0
var distance_traveled = 0.0

# Constants
const PLATFORM_HEIGHT = 3.0
const PLATFORM_WIDTH = 10.0
const MIN_GAP_SIZE = 8.0
const MAX_GAP_SIZE = 15.0
const MIN_PLATFORM_LENGTH = 20.0
const MAX_PLATFORM_LENGTH = 40.0
const WORLD_HEIGHT = 30.0
const PLAYER_SPEED_MULTIPLIER = 10.0

# Node references
var player: Node3D
var camera: Camera3D
var platforms: Array = []
var obstacles: Array = []
var platform_container: Node3D
var obstacle_container: Node3D
var background_objects: Node3D
var ui_canvas: CanvasLayer
var score_label: Label
var distance_label: Label
var speed_label: Label
var game_over_panel: Panel
var combo_label: Label

# Character animation references
var left_leg: Node3D
var right_leg: Node3D
var left_arm: Node3D
var right_arm: Node3D
var walk_cycle: float = 0.0
var clouds: Array = []

# Platform data structure
class PlatformData:
	var start_x: float
	var end_x: float
	var is_top: bool
	var mesh_instance: MeshInstance3D
	
	func _init(sx: float, ex: float, top: bool):
		start_x = sx
		end_x = ex
		is_top = top

# Obstacle data structure
class ObstacleData:
	var x: float
	var y: float
	var is_top: bool
	var mesh_instance: MeshInstance3D
	
	func _init(ox: float, oy: float, top: bool):
		x = ox
		y = oy
		is_top = top

func _ready():
	setup_scene()
	init_game()

func setup_scene():
	# Create camera
	camera = Camera3D.new()
	add_child(camera)
	camera.position = Vector3(8, 15, 35)
	camera.rotation_degrees = Vector3(-12, 0, 0)
	camera.fov = 65
	camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	
	# Create main directional light
	var sun = DirectionalLight3D.new()
	add_child(sun)
	sun.position = Vector3(10, 30, 10)
	sun.rotation_degrees = Vector3(-50, -30, 0)
	sun.light_energy = 1.2
	sun.light_color = Color(1.0, 0.95, 0.8)
	sun.shadow_enabled = true
	
	# Create fill light
	var fill_light = DirectionalLight3D.new()
	add_child(fill_light)
	fill_light.position = Vector3(-10, 20, -10)
	fill_light.rotation_degrees = Vector3(-30, 150, 0)
	fill_light.light_energy = 0.3
	fill_light.light_color = Color(0.7, 0.8, 1.0)
	
	# Enhanced environment with sky gradient
	var env = Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky = Sky.new()
	var sky_material = ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.15, 0.25, 0.5)
	sky_material.sky_horizon_color = Color(0.95, 0.6, 0.4)
	sky_material.ground_bottom_color = Color(0.25, 0.35, 0.3)
	sky_material.ground_horizon_color = Color(0.7, 0.5, 0.4)
	sky_material.sun_angle_max = 35.0
	sky_material.sun_curve = 0.15
	sky.sky_material = sky_material
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.7
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.ssao_enabled = true
	env.glow_enabled = true
	env.glow_intensity = 0.4
	env.glow_bloom = 0.3
	
	var world_env = WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)
	
	# Create humanoid player
	player = Node3D.new()
	add_child(player)
	
	# Torso
	var torso = MeshInstance3D.new()
	var torso_mesh = BoxMesh.new()
	torso_mesh.size = Vector3(0.8, 1.2, 0.4)
	torso.mesh = torso_mesh
	var torso_material = StandardMaterial3D.new()
	torso_material.albedo_color = Color(0.2, 0.5, 0.9)
	torso_material.metallic = 0.1
	torso_material.roughness = 0.8
	torso.material_override = torso_material
	player.add_child(torso)
	
	# Head
	var head = MeshInstance3D.new()
	var head_mesh = SphereMesh.new()
	head_mesh.radius = 0.35
	head_mesh.height = 0.7
	head.mesh = head_mesh
	var head_material = StandardMaterial3D.new()
	head_material.albedo_color = Color(1.0, 0.85, 0.7)
	head_material.roughness = 0.9
	head.material_override = head_material
	head.position = Vector3(0, 0.95, 0)
	player.add_child(head)
	
	# Eyes
	var left_eye = MeshInstance3D.new()
	var eye_mesh = SphereMesh.new()
	eye_mesh.radius = 0.08
	eye_mesh.height = 0.08
	eye_mesh.radial_segments = 8
	eye_mesh.rings = 4
	left_eye.mesh = eye_mesh
	var eye_material = StandardMaterial3D.new()
	eye_material.albedo_color = Color(0.1, 0.1, 0.1)
	eye_material.roughness = 0.9
	left_eye.material_override = eye_material
	left_eye.position = Vector3(-0.12, 1.0, 0.32)
	left_eye.scale = Vector3(1.0, 1.0, 0.5)
	player.add_child(left_eye)
	
	var right_eye = MeshInstance3D.new()
	var right_eye_mesh = SphereMesh.new()
	right_eye_mesh.radius = 0.08
	right_eye_mesh.height = 0.08
	right_eye_mesh.radial_segments = 8
	right_eye_mesh.rings = 4
	right_eye.mesh = right_eye_mesh
	right_eye.material_override = eye_material
	right_eye.position = Vector3(0.12, 1.0, 0.32)
	right_eye.scale = Vector3(1.0, 1.0, 0.5)
	player.add_child(right_eye)
	
	# Smile
	var mouth = MeshInstance3D.new()
	var mouth_mesh = TorusMesh.new()
	mouth_mesh.inner_radius = 0.08
	mouth_mesh.outer_radius = 0.12
	mouth.mesh = mouth_mesh
	var mouth_material = StandardMaterial3D.new()
	mouth_material.albedo_color = Color(0.0, 0.0, 0.0)
	mouth.material_override = mouth_material
	mouth.position = Vector3(0, 0.85, 0.28)
	mouth.rotation_degrees = Vector3(60, 0, 0)
	mouth.scale = Vector3(1.2, 0.5, 0.3)
	player.add_child(mouth)
	
	# Left Arm
	left_arm = Node3D.new()
	left_arm.position = Vector3(-0.5, 0.4, 0)
	player.add_child(left_arm)
	
	var left_upper_arm = MeshInstance3D.new()
	var arm_mesh = CylinderMesh.new()
	arm_mesh.top_radius = 0.12
	arm_mesh.bottom_radius = 0.1
	arm_mesh.height = 0.6
	left_upper_arm.mesh = arm_mesh
	var arm_material = StandardMaterial3D.new()
	arm_material.albedo_color = Color(1.0, 0.8, 0.65)
	left_upper_arm.material_override = arm_material
	left_upper_arm.position = Vector3(0, -0.3, 0)
	left_arm.add_child(left_upper_arm)
	
	# Right Arm
	right_arm = Node3D.new()
	right_arm.position = Vector3(0.5, 0.4, 0)
	player.add_child(right_arm)
	
	var right_upper_arm = MeshInstance3D.new()
	right_upper_arm.mesh = arm_mesh
	right_upper_arm.material_override = arm_material
	right_upper_arm.position = Vector3(0, -0.3, 0)
	right_arm.add_child(right_upper_arm)
	
	# Left Leg
	left_leg = Node3D.new()
	left_leg.position = Vector3(-0.25, -0.6, 0)
	player.add_child(left_leg)
	
	var left_thigh = MeshInstance3D.new()
	var leg_mesh = CylinderMesh.new()
	leg_mesh.top_radius = 0.15
	leg_mesh.bottom_radius = 0.12
	leg_mesh.height = 0.7
	left_thigh.mesh = leg_mesh
	var leg_material = StandardMaterial3D.new()
	leg_material.albedo_color = Color(0.3, 0.3, 0.4)
	left_thigh.material_override = leg_material
	left_thigh.position = Vector3(0, -0.35, 0)
	left_leg.add_child(left_thigh)
	
	var left_foot = MeshInstance3D.new()
	var foot_mesh = BoxMesh.new()
	foot_mesh.size = Vector3(0.2, 0.15, 0.35)
	left_foot.mesh = foot_mesh
	var foot_material = StandardMaterial3D.new()
	foot_material.albedo_color = Color(0.2, 0.2, 0.2)
	left_foot.material_override = foot_material
	left_foot.position = Vector3(0, -0.7, 0.08)
	left_leg.add_child(left_foot)
	
	# Right Leg
	right_leg = Node3D.new()
	right_leg.position = Vector3(0.25, -0.6, 0)
	player.add_child(right_leg)
	
	var right_thigh = MeshInstance3D.new()
	right_thigh.mesh = leg_mesh
	right_thigh.material_override = leg_material
	right_thigh.position = Vector3(0, -0.35, 0)
	right_leg.add_child(right_thigh)
	
	var right_foot = MeshInstance3D.new()
	right_foot.mesh = foot_mesh
	right_foot.material_override = foot_material
	right_foot.position = Vector3(0, -0.7, 0.08)
	right_leg.add_child(right_foot)
	
	# Create containers
	platform_container = Node3D.new()
	add_child(platform_container)
	
	obstacle_container = Node3D.new()
	add_child(obstacle_container)
	
	background_objects = Node3D.new()
	add_child(background_objects)
	
	create_background_elements()
	setup_ui()

func create_background_elements():
	# Add animated clouds
	for i in range(30):
		var cloud = create_cloud()
		cloud.position = Vector3(
			randf_range(-100, 1500),
			randf_range(15, 28),
			randf_range(-50, -20)
		)
		background_objects.add_child(cloud)
		clouds.append(cloud)
	
	# Add distant mountains
	for i in range(15):
		var mountain = MeshInstance3D.new()
		var mountain_mesh = BoxMesh.new()
		var width = randf_range(30, 80)
		var height = randf_range(15, 35)
		mountain_mesh.size = Vector3(width, height, 20)
		mountain.mesh = mountain_mesh
		
		var mountain_material = StandardMaterial3D.new()
		mountain_material.albedo_color = Color(0.3, 0.35, 0.45, 0.7)
		mountain_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mountain.material_override = mountain_material
		
		mountain.position = Vector3(
			randf_range(0, 1500),
			height / 2.0 - 5,
			randf_range(-80, -60)
		)
		background_objects.add_child(mountain)
	
	# Ground plane
	var ground = MeshInstance3D.new()
	var ground_mesh = PlaneMesh.new()
	ground_mesh.size = Vector2(2000, 100)
	ground.mesh = ground_mesh
	var ground_material = StandardMaterial3D.new()
	ground_material.albedo_color = Color(0.25, 0.4, 0.3)
	ground_material.roughness = 1.0
	ground.material_override = ground_material
	ground.position = Vector3(500, -15, 0)
	ground.rotation_degrees = Vector3(-90, 0, 0)
	background_objects.add_child(ground)
	
	# Flying birds
	for i in range(20):
		var bird = MeshInstance3D.new()
		var bird_mesh = BoxMesh.new()
		bird_mesh.size = Vector3(0.8, 0.2, 0.2)
		bird.mesh = bird_mesh
		var bird_material = StandardMaterial3D.new()
		bird_material.albedo_color = Color(0.1, 0.1, 0.1)
		bird.material_override = bird_material
		bird.position = Vector3(
			randf_range(0, 1000),
			randf_range(18, 25),
			randf_range(-40, -25)
		)
		background_objects.add_child(bird)

func create_cloud() -> Node3D:
	var cloud = Node3D.new()
	var num_puffs = randi() % 4 + 3
	for i in range(num_puffs):
		var puff = MeshInstance3D.new()
		var puff_mesh = SphereMesh.new()
		var size = randf_range(3, 6)
		puff_mesh.radius = size
		puff_mesh.height = size * 2
		puff.mesh = puff_mesh
		
		var cloud_material = StandardMaterial3D.new()
		cloud_material.albedo_color = Color(1.0, 1.0, 1.0, 0.85)
		cloud_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		cloud_material.roughness = 1.0
		puff.material_override = cloud_material
		
		puff.position = Vector3(
			randf_range(-5, 5),
			randf_range(-2, 2),
			randf_range(-2, 2)
		)
		cloud.add_child(puff)
	return cloud

func setup_ui():
	ui_canvas = CanvasLayer.new()
	add_child(ui_canvas)
	
	# Top HUD bar with gradient background
	var top_bar = Panel.new()
	ui_canvas.add_child(top_bar)
	top_bar.position = Vector2(0, 520)
	top_bar.size = Vector2(1200, 100)
	
	var bar_style = StyleBoxFlat.new()
	bar_style.bg_color = Color(0.05, 0.05, 0.1, 0.85)
	bar_style.border_width_bottom = 3
	bar_style.border_color = Color(0.4, 0.7, 1.0, 0.8)
	top_bar.add_theme_stylebox_override("panel", bar_style)
	
	# Score with icon
	var score_container = HBoxContainer.new()
	top_bar.add_child(score_container)
	score_container.position = Vector2(30, 20)
	
	var score_icon = Label.new()
	score_container.add_child(score_icon)
	score_icon.text = "⚡"
	score_icon.add_theme_font_size_override("font_size", 40)
	
	score_label = Label.new()
	score_container.add_child(score_label)
	score_label.text = "0"
	score_label.add_theme_font_size_override("font_size", 48)
	score_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	score_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0))
	score_label.add_theme_constant_override("outline_size", 8)
	
	# Distance with icon
	var dist_container = HBoxContainer.new()
	top_bar.add_child(dist_container)
	dist_container.position = Vector2(300, 20)
	
	var dist_icon = Label.new()
	dist_container.add_child(dist_icon)
	dist_icon.text = "📏"
	dist_icon.add_theme_font_size_override("font_size", 35)
	
	distance_label = Label.new()
	dist_container.add_child(distance_label)
	distance_label.text = "0m"
	distance_label.add_theme_font_size_override("font_size", 36)
	distance_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
	distance_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0))
	distance_label.add_theme_constant_override("outline_size", 6)
	
	# Speed with icon
	var speed_container = HBoxContainer.new()
	top_bar.add_child(speed_container)
	speed_container.position = Vector2(600, 20)
	
	var speed_icon = Label.new()
	speed_container.add_child(speed_icon)
	speed_icon.text = "🚀"
	speed_icon.add_theme_font_size_override("font_size", 35)
	
	speed_label = Label.new()
	speed_container.add_child(speed_label)
	speed_label.text = "2.0x"
	speed_label.add_theme_font_size_override("font_size", 36)
	speed_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.3))
	speed_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0))
	speed_label.add_theme_constant_override("outline_size", 6)
	
	# Combo multiplier
	combo_label = Label.new()
	ui_canvas.add_child(combo_label)
	combo_label.text = ""
	combo_label.position = Vector2(500, 150)
	combo_label.add_theme_font_size_override("font_size", 56)
	combo_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))
	combo_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0))
	combo_label.add_theme_constant_override("outline_size", 10)
	combo_label.modulate = Color(1, 1, 1, 0)
	
	# Controls panel
	var controls_panel = Panel.new()
	ui_canvas.add_child(controls_panel)
	controls_panel.position = Vector2(20, 550)
	controls_panel.size = Vector2(300, 100)
	
	var ctrl_style = StyleBoxFlat.new()
	ctrl_style.bg_color = Color(0.1, 0.1, 0.15, 0.7)
	ctrl_style.corner_radius_top_left = 15
	ctrl_style.corner_radius_top_right = 15
	ctrl_style.corner_radius_bottom_left = 15
	ctrl_style.corner_radius_bottom_right = 15
	ctrl_style.border_width_left = 2
	ctrl_style.border_width_right = 2
	ctrl_style.border_width_top = 2
	ctrl_style.border_width_bottom = 2
	ctrl_style.border_color = Color(0.4, 0.6, 1.0, 0.5)
	controls_panel.add_theme_stylebox_override("panel", ctrl_style)
	
	var controls_vbox = VBoxContainer.new()
	controls_panel.add_child(controls_vbox)
	controls_vbox.position = Vector2(15, 15)
	
	var ctrl_title = Label.new()
	controls_vbox.add_child(ctrl_title)
	ctrl_title.text = "CONTROLS"
	ctrl_title.add_theme_font_size_override("font_size", 20)
	ctrl_title.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	
	var ctrl_space = Label.new()
	controls_vbox.add_child(ctrl_space)
	ctrl_space.text = "[SPACE] Flip Gravity"
	ctrl_space.add_theme_font_size_override("font_size", 18)
	ctrl_space.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.9))
	
	var ctrl_r = Label.new()
	controls_vbox.add_child(ctrl_r)
	ctrl_r.text = "[R] Restart | [ESC] Quit"
	ctrl_r.add_theme_font_size_override("font_size", 16)
	ctrl_r.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 0.8))
	
	# Game Over Panel
	game_over_panel = Panel.new()
	ui_canvas.add_child(game_over_panel)
	game_over_panel.visible = false
	game_over_panel.position = Vector2(300, 150)
	game_over_panel.size = Vector2(600, 400)
	
	var go_style = StyleBoxFlat.new()
	go_style.bg_color = Color(0.08, 0.08, 0.12, 0.97)
	go_style.corner_radius_top_left = 25
	go_style.corner_radius_top_right = 25
	go_style.corner_radius_bottom_left = 25
	go_style.corner_radius_bottom_right = 25
	go_style.border_width_left = 5
	go_style.border_width_right = 5
	go_style.border_width_top = 5
	go_style.border_width_bottom = 5
	go_style.border_color = Color(1.0, 0.2, 0.2, 0.8)
	go_style.shadow_size = 20
	go_style.shadow_color = Color(0, 0, 0, 0.8)
	game_over_panel.add_theme_stylebox_override("panel", go_style)
	
	var go_vbox = VBoxContainer.new()
	game_over_panel.add_child(go_vbox)
	go_vbox.position = Vector2(50, 40)
	go_vbox.size = Vector2(500, 320)
	go_vbox.add_theme_constant_override("separation", 25)
	
	var go_title = Label.new()
	go_vbox.add_child(go_title)
	go_title.text = "⚠ GAME OVER ⚠"
	go_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	go_title.add_theme_font_size_override("font_size", 56)
	go_title.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
	go_title.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0))
	go_title.add_theme_constant_override("outline_size", 12)
	
	var go_score = Label.new()
	go_vbox.add_child(go_score)
	go_score.text = "⚡ Flips: 0"
	go_score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	go_score.add_theme_font_size_override("font_size", 40)
	go_score.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	go_score.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0))
	go_score.add_theme_constant_override("outline_size", 8)
	
	var go_distance = Label.new()
	go_vbox.add_child(go_distance)
	go_distance.text = "📏 Distance: 0m"
	go_distance.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	go_distance.add_theme_font_size_override("font_size", 36)
	go_distance.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
	go_distance.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0))
	go_distance.add_theme_constant_override("outline_size", 6)
	
	var separator = Panel.new()
	go_vbox.add_child(separator)
	separator.custom_minimum_size = Vector2(400, 3)
	var sep_style = StyleBoxFlat.new()
	sep_style.bg_color = Color(0.5, 0.5, 0.6, 0.5)
	separator.add_theme_stylebox_override("panel", sep_style)
	
	var go_restart = Label.new()
	go_vbox.add_child(go_restart)
	go_restart.text = "Press [R] to Restart"
	go_restart.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	go_restart.add_theme_font_size_override("font_size", 28)
	go_restart.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	go_restart.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0))
	go_restart.add_theme_constant_override("outline_size", 6)

func init_game():
	for plat in platforms:
		if plat.mesh_instance:
			plat.mesh_instance.queue_free()
	platforms.clear()
	
	for obs in obstacles:
		if obs.mesh_instance:
			obs.mesh_instance.queue_free()
	obstacles.clear()
	
	player.position = Vector3(10, PLATFORM_HEIGHT + 1.5, 0)
	player.rotation_degrees = Vector3(0, 0, 0)
	on_top_platform = false
	is_flipping = false
	flip_progress = 0.0
	camera_x = 0.0
	game_speed = 2.0
	frame_counter = 0
	score = 0
	distance_traveled = 0.0
	walk_cycle = 0.0
	game_over_panel.visible = false
	combo_label.modulate = Color(1, 1, 1, 0)
	
	generate_fair_platforms()

func generate_fair_platforms():
	var current_x = 0.0
	create_platform(current_x, current_x + 60, false)
	create_platform(current_x, current_x + 60, true)
	current_x += 60
	
	var current_player_side = false
	
	for i in range(100):
		var gap_size = randf_range(MIN_GAP_SIZE, MAX_GAP_SIZE)
		var platform_length = randf_range(MIN_PLATFORM_LENGTH, MAX_PLATFORM_LENGTH)
		var gap_start = current_x
		var gap_end = current_x + gap_size
		var opposite_side = !current_player_side
		
		create_platform(gap_start - 5, gap_end + 10, opposite_side)
		current_x = gap_end
		create_platform(current_x, current_x + platform_length, opposite_side)
		
		if i > 5 and platform_length > 25 and randf() < 0.5:
			var obstacle_x = current_x + platform_length * 0.5
			create_obstacle(obstacle_x, opposite_side)
			var safety_extension = obstacle_x + 15
			if not has_platform_coverage(obstacle_x - 10, safety_extension, current_player_side):
				create_platform(obstacle_x - 10, safety_extension, current_player_side)
		
		current_x += platform_length
		current_player_side = opposite_side
		if i == 90:
			i = 0

func has_platform_coverage(start_x: float, end_x: float, is_top: bool) -> bool:
	for plat in platforms:
		if plat.is_top == is_top:
			if plat.start_x <= start_x and plat.end_x >= end_x:
				return true
			if (plat.start_x <= end_x and plat.end_x >= start_x):
				return true
	return false

func create_platform(start_x: float, end_x: float, is_top: bool):
	for existing in platforms:
		if existing.is_top == is_top:
			if abs(existing.start_x - start_x) < 1.0 and abs(existing.end_x - end_x) < 1.0:
				return
	
	var plat_data = PlatformData.new(start_x, end_x, is_top)
	var mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	var length = end_x - start_x
	box_mesh.size = Vector3(length, PLATFORM_HEIGHT, PLATFORM_WIDTH)
	mesh_instance.mesh = box_mesh
	
	var material = StandardMaterial3D.new()
	if is_top:
		material.albedo_color = Color(0.5, 0.35, 0.25)
		material.metallic = 0.2
		material.roughness = 0.8
	else:
		material.albedo_color = Color(0.35, 0.25, 0.15)
		material.metallic = 0.2
		material.roughness = 0.9
	
	mesh_instance.material_override = material
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	
	var center_x = (start_x + end_x) / 2.0
	var y_pos = PLATFORM_HEIGHT / 2.0 if !is_top else WORLD_HEIGHT - PLATFORM_HEIGHT / 2.0
	mesh_instance.position = Vector3(center_x, y_pos, 0)
	
	platform_container.add_child(mesh_instance)
	plat_data.mesh_instance = mesh_instance
	platforms.append(plat_data)

func create_obstacle(x: float, is_top: bool):
	var obs_data = ObstacleData.new(x, 0, is_top)
	
	var mesh_instance = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.75
	sphere_mesh.height = 1.5
	mesh_instance.mesh = sphere_mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.2, 0.2)
	material.metallic = 0.4
	material.roughness = 0.3
	material.emission_enabled = true
	material.emission = Color(1.0, 0.0, 0.0)
	material.emission_energy = 2.0
	mesh_instance.material_override = material
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	
	var y_pos = PLATFORM_HEIGHT + 1.5 if !is_top else WORLD_HEIGHT - PLATFORM_HEIGHT - 1.5
	mesh_instance.position = Vector3(x, y_pos, 0)
	
	obstacle_container.add_child(mesh_instance)
	obs_data.mesh_instance = mesh_instance
	obs_data.y = y_pos
	obstacles.append(obs_data)

func _process(delta):
	if !game_over:
		update_game(delta)
		animate_character(delta)
		animate_background(delta)
	
	update_ui()

func animate_character(delta):
	if !is_flipping:
		# Walking animation
		walk_cycle += delta * game_speed * 5.0
		
		# Leg movement
		var leg_swing = sin(walk_cycle) * 25.0
		left_leg.rotation_degrees.x = leg_swing
		right_leg.rotation_degrees.x = -leg_swing
		
		# Arm movement (opposite to legs)
		var arm_swing = sin(walk_cycle) * 20.0
		left_arm.rotation_degrees.x = -arm_swing
		right_arm.rotation_degrees.x = arm_swing
		
		# Slight body bounce
		var bounce = abs(sin(walk_cycle * 2.0)) * 0.1
		player.position.y += bounce * 0.1

func animate_background(delta):
	# Move and animate clouds
	for cloud in clouds:
		cloud.position.x -= delta * game_speed * 2.0
		if cloud.position.x < camera_x - 100:
			cloud.position.x = camera_x + 1500
		cloud.rotate_y(delta * 0.2)

func update_game(delta):
	frame_counter += 1
	if frame_counter >= 600:
		game_speed += 0.5
		frame_counter = 0
		show_combo_text("SPEED UP!")
	
	if is_flipping:
		flip_progress += 0.15
		if flip_progress >= 1.0:
			flip_progress = 0.0
			is_flipping = false
			
			var target_y = WORLD_HEIGHT - PLATFORM_HEIGHT - 1.5 if on_top_platform else PLATFORM_HEIGHT + 1.5
			player.position.y = target_y
			
			if on_top_platform:
				player.rotation_degrees.z = 180
			else:
				player.rotation_degrees.z = 0
	
	if is_flipping:
		var start_y = PLATFORM_HEIGHT + 1.5 if !on_top_platform else WORLD_HEIGHT - PLATFORM_HEIGHT - 1.5
		var target_y = WORLD_HEIGHT - PLATFORM_HEIGHT - 1.5 if on_top_platform else PLATFORM_HEIGHT + 1.5
		player.position.y = lerp(start_y, target_y, flip_progress)
		
		var target_rotation = 180.0 if on_top_platform else 0.0
		var start_rotation = 0.0 if on_top_platform else 180.0
		player.rotation_degrees.z = lerp(start_rotation, target_rotation, flip_progress)
	
	var movement = game_speed * delta * PLAYER_SPEED_MULTIPLIER
	player.position.x += movement
	distance_traveled += movement
	
	camera_x = player.position.x - 10
	camera.position.x = camera_x
	camera.position.y = 15
	
	if check_collisions() or !check_platform_collision():
		game_over = true
		game_over_panel.visible = true
		var go_vbox = game_over_panel.get_child(0)
		var final_score = go_vbox.get_child(1)
		var final_distance = go_vbox.get_child(2)
		final_score.text = "⚡ Flips: %d" % score
		final_distance.text = "📏 Distance: %dm" % int(distance_traveled)

func show_combo_text(text: String):
	combo_label.text = text
	combo_label.modulate = Color(1, 1, 1, 1)
	await get_tree().create_timer(1.0).timeout
	combo_label.modulate = Color(1, 1, 1, 0)

func check_collisions() -> bool:
	var player_pos = player.position
	for obs in obstacles:
		if obs.is_top == on_top_platform:
			var distance = player_pos.distance_to(obs.mesh_instance.position)
			if distance < 2.0:
				return true
	return false

func check_platform_collision() -> bool:
	var player_x = player.position.x
	for plat in platforms:
		if plat.is_top == on_top_platform:
			if player_x >= plat.start_x - 2 and player_x <= plat.end_x + 2:
				return true
	return false

func update_ui():
	if !game_over:
		score_label.text = "%d" % score
		distance_label.text = "%dm" % int(distance_traveled)
		speed_label.text = "%.1fx" % game_speed
		
		# Fade combo label
		if combo_label.modulate.a > 0:
			combo_label.modulate.a -= 0.02

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE and !game_over and !is_flipping:
			on_top_platform = !on_top_platform
			is_flipping = true
			flip_progress = 0.0
			score += 1
			show_combo_text("FLIP!")
		
		elif event.keycode == KEY_R and game_over:
			game_over = false
			init_game()
		
		elif event.keycode == KEY_ESCAPE:
			get_tree().quit()
