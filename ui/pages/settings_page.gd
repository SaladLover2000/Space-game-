extends "res://ui/pages/page_base.gd"

func build() -> void:
	host.names_form(false)
	var calm := CheckButton.new()
	calm.text = "Calm, steady instrument lights"
	calm.button_pressed = Game.state.calm_lights
	calm.toggled.connect(func(value): host.apply_setting(calm,"calm_lights",value))
	host.content.add_child(calm)
	var sound := CheckButton.new()
	sound.text = "Play completion chime"
	sound.button_pressed = Game.state.sound
	sound.toggled.connect(func(enabled: bool): host.apply_setting(sound,"sound",enabled))
	host.content.add_child(sound)
	host.paragraph("Saves are local and automatic. Closing pauses the saved session; reopening never grants time spent away. While running, minimizing keeps the timer counting.")
