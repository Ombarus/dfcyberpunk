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

func _ready() -> void:
	pass

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
	var fridge_anim : AnimationPlayer = fridge.find_child("AnimationPlayer", true, false)
	var player_anim : AnimationPlayer = ParentEntity.find_child("AnimationPlayer", true, false)
	
	fridge_anim.play("FridgeOpen")
	player_anim.play("Interact")
	await player_anim.animation_finished
	if await make_sure_still_running() == false:
		return
	player_anim.play("Interact")
	await player_anim.animation_finished
	if await make_sure_still_running() == false:
		return
	player_anim.play("Interact")
	fridge_anim.play_backwards("FridgeOpen")
	await player_anim.animation_finished
	_seq_state = SEQ_STATE.FINISHED
	
func SimpleInteractSequence():
	_seq_state = SEQ_STATE.RUNNING
	_cur_seq = "SimpleInteractSequence"
	var player_anim : AnimationPlayer = ParentEntity.find_child("AnimationPlayer", true, false)
	player_anim.play("Interact")
	await player_anim.animation_finished
	_seq_state = SEQ_STATE.FINISHED
	
func SitOnChair(chair : Advertisement):
	_seq_state = SEQ_STATE.RUNNING
	_cur_seq = "SitAndPutOnTable"
	var player_anim : AnimationPlayer = ParentEntity.find_child("AnimationPlayer", true, false)
	player_anim.play("SitChair")
	var tween = get_tree().create_tween()
	tween.tween_property(ParentEntity,"global_transform", chair.global_transform, 1.0)
	
	await player_anim.animation_finished
	if await make_sure_still_running() == false:
		return

	player_anim.play("SitChairIdle")
	_seq_state = SEQ_STATE.FINISHED
	
	

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
