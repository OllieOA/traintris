extends Sprite2D

var grid_position: Vector2i

const X_OFFSET: int = -2
const Y_OFFSET: int = -2

var target_position: Vector2i

func initialise_cursor():
	global_position = Vector2(GameBoard.GRID_START_X + X_OFFSET, \
			GameBoard.GRID_START_Y + GameBoard.GRID_SIZE * (GameBoard.GRID_HEIGHT - 1) + Y_OFFSET)
	
	grid_position = Vector2i(0, GameBoard.GRID_HEIGHT - 1)


func move_cursor_grid_with_animate(new_dir: Vector2i) -> Vector2i:
	# TODO: Add tween
	grid_position += new_dir
	global_position = Vector2(global_position.x + GameBoard.GRID_SIZE * new_dir.x, global_position.y + GameBoard.GRID_SIZE * new_dir.y)
	# TODO: HANDLE WRAPPING
	return grid_position
