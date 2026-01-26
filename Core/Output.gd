extends Node



signal text_outputted(data:String,channel:String)

signal clear_outputted

func send_to_output(data: String,channel:String="")->void:
	text_outputted.emit(data,channel)
	
func clear_output()->void:
	clear_outputted.emit()
