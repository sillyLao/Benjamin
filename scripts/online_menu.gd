extends Control

@onready var http_request = $HTTPRequest

@export var online_lobby_scene : PackedScene

var peer : ENetMultiplayerPeer = ENetMultiplayerPeer.new()
var host_ip : String
var join_ip : String

func _ready():
	http_request.request_completed.connect(_on_request_completed)
	send_request()
	
func send_request():
	var headers = ["Content-Type: application/json"]
	http_request.request("https://api.ipify.org", headers, HTTPClient.METHOD_GET)

func _on_request_completed(_results, _response_code, _headers, body):
	var ip = body.get_string_from_utf8()
	host_ip = ip

func _on_host_pressed():
	$HostPanel.show()
	$JoinPanel.hide()
func _on_join_pressed():
	$HostPanel.hide()
	$JoinPanel.show()
func _on_host_2_pressed():
	var result = peer.create_server(51779, 7)
	match result:
		Error.OK:
			print("OK")
			connected("Host")
		Error.ERR_ALREADY_IN_USE:
			print("ERR_ALREADY_IN_USE")
		Error.ERR_CANT_CREATE:
			print("ERR_CANT_CREATE")

func _on_join_2_pressed():
	join_ip = $JoinPanel/MarginContainer/VBoxContainer/IP/TextEdit.text
	if not join_ip:
		join_ip = "127.0.0.1"
	var result = peer.create_client(join_ip, 51779)
	match result:
		Error.OK:
			print("OK")
			connected("Join")
		Error.ERR_ALREADY_IN_USE:
			print("ERR_ALREADY_IN_USE")
		Error.ERR_CANT_CREATE:
			print("ERR_CANT_CREATE")

func connected(type : String):
	multiplayer.multiplayer_peer = peer
	Global.pseudo = get_node(type+"Panel/MarginContainer/VBoxContainer/Pseudo/TextEdit").text
	Global.peer = peer
	match type:
		"Host":
			Global.server_ip = host_ip
			Global.is_host = true
		"Join":
			Global.server_ip = join_ip
			Global.is_host = false
	get_tree().change_scene_to_packed(online_lobby_scene)


func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/Menu/main_menu.tscn")
