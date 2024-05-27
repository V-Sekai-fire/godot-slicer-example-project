@tool

extends RigidBody3D

class_name Sliceable

@export var cross_section_material: Material
@export var mesh_override: Mesh
@export var slicer_node: Slicer
@export var mesh_instance_node: MeshInstance3D

func _ready():
	if mesh_override:
		mesh_instance_node.mesh = mesh_override
	# Setup the collision shape to be the mesh's shape
	var shape = ConvexPolygonShape3D.new()
	shape.points = mesh_instance_node.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	shape.margin = 0.015
	var owner_id = self.create_shape_owner(self)
	self.shape_owner_add_shape(owner_id, shape)

func setup(mesh: Mesh, position: Transform3D):
	mesh_instance_node.mesh = mesh
	self.transform = position

func cut_plane(plane: Plane):
	var sliced: SlicedMesh = slicer_node.slice_by_plane(mesh_instance_node.mesh, plane, cross_section_material)
	sliced.lower

func cut(origin: Vector3, normal: Vector3):
	return slicer_node.slice(mesh_instance_node.mesh, self.transform, origin, normal, cross_section_material)
