extends Application
#this is an app that will show a simple circle but it will rotate over time
#resolution is 96x20
var curr = 1
@onready  var canvas: TempCanvas = TempCanvas.new()

func _ready() -> void:
	add_child(canvas)

func _input(_event: InputEvent) -> void:
	if active==false:
		return
	if _event is InputEventKey:
		if _event.keycode == Key.KEY_ESCAPE:
			shutdown_app()

func _physics_process(_delta: float) -> void:
	if active==false:
		return

func start(_command:String, _stripped_commands: Array[String])->void:
	active=true
	canvas.enabled=true
	
func exit()->void:
	canvas.enabled=false
	canvas.queue_redraw()
	GlobalOutput.clear_output()
	active=false
	
	
