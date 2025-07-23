extends Node3D

var Layered := []
var SyncCams := []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var main : SubViewport = get_node("MainViewport")
	var mask : SubViewport = get_node("MaskedViewport")
	var win : Viewport = self.get_viewport()
	main.size = win.get_texture().get_size()
	mask.size = win.get_texture().get_size()
	SyncCams.push_back(mask.get_camera_3d())
	SyncCams.push_back(main.get_camera_3d())

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var mainTex : Texture2D = get_node("MainViewport").get_texture()
	var maskTex : Texture2D = get_node("MaskedViewport").get_texture()
	var rect := get_node("CanvasLayer/ColorRect") as ColorRect

	rect.material.set_shader_parameter("main", mainTex)
	rect.material.set_shader_parameter("mask", maskTex)
	
	# Only hide floors above the current look offset
	var min_y = SyncCams[0].get_parent().global_transform.origin.y
	
	var area : Area3D = $MainViewport/LookAt/Camera3D/Area3D
	var cols = area.get_overlapping_bodies()
	var new_layered := []
	for c in cols:
		var m = c.get_parent()
		if m is MeshInstance3D and m.global_transform.origin.y > min_y:
			m.layers = 2
			new_layered.push_back(m)

	for m in Layered:
		if not m in new_layered:
			m.layers = 1
			
	Layered = new_layered

# Having trouble properly catching inputs inside a SubViewport
# So handle it somewhere else. Whatever.
func _input(event: InputEvent) -> void:
	var zoom : float = 0.0
	var floor_change : int = 0
	if event.is_action("zoom_in"):
		zoom -= 1.0
	if event.is_action("zoom_out"):
		zoom += 1.0
	if event.is_action_released("down_floor"):
		floor_change -= 1
	if event.is_action_released("up_floor"):
		floor_change += 1

	if abs(floor_change) > 0:
		var refCam : Camera3D= SyncCams[0]
		var cur_floor : float = refCam.get_parent().global_transform.origin.y / Globals.FLOOR_HEIGHT
		var new_floor : float = cur_floor + floor_change
		# For now, arbitrarily max 6 floors
		new_floor = clamp(new_floor, 0.0, 6 * Globals.FLOOR_HEIGHT)
		if new_floor != cur_floor:
			var offset = (new_floor - cur_floor) * Globals.FLOOR_HEIGHT
			print("cur_floor: %.3f, new_floor: %.3f, offset: %.3f" % [cur_floor, new_floor, offset])
			
			for c in SyncCams:
				var new_look_transform = c.get_parent().global_transform
				new_look_transform.origin.y += offset
				c.get_parent().global_transform = new_look_transform
				c.look_at(new_look_transform.origin)
		
	var zoom_speed : float = SyncCams[0].ZoomSpeed
		
	if abs(zoom) > 0.001:
		var look_y = SyncCams[0].get_parent().global_transform.origin.y
		var new_y = SyncCams[0].global_transform.origin.y + (zoom * zoom_speed)
		new_y = clamp(new_y, look_y + 0.2, look_y + 28.0)
		for c in SyncCams:
			c.global_transform.origin.y = new_y
			c.look_at(c.get_parent().global_transform.origin)
