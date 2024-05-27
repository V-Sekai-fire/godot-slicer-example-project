extends CharacterBody3D

var move_axis = Vector2()
var in_cut_mode = false

var SliceableScene = preload("res://Sliceable.tscn")

@export var mouse_sensitivity = 10.0
@export var speed = 10
@export var acceleration = 8
@export var deacceleration = 10
@export var normal_fov = 75
@export var cut_mode_fov = 50

func _ready():
	$Camera3D.fov = self.normal_fov
	
func _process(_delta: float) -> void:
	if Input.is_action_pressed("player_cut_mode"):
		if not self.in_cut_mode:
			self.in_cut_mode = true

			var plane_material: StandardMaterial3D = $Camera3D/Plane.get_surface_override_material(0)
			var new_color = plane_material.albedo_color
			new_color.a = .1
			var fov_tween = get_tree().create_tween()
			fov_tween.set_ease(Tween.EASE_IN_OUT)
			fov_tween.set_trans(Tween.TRANS_LINEAR)
			fov_tween.tween_property($Camera3D, "fov", cut_mode_fov, .1)
			var color_tween = get_tree().create_tween()
			color_tween.set_ease(Tween.EASE_IN_OUT)
			color_tween.set_trans(Tween.TRANS_LINEAR)
			color_tween.tween_property(plane_material, "albedo_color", new_color, .1)
			
	elif self.in_cut_mode:
		self.in_cut_mode = false
		var plane_material = $Camera3D/Plane.get_surface_override_material(0)		
		var new_color = plane_material.albedo_color
		new_color.a = 0
		var fov_tween = get_tree().create_tween()
		fov_tween.set_ease(Tween.EASE_IN_OUT)
		fov_tween.set_trans(Tween.TRANS_LINEAR)
		fov_tween.tween_property($Camera3D, "fov", normal_fov, .1)
		var color_tween = get_tree().create_tween()
		color_tween.set_ease(Tween.EASE_IN_OUT)
		color_tween.set_trans(Tween.TRANS_LINEAR)
		color_tween.tween_property(plane_material, "albedo_color", new_color, .1)

	self.move_axis.x = Input.get_action_strength("player_forward") - Input.get_action_strength("player_backward")
	self.move_axis.y = Input.get_action_strength("player_right") - Input.get_action_strength("player_left")

func _physics_process(delta: float) -> void:
	var direction = Vector3()
	var aim: Basis = get_global_transform().basis
	if move_axis.x >= 0.5:
		direction -= aim.z
	if move_axis.x <= -0.5:
		direction += aim.z
	if move_axis.y <= -0.5:
		direction -= aim.x
	if move_axis.y >= 0.5:
		direction += aim.x

	direction = direction.normalized()

	var target: Vector3 = direction * speed
	var temp_accel: float
	if direction.dot(velocity) > 0:
		temp_accel = acceleration
	else:
		temp_accel = deacceleration

	velocity = velocity.lerp(target, temp_accel * delta)

	set_velocity(velocity)
	set_up_direction(Vector3(0, 1, 0))
	move_and_slide()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_camera(event.relative)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed and self.in_cut_mode:
			cut()

func rotate_camera(mouse_axis: Vector2) -> void:
	if mouse_axis.length() > 0:
		var smoothness := 60

		if not self.in_cut_mode:
			var horizontal: float = -(mouse_axis.x * mouse_sensitivity) / smoothness
			rotate_y(deg_to_rad(horizontal))
		else:
			$Camera3D/Plane.transform = $Camera3D/Plane.transform.rotated(Vector3(0, 0, 1), -(mouse_axis.x) / smoothness * .2)

		var vertical: float = -(mouse_axis.y * mouse_sensitivity) / smoothness
		$Camera3D.rotate_x(deg_to_rad(vertical))

func cut():
	var plane_transform = $Camera3D/Plane.global_transform
	for body in $Camera3D/Plane/CutArea.get_overlapping_bodies():
		if body is Sliceable:
			var origin = plane_transform.origin - body.transform.origin
			var normal = (plane_transform.basis.y) * body.transform.basis
			var dist = plane_transform.basis.y.dot(origin)
			var plane = Plane(normal, dist)
#			var sliced_mesh = body.cut_plane(plane)
			var sliced_mesh = body.cut(plane_transform.origin, plane_transform.basis.y)
			if not sliced_mesh:
				continue

			if sliced_mesh.upper_mesh:
				var upper = SliceableScene.instantiate()
				upper.setup(sliced_mesh.upper_mesh, body.transform)
				upper.cross_section_material = body.cross_section_material
				self.get_parent().add_child(upper)
#
			if sliced_mesh.lower_mesh:
				var lower = SliceableScene.instantiate()
				lower.setup(sliced_mesh.lower_mesh, body.transform)
				lower.cross_section_material = body.cross_section_material
				self.get_parent().add_child(lower)

			body.queue_free()
