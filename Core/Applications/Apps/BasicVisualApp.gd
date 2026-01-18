extends Application
#this is an app that will show a simple circle but it will rotate over time
#resolution is 96x20
var curr = 1

var image = ""

func _ready() -> void:
	for i in range(96*20):
		image = image.insert(0,"0")

func _input(_event: InputEvent) -> void:
	if active==false:
		return
	if _event is InputEventKey:
		if _event.keycode == Key.KEY_ESCAPE:
			shutdown_app()
func _physics_process(_delta: float) -> void:
	if active==false:
		return
	image[curr]='0'
	curr += 1
	image[curr]='X'
	GlobalOutput.clear_output()
	#GlobalOutput.send_to_output(image.replace("X","[img]icon.svg[/img]"))
	GlobalOutput.send_to_output(image)

func start(_command:String, _stripped_commands: Array[String])->void:
	active=true

func exit()->void:
	GlobalOutput.clear_output()
	active=false
	
	
