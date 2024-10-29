@tool
extends Control
class_name SpriteControl

@export var sprites: Array[CanvasItem]:
	set = set_sprites


func set_sprites(p_sprites: Array[CanvasItem]) -> void:
	for p_sprite in p_sprites:
		if p_sprite:
			if p_sprite is Sprite2D:
				var p_sprite_2D: Sprite2D = p_sprite
				if not p_sprite_2D.texture:
					return
			elif p_sprite is AnimatedSprite2D:
				var p_animated_sprite_2D: AnimatedSprite2D = p_sprite
				if not p_animated_sprite_2D.sprite_frames:
					return
			else:
				return
	sprites = p_sprites
	_resize_sprites()


func _on_resized() -> void:
	_resize_sprites()


func _resize_sprites() -> void:
	for sprite in sprites:
		if sprite is Sprite2D:
			var sprite_2D: Sprite2D = sprite
			if sprite_2D.texture:
				sprite_2D.centered = false
				sprite_2D.scale = size / sprite_2D.texture.get_size()
		elif sprite is AnimatedSprite2D:
			var animated_sprite_2D: AnimatedSprite2D = sprite
			if animated_sprite_2D.sprite_frames:
				var texture: Texture2D = animated_sprite_2D.sprite_frames.get_frame_texture(animated_sprite_2D.animation, animated_sprite_2D.frame)
				animated_sprite_2D.centered = false
				animated_sprite_2D.scale = size / texture.get_size()


func _ready() -> void:
	resized.connect(_on_resized)
	_resize_sprites()
