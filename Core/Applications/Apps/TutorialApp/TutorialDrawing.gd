@tool
extends Node2D
class_name TutorialDrawing

# Face expression
@export var current_face : String = "neutral":
	set(value):
		current_face = value
		queue_redraw()

# Fallback sizing (used when parent has no size)
@export_group("Fallback Sizing")
@export var fallback_size := Vector2(200, 200):
	set(value):
		fallback_size = value
		queue_redraw()
@export var fallback_center := Vector2(100, 100):
	set(value):
		fallback_center = value
		queue_redraw()
@export var fallback_face_size := 80.0:
	set(value):
		fallback_face_size = value
		queue_redraw()

# Face sizing (as ratio of parent's smaller dimension)
@export_group("Face Sizing")
@export_range(0.1, 1.0, 0.05) var face_size_ratio := 0.4:
	set(value):
		face_size_ratio = value
		queue_redraw()

# Eye positioning (as ratio of face_size)
@export_group("Eye Settings")
@export_range(0.0, 1.0, 0.05) var eye_offset_x_ratio := 0.35:
	set(value):
		eye_offset_x_ratio = value
		queue_redraw()
@export_range(0.0, 1.0, 0.05) var eye_offset_y_ratio := 0.25:
	set(value):
		eye_offset_y_ratio = value
		queue_redraw()
@export_range(0.0, 1.0, 0.05) var eye_radius_ratio := 0.15:
	set(value):
		eye_radius_ratio = value
		queue_redraw()
@export_range(1.0, 3.0, 0.1) var eye_surprised_scale := 1.3:
	set(value):
		eye_surprised_scale = value
		queue_redraw()

# Mouth positioning (as ratio of face_size)
@export_group("Mouth Settings")
@export_range(0.0, 1.0, 0.05) var mouth_radius_ratio := 0.4:
	set(value):
		mouth_radius_ratio = value
		queue_redraw()
@export_range(0.0, 1.0, 0.05) var mouth_offset_y_ratio := 0.2:
	set(value):
		mouth_offset_y_ratio = value
		queue_redraw()
@export_range(0.0, 1.0, 0.05) var mouth_smile_extra_offset := 0.5:
	set(value):
		mouth_smile_extra_offset = value
		queue_redraw()

# Drawing parameters
@export_group("Drawing")
@export_range(1.0, 50.0, 1.0) var line_width := 100.0:
	set(value):
		line_width = value
		queue_redraw()
@export_range(10, 100, 5) var arc_point_count := 50:
	set(value):
		arc_point_count = value
		queue_redraw()

# Colors
@export_group("Colors")
@export var color_angry := Color.RED:
	set(value):
		color_angry = value
		queue_redraw()
@export var color_default := Color.GREEN:
	set(value):
		color_default = value
		queue_redraw()


func _get_center_and_size() -> Dictionary:
	var parent = get_parent()
	if parent is Control:
		var size = parent.size
		if size.x <= 0 or size.y <= 0:
			size = fallback_size
		var center = size / 2.0
		var face_size = min(size.x, size.y) * face_size_ratio
		return {"center": center, "size": face_size}
	push_error("Parent is not Control, using fallback")
	return {"center": fallback_center, "size": fallback_face_size}

func _draw() -> void:
	var data = _get_center_and_size()
	var center : Vector2 = data["center"]
	var face_size : float = data["size"]

	var eye_offset_x := face_size * eye_offset_x_ratio
	var eye_offset_y := face_size * eye_offset_y_ratio
	var eye_radius := face_size * eye_radius_ratio
	var mouth_radius := face_size * mouth_radius_ratio
	var mouth_offset_y := face_size * mouth_offset_y_ratio

	var left_eye_pos := center + Vector2(-eye_offset_x, -eye_offset_y)
	var right_eye_pos := center + Vector2(eye_offset_x, -eye_offset_y)
	var mouth_center := center + Vector2(0, mouth_offset_y)

	match current_face:
		"angry":
			draw_circle(left_eye_pos, eye_radius, color_angry, false, line_width)
			draw_circle(right_eye_pos, eye_radius, color_angry, false, line_width)
			draw_arc(mouth_center, mouth_radius, PI, 2 * PI, arc_point_count, color_angry, line_width)
			draw_line(left_eye_pos+Vector2(-100,-200),left_eye_pos+Vector2(100,-100),color_angry,line_width)
			draw_line(right_eye_pos+Vector2(-100,-100),right_eye_pos+Vector2(100,-200),color_angry,line_width)
		"smile":
			draw_circle(left_eye_pos, eye_radius, color_default, false, line_width)
			draw_circle(right_eye_pos, eye_radius, color_default, false, line_width)
			var smile_center := mouth_center + Vector2(0, mouth_radius * mouth_smile_extra_offset)
			draw_arc(smile_center, mouth_radius, 0, PI, arc_point_count, color_default, line_width)
		"suprised":
			var surprised_eye_radius := eye_radius * eye_surprised_scale
			draw_circle(left_eye_pos, surprised_eye_radius, color_default, false, line_width)
			draw_circle(right_eye_pos, surprised_eye_radius, color_default, false, line_width)
			draw_circle(mouth_center, eye_radius, color_default, false, line_width)
		"neutral":
			draw_circle(left_eye_pos, eye_radius, color_default, false, line_width)
			draw_circle(right_eye_pos, eye_radius, color_default, false, line_width)
			var mouth_left := center + Vector2(-mouth_radius, mouth_offset_y)
			var mouth_right := center + Vector2(mouth_radius, mouth_offset_y)
			draw_line(mouth_left, mouth_right, color_default, line_width)
			

func _physics_process(_delta: float) -> void:
	queue_redraw()
	
	
