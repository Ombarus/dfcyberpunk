extends Node
class_name Sequencer

@onready var ParentEntity : Entity = get_parent()

enum SEQ_STATE {
	IDLE,
	WAITING,
	RUNNING,
	FINISHED
}

var _seq_state : SEQ_STATE = SEQ_STATE.IDLE
var _cur_seq : String = ""
var _last_delta : float = 0.0

func _ready() -> void:
	pass
	
func _process(delta: float) -> void:
	_last_delta = delta

func SetContinue():
	# Only set RUNNING if WAITING. This way I can call this every frame
	# and it only works when needed
	if _seq_state == SEQ_STATE.WAITING:
		_seq_state = SEQ_STATE.RUNNING
		
func Reset():
	_seq_state = SEQ_STATE.IDLE
	_cur_seq = ""

func CurState() -> SEQ_STATE:
	return _seq_state

func CurSequence() -> String:
	return _cur_seq

func FridgeSequence(fridge : Advertisement):
	_seq_state = SEQ_STATE.RUNNING
	_cur_seq = "FridgeSequence"
	
	var fridge_tree : AnimationTree = fridge.find_child("AnimationTree", true, false)
	var fridge_state : AnimationNodeStateMachinePlayback = fridge_tree.get("parameters/playback")
	var player_tree : AnimationTree = ParentEntity.find_child("AnimationTree", true, false)
	var player_state : AnimationNodeStateMachinePlayback = player_tree.get("parameters/playback")
	
	fridge_state.travel("OpenIdle")
	player_state.travel("Interact")
	await waitForState(fridge_state, "OpenIdle")
	await waitForState(player_state, "Idle")
	if await make_sure_still_running() == false:
		return

	fridge_state.travel("CloseIdle")
	player_state.travel("Interact")
	await waitForState(fridge_state, "CloseIdle")
	_seq_state = SEQ_STATE.FINISHED
	
func OneShotSequence(anim_name : String):
	_seq_state = SEQ_STATE.RUNNING
	_cur_seq = "OneShotSequence"
	
	var player_tree : AnimationTree = ParentEntity.find_child("AnimationTree", true, false)
	var player_state : AnimationNodeStateMachinePlayback = player_tree.get("parameters/playback")
	
	player_state.travel(anim_name)
	await waitForState(player_state, anim_name)
	await waitForState(player_state, "Idle")
		
	_seq_state = SEQ_STATE.FINISHED
	
func waitForState(machine : AnimationNodeStateMachinePlayback, state : String):
	var timeout := 10.0
	while timeout > 0:
		var cur_anim = machine.get_current_node()
		timeout -= _last_delta
		if cur_anim == state:
			return
		await get_tree().process_frame
	

# This assume we run Ai every frame.
# Easy optim would be to have a "tick" event we can listen to
# Next tick didn't set SEQ_STATE then abort
func make_sure_still_running(reset : bool = true) -> bool:
	_seq_state = SEQ_STATE.WAITING
	await get_tree().process_frame
	await get_tree().process_frame
	if _seq_state == SEQ_STATE.WAITING:
		if reset:
			Reset()
		return false
	return true
