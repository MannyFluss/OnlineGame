extends Node2D
class_name TempCanvas

var thingy :Vector2 = Vector2(100,100)
var enabled = false

func _draw() -> void:
	if enabled:
		draw_circle(thingy,50,Color.RED)
	
func _process(_delta: float) -> void:
	if enabled:
		queue_redraw()
		thingy += Vector2(randf_range(-10,10),0)
	
