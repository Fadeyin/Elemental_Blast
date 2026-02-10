extends MeshInstance3D

# Процедурное дерево для фона
func _ready():
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = _create_tree_mesh()
	mesh_instance.material_override = _create_tree_material()
	add_child(mesh_instance)

func _create_tree_mesh() -> ArrayMesh:
	var arr_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	
	# Ствол (цилиндр)
	var trunk_vertices = PackedVector3Array()
	var trunk_normals = PackedVector3Array()
	var trunk_indices = PackedInt32Array()
	
	var trunk_height = 2.0
	var trunk_radius = 0.15
	var segments = 8
	
	# Вершины ствола
	for i in range(segments + 1):
		var angle = (float(i) / float(segments)) * TAU
		var x = cos(angle) * trunk_radius
		var z = sin(angle) * trunk_radius
		trunk_vertices.append(Vector3(x, 0, z))
		trunk_vertices.append(Vector3(x, trunk_height, z))
		trunk_normals.append(Vector3(x / trunk_radius, 0, z / trunk_radius))
		trunk_normals.append(Vector3(x / trunk_radius, 0, z / trunk_radius))
	
	# Индексы ствола
	for i in range(segments):
		var base = i * 2
		trunk_indices.append(base)
		trunk_indices.append(base + 1)
		trunk_indices.append((base + 2) % (segments * 2))
		trunk_indices.append(base + 1)
		trunk_indices.append((base + 3) % (segments * 2))
		trunk_indices.append((base + 2) % (segments * 2))
	
	# Крона (конус)
	var crown_vertices = PackedVector3Array()
	var crown_normals = PackedVector3Array()
	var crown_indices = PackedInt32Array()
	
	var crown_height = 1.5
	var crown_radius = 1.2
	var crown_top = trunk_height + crown_height
	
	# Вершина кроны
	crown_vertices.append(Vector3(0, crown_top, 0))
	crown_normals.append(Vector3(0, 1, 0))
	
	# Основание кроны
	for i in range(segments + 1):
		var angle = (float(i) / float(segments)) * TAU
		var x = cos(angle) * crown_radius
		var z = sin(angle) * crown_radius
		crown_vertices.append(Vector3(x, trunk_height, z))
		var normal = Vector3(x, 0.3, z).normalized()
		crown_normals.append(normal)
	
	# Индексы кроны
	for i in range(segments):
		crown_indices.append(0) # Вершина
		crown_indices.append(i + 1)
		crown_indices.append((i + 2) % (segments + 1) + 1)
	
	# Объединяем все в один меш
	var all_vertices = trunk_vertices
	all_vertices.append_array(crown_vertices)
	
	var all_normals = trunk_normals
	all_normals.append_array(crown_normals)
	
	var all_indices = trunk_indices
	var crown_offset = trunk_vertices.size()
	for idx in crown_indices:
		all_indices.append(idx + crown_offset)
	
	arrays[Mesh.ARRAY_VERTEX] = all_vertices
	arrays[Mesh.ARRAY_NORMAL] = all_normals
	arrays[Mesh.ARRAY_INDEX] = all_indices
	
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return arr_mesh

func _create_tree_material() -> StandardMaterial3D:
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.3, 0.6, 0.2) # Зеленый для кроны
	material.roughness = 0.8
	material.metallic = 0.0
	return material


