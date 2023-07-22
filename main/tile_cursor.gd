extends Sprite2D


const X_OFFSET: int = -2
const Y_OFFSET: int = -2

var grid_coord: Vector2i
var target_grid_coord: Vector2i
var target_position: Vector2

func initialise_cursor():
	global_position = Vector2(GameBoard.GRID_START_X + X_OFFSET, \
			GameBoard.GRID_START_Y + GameBoard.GRID_SIZE * (GameBoard.GRID_HEIGHT - 1) + Y_OFFSET)
	
	grid_coord = Vector2i(0, GameBoard.GRID_HEIGHT - 1)


func move_cursor_grid_with_animate(new_dir: Vector2i, is_keyboard: bool) -> Vector2i:
	if is_keyboard:
		target_grid_coord = grid_coord + new_dir
		if target_grid_coord.x < 0:  # Wrap right side
			target_grid_coord.x = GameBoard.GRID_WIDTH - 1
		elif target_grid_coord.x >= GameBoard.GRID_WIDTH:  # Wrap left side
			target_grid_coord.x = 0

		if target_grid_coord.y < 0: # Wrap to bottom
			target_grid_coord.y = GameBoard.GRID_HEIGHT - 1
		elif target_grid_coord.y >= GameBoard.GRID_HEIGHT: # Wrap to top
			target_grid_coord.y = 0
		
	else:  # This was set by mouse so just move to that position
		target_grid_coord = new_dir

	target_position = Vector2(GameBoard.GRID_START_X + X_OFFSET + target_grid_coord.x * GameBoard.GRID_SIZE, \
			GameBoard.GRID_START_Y + Y_OFFSET + target_grid_coord.y * GameBoard.GRID_SIZE)
			
	var tween = get_tree().create_tween()
	tween.tween_property(self, "global_position", target_position, 0.02).set_ease(Tween.EASE_IN)
	tween.play()
	grid_coord = target_grid_coord
	return grid_coord
