# Arrow
# Game Narrative Design Tool
# Mor. H. Golkar

# Main (root)
extends Node

signal mind_initialized

export var _SANDBOX:bool = Settings.RUN_IN_SANDBOX

var Utils = Helpers.Utils

onready var TheTree:SceneTree = self.get_tree()
onready var UI = MainUserInterface.UiManager.new(self)
onready var Configs = Configuration.ConfigHandler.new(self)
onready var Mind = CentralMind.Mind.new(self)

# Quick Preferences (defaults)
export var _AUTO_INSPECT:bool = true

func _ready() -> void:
	# print startup messages
	print(Embedded.Text.Welcome_Message)
	print(Embedded.Text.Legal_Notes)
	# get operational
	handle_cli_arguments()
	register_connections()
	Configs.load_configurations()
	UI.setup_defaults_on_ui_and_quick_preferences()
	UI.update_view_from_configuration(Configs.CONFIRMED)
	Mind.post_initialization()
	self.emit_signal("mind_initialized")
	self.set_process_input(true)
	# and finally, report app state
	print("Sandbox: ", ("ON" if _SANDBOX else "OFF"))
	pass

func handle_cli_arguments():
	var args = Array( OS.get_cmdline_args() )
	# 1.
	if args.has("--manual"):
		var manual_message = Embedded.Text.Manual.format({ "ver" : Settings.ARROW_VERSION, "www": Settings.ARROW_WEBSITE, "cfn": Settings.CONFIG_FILE_NAME })
		print(manual_message)
	# 2.
	if args.has("--sandbox"):
		_SANDBOX = true
	# 3. --config-dir <path>
	var custom_config_path_index = (args.find("--config-dir") + 1)
	if custom_config_path_index > 0 && args.size() > custom_config_path_index :
		Configs._CONFIG_FILE_BASE_DIR = Utils.safe_base_dir( args[custom_config_path_index] ) # will stay null or a safe path ending with "/"
	# 4. --work-dir <path>
	var custom_local_app_dir_path_index = (args.find("--work-dir") + 1)
	if custom_local_app_dir_path_index > 0 && args.size() > custom_local_app_dir_path_index :
		var new_app_local_dir_path = args[custom_local_app_dir_path_index]
		if new_app_local_dir_path is String && Utils.is_abs_or_rel_path(new_app_local_dir_path):
			self.call_deferred("change_local_app_dir_path_preference_in_runtime", new_app_local_dir_path)
	pass

func change_local_app_dir_path_preference_in_runtime(new_app_local_dir_path: String):
	# following will call the `dynamically_update_local_app_dir` back from main after some work
	Configs.emulate_prefrence_modification_and_save("app_local_dir_path", new_app_local_dir_path)
	pass

func dynamically_update_local_app_dir(new_app_local_dir_path:String) -> void:
	if new_app_local_dir_path is String && (new_app_local_dir_path.is_abs_path() || new_app_local_dir_path.is_rel_path()):
		Mind.ProMan.hold_local_app_dir(new_app_local_dir_path)
		Mind.reset_project_save_status(false)
		Mind.load_projects_list()
	else:
		printerr("Wrong Operation! Trying to dynamically update local app directory with wrong argument: ", new_app_local_dir_path)
	pass

func register_connections() -> void:
	UI.register_connections()
	pass

func set_quick_preferences(preference:String, new_state:bool, refresh_view:bool = true) -> void:
	match preference:
		"auto_inspect":
			_AUTO_INSPECT = new_state
#		"other_quick_pref":
#			_OTHER_QUICK_PREF = new_state
	if refresh_view != false :
		UI.update_quick_preferences_switchs_view()
	pass

func toggle_quick_preferences(preference:String, refresh_view:bool = true):
	var new_state = null
	match preference:
		"auto_inspect":
			new_state = ( ! _AUTO_INSPECT )
#		"other_quick_pref":
#			new_state = ( ! _OTHER_QUICK_PREF )
	if new_state != null:
		set_quick_preferences(preference, new_state, refresh_view)
	return new_state

func toggle_about() -> void:
	UI.toggle_panel_visibility("about")
	pass

func safe_quit_app() -> void:
	Mind.close_project(false, true)
	pass

func quit_app(exit_code:int = OK) -> void:
	if exit_code != OK: # != 0
		printerr("Quiting app due to unexpected behavior!")
	yield(TheTree, "idle_frame")
	TheTree.quit(exit_code)
	pass

# handling quit signal(s) from window manager
func _notification(what) -> void:
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		safe_quit_app()
	pass

# shortcuts (keybinding/action)
func _input(event:InputEvent) -> void:
	var _handled = Mind.handle_shortcuts(event)
	pass