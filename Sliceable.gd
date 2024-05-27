@tool

extends RigidBody3D

class_name Sliceable

@export var cross_section_material: Material
@export var mesh_override: Mesh
@export var start_static = false

func _ready():
	if mesh_override:
		$MeshInstance3D.mesh = mesh_override
	# Setup the collision shape to be the mesh's shape
	var shape = ConvexPolygonShape3D.new()
	shape.points = $MeshInstance3D.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	shape.margin = 0.015
	var owner_id = self.create_shape_owner(self)
	self.shape_owner_add_shape(owner_id, shape)
	if start_static:
		self.mode = RigidBody3D.FREEZE_MODE_STATIC

func setup(mesh: Mesh, position: Transform3D):
	$MeshInstance3D.mesh = mesh
	self.transform = position
	self.mode = RigidBody3D.MODE_RIGID

func cut_plane(plane: Plane):
	var sliced: SlicedMesh = $Slicer.slice_by_plane($MeshInstance3D.mesh, plane, cross_section_material)
	sliced.lower

func cut(origin: Vector3, normal: Vector3):
	return $Slicer.slice($MeshInstance3D.mesh, self.transform, origin, normal, cross_section_material)
