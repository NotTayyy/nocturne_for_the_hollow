extends Node

var game_manager: Node = null
var combo_manager: Node2D = null
var character_manager: Node2D = null
var camera_manager: Node2D = null
var level_manager: Node2D = null
var audio_manager: Node2D = null
var ui_manager: Node2D = null

var Volume: Dictionary = {
	"master": 2,
	"bgm": 2,
	"sfx": 2,
	"voice": 2,
	"bgsfx": 2
}

var Walls: StaticBody2D = null
var UI: Node = null

var P1: Fighter = null
var P1_Select: String = ""

var P2: Fighter = null
var P2_Select: String = ""

var Level: PackedScene = null
var Level_Select: String = ""
