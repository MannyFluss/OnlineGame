extends Node
class_name Application
#this is a baseclass to be inherited from. no state to be in this class other than metadata

@export var AppName : String = "default"

var active : bool = false

signal AppShutDown

func _input(_event: InputEvent) -> void:
	printerr("input not implemented for application, shutting down")
	pass

func start(_command:String, _stripped_commands:Array[String])->void:
	printerr("start not implemented for application")


func exit()->void:
	printerr("state cleanup not implemented for application")

func shutdown_app()->void:
	AppShutDown.emit()
	pass
