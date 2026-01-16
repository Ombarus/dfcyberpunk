extends Node
class_name Messaging

@export var BubbleScene : PackedScene

class Message:
	var Sender: Entity
	var HearingRange: float
	var Lifetime: float
	var Text: String
	var Bubble: Control
	
	func _init(sender : Entity, text: String) -> void:
		self.Sender = sender
		self.Lifetime = 1.0 + text.length() * 0.1
		self.Text = text
		self.HearingRange = 3.0
	
var Messages: Array[Message] = []

func Say(sender : Entity, text: String):
	var message := Message.new(sender, text)
	Messages.push_back(message)
	var n : Control = BubbleScene.instantiate()
	self.add_child(n)
	n.global_position = message.Sender.get_viewport().get_camera_3d().unproject_position(message.Sender.global_position)
	(n.get_node("RichTextLabel") as RichTextLabel).text = text
	message.Bubble = n
	
func Listen(listener: Entity) -> Array[Message]:
	var heard : Array[Message] = []
	var my_pos : Vector3 = listener.global_position
	for m in Messages:
		if (m.Sender.global_position - my_pos).length_squared() <= m.HearingRange:
			heard.push_back(m)
	return heard
	
func _process(delta: float) -> void:
	for i in range(Messages.size() - 1, -1, -1):
		var m : Message = Messages[i]
		m.Lifetime -= delta
		if m.Lifetime <= 0:
			Messages.remove_at(i)
			m.Bubble.visible = false
			m.Bubble.queue_free()
		else:
			m.Bubble.global_position = m.Sender.get_viewport().get_camera_3d().unproject_position(m.Sender.global_position)
