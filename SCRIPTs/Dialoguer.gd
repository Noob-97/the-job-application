extends Node

var conversations = {}  # {"test_conversation": [ {speaker, line}, ... ]}
var current_conversation = ""
var current_index = 0
var endings = {} # {"forest_m" : {col0 : "", col1 : "", col2: ""}}

var listen_input := false
var initial_click := true

var music_playback

var colors = {"derek": Color(0.648, 0.785, 1.0, 1.0),
"kyro": Color(0.743, 0.689, 0.953, 1.0),
"amber": Color(0.979, 0.653, 0.678, 1.0),
"toby": Color(0.939, 0.741, 0.295, 1.0)}

var char_speed := 0.01

@onready var dialog := get_node("/root/Node3D/Dialog")
@onready var decision := get_node("/root/Node3D/Decision")
@onready var music := get_node("/root/Node3D/Music")
@onready var sfx := get_node("/root/Node3D/SFX")
@onready var interacter := get_node("/root/Node3D/character/neck/camera/RayCast3D")
@onready var blackscreen := get_node("/root/Node3D/Blackscreen")

func _ready():
	load_csv("res://tja-dialog - Sheet1.txt")
	#start_conversation("test_conversation")

# --- Load CSV without headers ---
func load_csv(path: String):
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("Could not open CSV: " + path)
		return
	
	var conversation_name = ""
	var conversation_lines = []
	
	while not file.eof_reached():
		var line = file.get_csv_line()
		if line.size() == 0:
			continue
		
		var col0 = line[0].strip_edges()
		var col1 = ""
		var col2 = ""
		if line.size() > 1:
			col1 = line[1].strip_edges()
		if line.size() > 2:
			col2 = line[2].strip_edges()
		
		# Start of a new conversation
		if col0 != "" and col0 != "end" and col0 != "end_goto" and not col0.contains(">") and not col0.contains("#") and not col0.contains("/") and not col0.contains(":"):
			conversation_name = col0
			conversation_lines = []
			continue
		
		# End of conversation
		if col0 == "end" or col0 == "end_goto" or col0.contains(">"):
			if conversation_name != "":
				conversations[conversation_name] = conversation_lines.duplicate()
				var ending = {
					"col0" : col0,
					"col1" : col1,
					"col2" : col2
				}
				endings[conversation_name] = ending
				conversation_name = ""
			continue
		
		# If inside a conversation, store the line
		if conversation_name != "":
			var entry = {
				"speaker": col1,
				"text": col2,
				"command": col0
			}
			conversation_lines.append(entry)
	
	file.close()
	print("Loaded conversations:", conversations.keys())

# --- Start a conversation ---
func start_conversation(name: String):
	if not conversations.has(name):
		push_error("Conversation not found: " + name)
		return
	
	current_conversation = name
	current_index = 0
	dialog.visible = true
	show_current_line()

# --- Show the current line ---
func show_current_line():
	var convo = conversations[current_conversation]
	if current_index >= convo.size():
		print("End of conversation:", current_conversation)
		if endings[current_conversation].col0 == "end_goto":
			get_tree().change_scene_to_file("res://SCENEs/" + endings[current_conversation].col1 + ".tscn")
		if endings[current_conversation].col0.contains(">"):
			var txt = endings[current_conversation].col0.replace(">", "").split(",")
			decision.get_child(0).text = txt[0]
			decision.get_child(0).pressed.connect(get_option.bind(endings[current_conversation].col1))
			decision.get_child(1).text = txt[1]
			decision.get_child(1).pressed.connect(get_option.bind(endings[current_conversation].col2))
			Input.action_press("ui_cancel")
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			decision.visible = true
		else:
			dialog.visible = false
			initial_click = true
			interacter.onhold = false
		current_conversation = ""
		listen_input = false
		return
	
	var entry = convo[current_index]
	write_text("> %s: %s" % [entry["speaker"], entry["text"]])
	if colors.has(entry["speaker"]):
		dialog.get_child(1).set("theme_override_colors/font_color", colors[entry["speaker"]])
	else:
		dialog.get_child(1).set("theme_override_colors/font_color", Color(0.667, 0.667, 0.667, 1.0))
	sfx.stop()
	
	var emotion = entry["command"]
	if entry["command"].split(":").size() == 2 or entry["command"].split(":").size() == 3:
		emotion = entry["command"].split(":")[1]

	var revisedentry = entry["command"]
	if entry["command"].contains(":"):
		revisedentry = entry["command"].split(":")[0]
	
	if entry["command"].contains("/"):
		match revisedentry:
			"/pause_music":
				music_playback = music.get_playback_position()
				music.stop()
			"/resume_music":
				music.play(music_playback)
			"/black_screen":
				blackscreen.visible = true

	elif entry["command"].contains("#"):
		var sound = load("res://SFXs/"+ revisedentry.replace("#", "") +".mp3")
		sfx.stream = sound	
		sfx.play()
	
	if emotion != "" and not emotion == null and emotion != "/black_screen" and emotion != "#fighting" and emotion != "#aah" and emotion != "#laugh":
		emotion = emotion.replace(":", "")
		var png = load("res://PNGs/" + entry["speaker"] + "_" +emotion + ".png")
		var node = get_node("/root/Node3D/" + entry["speaker"])
		node.material_override.set_shader_parameter("sprite_texture", png)
	
	listen_input = true

# --- Go to next line ---
func next_line():
	if current_conversation == "":
		return
	current_index += 1
	show_current_line()
	
func _input(event: InputEvent) -> void:
	if Input.is_action_pressed("interact") and listen_input and not initial_click:
		next_line()
	elif Input.is_action_pressed("interact") and listen_input:
		initial_click = false
		
func get_option(convo:String):
	decision.visible = false
	Dialoguer.start_conversation(convo)
	
func write_text(text:String):
	var label = dialog.get_child(1)
	label.visible_ratio = 0
	label.text = text
	
	var char_len:float = float(1) / float(label.text.length())
	var header = text.split(":")[0].length() + 1
	var total = label.text.length() - header
	label.visible_ratio = header * char_len
	
	for i in total:
		label.visible_ratio = label.visible_ratio + char_len
		await get_tree().create_timer(char_speed).timeout
		
	label.visible_ratio = 1
