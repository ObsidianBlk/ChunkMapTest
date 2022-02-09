extends TileMap
tool
class_name ChunkEditor

# -------------------------------------------------------------------------
# Constants
# -------------------------------------------------------------------------

const CHUNK_SIZE : Vector2 = Vector2(32,32)

# -------------------------------------------------------------------------
# Export Variables
# -------------------------------------------------------------------------
export (String, DIR) var chunk_path : String = ""
export (int, 1, 10) var chunk_distance : int = 4			setget set_chunk_distance

# -------------------------------------------------------------------------
# Variables
# -------------------------------------------------------------------------
var _chunks : Dictionary = {}
var _active_chunk_pos : Vector2 = Vector2.ZERO
var _ignore_chunk_set : bool = false

# -------------------------------------------------------------------------
# Onready Variables
# -------------------------------------------------------------------------


# -------------------------------------------------------------------------
# Setters / Getters
# -------------------------------------------------------------------------

func set_chunk_distance(cd : int) -> void:
	if cd > 0:
		chunk_distance = cd
		_UnloadOutsideChunks(_active_chunk_pos)
		_LoadInsideChunks(_active_chunk_pos)

# -------------------------------------------------------------------------
# Override Methods
# -------------------------------------------------------------------------
func _ready() -> void:
	_LoadInsideChunks(_active_chunk_pos)

func _draw() -> void:
	print("Updating")
	for pos in _chunks.keys():
		print("Chunk: ", _chunks[pos].node, " | Cell Count: ", _chunks[pos].node.get_used_cells().size())
	var chunk_size : Vector2 = CHUNK_SIZE * cell_size 
	var r : Rect2 = Rect2(_active_chunk_pos * chunk_size, chunk_size)
	draw_rect(r, Color(0.0, 0.4, 1.0), false, 3)


# -------------------------------------------------------------------------
# Plugin Methods
# -------------------------------------------------------------------------
func _tool_unhandled_input(event) -> bool:
	if event is InputEventMouseMotion:
		var mpos : Vector2 = get_viewport().get_mouse_position()
		var chunk_size = CHUNK_SIZE * cell_size
		var chunk_pos = (mpos / chunk_size).floor()
#		)
		if chunk_pos != _active_chunk_pos:
			if _active_chunk_pos in _chunks:
				print("Clearing")
				_ClearChunkArea(_active_chunk_pos)
				#.clear()
			if chunk_pos in _chunks:
				_CopyChunkToEditor(chunk_pos)
			_active_chunk_pos = chunk_pos
			#_UnloadOutsideChunks(_active_chunk_pos)
			#_LoadInsideChunks(_active_chunk_pos)
			#update()
	elif event is InputEventMouseButton:
		if not event.pressed:
			for pos in _chunks.keys():
				print("Chunk: ", _chunks[pos].node, " | Cell Count: ", _chunks[pos].node.get_used_cells().size())
	return false
	
# -------------------------------------------------------------------------
# Private Methods
# -------------------------------------------------------------------------
func _GetChunkNameFromPos(chunk_pos : Vector2) -> String:
	return "Chunk_" + String(chunk_pos.x) + "x" + String(chunk_pos.y)

func _StoreChunkNode(chunk_pos : Vector2, node : TileMap) -> void:
	if not chunk_pos in _chunks:
		_chunks[chunk_pos] = {
			"node": node,
			"dirty": false
		}

func _IsChunkLoaded(chunk_name : String) -> bool:
	for child in get_children():
		if child is TileMap and child.name == chunk_name:
			return true
	return false

func _UnloadOutsideChunks(chunk_pos : Vector2) -> void:
	var xmin = chunk_pos.x - chunk_distance
	var xmax = chunk_pos.x + chunk_distance
	var ymin = chunk_pos.y - chunk_distance
	var ymax = chunk_pos.y + chunk_distance
	
	for cpos in _chunks.keys():
		if not (cpos.x >= xmin and cpos.x <= xmax and cpos.y >= ymin and cpos.y <= ymax):
			if _chunks[cpos].dirty == true:
				return # Don't unload dirty chunks
			
			var tm = _chunks[cpos].node
			remove_child(tm)
			tm.queue_free()
			_chunks.erase(cpos)

func _LoadInsideChunks(chunk_pos : Vector2) -> void:
	if chunk_path == "":
		return # Without a base path to check, there's nothing to load.
	
	var xmin = chunk_pos.x - chunk_distance
	var xmax = chunk_pos.x + chunk_distance
	var ymin = chunk_pos.y - chunk_distance
	var ymax = chunk_pos.y + chunk_distance
	
	for y in range(ymin, ymax+1):
		for x in range(xmin, xmax+1):
			var cpos : Vector2 = Vector2(x, y)
			if not cpos in _chunks:
				var tm : TileMap = _LoadChunkAtPosition(cpos)
				if tm != null:
					_StoreChunkNode(cpos, tm)
					add_child(tm)
					tm.modulate = Color(1,1,1,0.5)

func _LoadChunkAtPosition(chunk_pos : Vector2) -> TileMap:
	if chunk_path == "":
		return null # Without a base path to check, there's nothing to load.
	
	var chunk_name = _GetChunkNameFromPos(chunk_pos)
	var filename = chunk_path + "/" + chunk_name + ".tscn"
	
	var dir : Directory = Directory.new()
	if dir.file_exists(filename):
		var scene = load(filename)
		if scene:
			var tm = scene.instance()
			if tm is TileMap:
				return tm
	return null

func _CreateChunkAtPosition(chunk_pos : Vector2) -> TileMap:
	if chunk_pos in _chunks:
		return null
	
	var tm : TileMap = TileMap.new()
	tm.tile_set = tile_set
	tm.cell_size = cell_size
	tm.name = _GetChunkNameFromPos(chunk_pos)
	return tm


func _SaveDirtyChunks() -> void:
	if chunk_path == "":
		return # No base path, then nothing to do.
	
	for chunk_pos in _chunks.keys():
		if _chunks[chunk_pos].dirty:
			var packed : PackedScene = PackedScene.new()
			_chunks[chunk_pos].node.modulate = Color(1,1,1,1)
			packed.pack(_chunks[chunk_pos].node)
			var filepath : String = chunk_path + "/" + _GetChunkNameFromPos(chunk_pos) + ".tscn"
			ResourceSaver.save(filepath, packed)
			print("Saved chunk : ", filepath)
			_chunks[chunk_pos].node.modulate = Color(1,1,1,0.5)
			_chunks[chunk_pos].dirty = false


func _ClearChunkArea(chunk_pos : Vector2) -> void:
	var cpos_x : float = chunk_pos.x * CHUNK_SIZE.x
	var cpos_y : float = chunk_pos.y * CHUNK_SIZE.y
	_ignore_chunk_set = true
	for y in range(cpos_y, cpos_y + CHUNK_SIZE.y):
		for x in range(cpos_x, cpos_x + CHUNK_SIZE.x):
			.set_cell(x, y, -1)
	_ignore_chunk_set = false


func _CopyChunkToEditor(chunk_pos : Vector2) -> void:
	print("Attempting to copy chunk at: ", chunk_pos)
	if chunk_pos in _chunks:
		var tm : TileMap = _chunks[chunk_pos].node
		var cells = tm.get_used_cells()
		print("Cell count: ", cells.size())
		for cell in cells:
			var id = tm.get_cell(cell.x, cell.y)
			if id != INVALID_CELL:
				var autotile_coord = tm.get_cell_autotile_coord(cell.x, cell.y)
				var transpose = tm.is_cell_transposed(cell.x, cell.y)
				var flip_x = tm.is_cell_x_flipped(cell.x, cell.y)
				var flip_y = tm.is_cell_y_flipped(cell.x, cell.y)
				.set_cell(cell.x, cell.y, id, flip_x, flip_y, transpose, autotile_coord)

# -------------------------------------------------------------------------
# Public Methods
# -------------------------------------------------------------------------
func set_cell(x : int, y : int, tile : int, flip_x : bool = false, flip_y : bool = false, transpose : bool = false, autotile_coord : Vector2 = Vector2(0, 0)) -> void:
	if not _ignore_chunk_set:
		var cpos : Vector2 = (Vector2(x, y) / CHUNK_SIZE).floor()
		if not cpos in _chunks:
			#print("Creating chunk at position: ", cpos)
			var tm : TileMap = _CreateChunkAtPosition(cpos)
			if not tm:
				print("Failed to create new chunk")
				return
			_StoreChunkNode(cpos, tm)
			add_child(tm)
		
		if cpos in _chunks:
			#print("Setting Chunk Tile: ", cpos)
			_chunks[cpos].node.set_cell(x, y, tile, flip_x, flip_y, transpose, autotile_coord)
			_chunks[cpos].node.modulate = Color(1,1,1,0.75)
			_chunks[cpos].dirty = true
	.set_cell(x, y, tile, flip_x, flip_y, transpose, autotile_coord)

# -------------------------------------------------------------------------
# Handler Methods
# -------------------------------------------------------------------------
