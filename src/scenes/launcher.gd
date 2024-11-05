extends Panel

@export var exeLink : String = ""
@export var pckLink : String = ""
@export var versionLink : String = ""
@export var exePath : String = "user://game"
@export var pckPath : String = "user://game.pck"
@export var versionPath : String = "user://version"

@export_node_path("Button") var playPath : NodePath = ""

var request : HTTPRequest = null

func _ready() -> void:
	get_node(playPath).disabled = true
	
	IdentifySystem()
	VerifyFiles()
	CheckIntegrity()
	pass

# Identify OS to get correct executable
func IdentifySystem():
	match OS.get_name():
		"Windows":
			exeLink += ".exe"
			exePath += ".exe"
	pass

# Return true if the given path exists otherwise return false
func FileExists(path : String) -> bool:
	return DirAccess.dir_exists_absolute(path)

# Try to check every game files
func VerifyFiles() -> void:
	if FileExists(exePath) and !FileExists(pckPath) and FileExists(versionPath):
		Download(versionLink, versionPath, false)
	else:
		CheckIntegrity()
	pass

# Check all game files integrity
func CheckIntegrity() -> void:
	if !FileExists(exePath):
		Download(exeLink, exePath, false)
		print("Game not found")
		return
	
	if !FileExists(versionPath):
		Download(versionLink, versionPath, false)
		DirAccess.remove_absolute(versionPath)
		print("Version not found")
		return
	
	if !FileExists(pckPath):
		Download(pckLink, pckPath, false)
		print("PCK not found")
		return
	
	get_node(playPath).text = "Play"
	get_node(playPath).disabled = false
	pass

# Compare local version with online version
func CompareVersions(new : String):
	var file = FileAccess.open(versionPath, FileAccess.READ)
	var version = file.get_as_text()
	file.close()
	
	if int(new) > int(version):
		DirAccess.remove_absolute(versionPath)
	
	CheckIntegrity()
	pass

# Download game content
func Download(link : String, path : String, justVersion : bool) -> void:
	request = HTTPRequest.new()
	add_child(request)
	
	get_node(playPath).text = "Downloading %s..." % path.get_file()
	request.request_completed.connect(InstallContent.bind(path, justVersion)) 
	
	var error : int = request.request_raw(link)
	if error != OK:
		get_node(playPath).text = "Download Failed %s" % error_string(error)
	
	remove_child(request)
	pass

# Signal from HTTPREQUEST when a request is completed
func InstallContent(_result: int, _response_code: int, _headers: PackedStringArray, body: PackedByteArray, path : String, justVersion : bool) -> void:
	if justVersion:
		var new : String = str(body.get_string_from_utf8())
		CompareVersions(new)
		return
	
	DirAccess.remove_absolute(path)
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_buffer(body)
	file.close()
	CheckIntegrity()
	pass
