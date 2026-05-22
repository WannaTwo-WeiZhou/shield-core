extends Label

const Version = preload("res://version.gd")

func _ready() -> void:
	text = "v%s.%d" % [Version.MAJOR_VERSION, Version.BUILD_NUMBER]
