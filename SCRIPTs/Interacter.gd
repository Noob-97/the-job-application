extends RayCast3D

var current_interacter
var onhold := false
@onready var tooltip = get_node("../../../Tooltip")

func _process(delta: float) -> void:
	if is_colliding() and not onhold:
		current_interacter = get_collider()
		# highlight
		current_interacter.get_parent().material_override.set_shader_parameter("line_color", Vector4(1.0,1.0,0.0,1.0))
		tooltip.visible = true
		var txt = current_interacter.get_parent().get_meta("tooltip")
		txt = txt.replace("=name", current_interacter.get_parent().name)
		tooltip.get_child(1).text = txt
	elif current_interacter != null:
		current_interacter.get_parent().material_override.set_shader_parameter("line_color", Vector4(1.0,1.0,0.0,0.0))
		current_interacter = null
		tooltip.visible = false

func _input(event: InputEvent) -> void:
	if Input.is_action_pressed("interact") and current_interacter != null and not onhold:
		if current_interacter.get_parent().get_meta("type") == "convo":
			Dialoguer.start_conversation(current_interacter.get_parent().get_meta("action"))
			onhold = true
