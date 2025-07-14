extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var mainTex : Texture2D = get_node("MainViewport").get_texture()
	var maskTex : Texture2D = get_node("MaskedViewport").get_texture()
	var rect := get_node("CanvasLayer/ColorRect") as ColorRect

	rect.material.set_shader_parameter("main", mainTex)
	rect.material.set_shader_parameter("mask", maskTex)
