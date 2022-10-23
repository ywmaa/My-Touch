extends Node

enum coordinates {xy,x,y}

var direction : coordinates = coordinates.xy

enum tool_mode {none,move_image,rotate_image,scale_image,selection_tools,text}
var current_tool : tool_mode = tool_mode.none



var last_mode : tool_mode = tool_mode.none
var current_mode : tool_mode = tool_mode.none:
	get: return current_mode
	set(new_mode):
		last_mode = current_mode
		current_mode = new_mode


func rotate(object,direction_point:Vector2):
	object.look_at(direction_point)
	object.rotate(PI/2) 


func scale(object,amount:Vector2):
	match direction:
		coordinates.xy:
			object.scale += amount
		coordinates.x:
			object.scale.x += amount.x
		coordinates.y:
			object.scale.y += amount.y


func move(object,amount:Vector2):
	match direction:
		coordinates.xy:
			object.position += amount
		coordinates.x:
			object.position.x += amount.x
		coordinates.y:
			object.position.y += amount.y

func lock_x():
	if direction == coordinates.x:
		direction = coordinates.xy
	else:
		direction = coordinates.x

func lock_y():
	if direction == coordinates.y:
		direction = coordinates.xy
	else:
		direction = coordinates.y
