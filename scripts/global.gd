extends Node

# ---- ONLINE ----
var pseudo : String
var server_ip : String
var is_host : bool
var peer : ENetMultiplayerPeer

var players_dict : Dictionary
var player_count : int = 0
