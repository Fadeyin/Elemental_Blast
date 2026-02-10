extends Node3D

# Генератор 3D деревьев для фона
const TREE_COUNT := 12
const SPREAD_X := 20.0
const SPREAD_Z := 15.0
const DEPTH_OFFSET := -5.0

func _ready():
	_generate_trees()

func _generate_trees():
	for i in range(TREE_COUNT):
		var tree = _create_simple_tree()
		var x = randf_range(-SPREAD_X, SPREAD_X)
		var z = randf_range(DEPTH_OFFSET - SPREAD_Z, DEPTH_OFFSET + SPREAD_Z)
		var y = 0.0
		tree.position = Vector3(x, y, z)
		tree.rotation_degrees.y = randf_range(0, 360)
		tree.scale = Vector3.ONE * randf_range(0.8, 1.2)
		$Trees.add_child(tree)

func _create_simple_tree() -> Node3D:
	var tree_node = Node3D.new()
	
	# Ствол
	var trunk = _create_cylinder(0.15, 2.0, Color(0.4, 0.25, 0.15))
	trunk.position.y = 1.0
	tree_node.add_child(trunk)
	
	# Крона (несколько сфер для объема)
	for i in range(3):
		var crown = _create_sphere(1.0 - i * 0.2, Color(0.2, 0.5, 0.15))
		crown.position = Vector3(0, 2.5 + i * 0.8, 0)
		crown.scale = Vector3(1.0 - i * 0.15, 1.0, 1.0 - i * 0.15)
		tree_node.add_child(crown)
	
	return tree_node

func _create_cylinder(radius: float, height: float, color: Color) -> MeshInstance3D:
	var mesh_instance = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = height
	cylinder.radial_segments = 8
	mesh_instance.mesh = cylinder
	
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	mesh_instance.material_override = material
	
	return mesh_instance

func _create_sphere(radius: float, color: Color) -> MeshInstance3D:
	var mesh_instance = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2
	sphere.radial_segments = 12
	sphere.rings = 8
	mesh_instance.mesh = sphere
	
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.8
	material.metallic = 0.0
	mesh_instance.material_override = material
	
	return mesh_instance
