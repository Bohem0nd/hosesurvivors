class_name PassiveAbility
extends Node
## Base class for character passives. Subclasses read tuning from `params`
## (CharacterData.passive_params) and act on the player through its StatBlock
## or the GameContext, never through character-specific checks elsewhere.

var player: Player
var ctx: GameContext
var params: Dictionary


func setup(p_player: Player, p_ctx: GameContext, p_params: Dictionary) -> void:
	player = p_player
	ctx = p_ctx
	params = p_params
	_on_setup()


func _on_setup() -> void:
	pass


## Short line shown on the HUD (empty to hide).
func get_status_text() -> String:
	return ""
