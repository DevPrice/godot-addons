extends Node

signal broadcasted(message: GameplayMessage)

func broadcast(message: GameplayMessage) -> void:
	broadcasted.emit(message)

func subscribe(channel: String, exact_match: bool = true) -> MessageSubscription:
	var subscription := MessageSubscription.new()
	return subscription

class MessageSubscription extends RefCounted:
	signal message(message: GameplayMessage)
