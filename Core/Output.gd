extends Node



signal text_outputted(data:String)

signal clear_outputted

func send_to_output(data: String)->void:
	text_outputted.emit(data)
	


func clear_output()->void:
	clear_outputted.emit()
