extends TestSuite
## Touch play: the virtual joystick and the touch-only HUD pause button.


func _touch_controls(game: Game) -> TouchControls:
	for child in game.get_children():
		if child is TouchControls:
			return child
	return null


func _touch(index: int, pos: Vector2, pressed: bool) -> InputEventScreenTouch:
	var ev := InputEventScreenTouch.new()
	ev.index = index
	ev.position = pos
	ev.pressed = pressed
	return ev


func _drag(index: int, pos: Vector2) -> InputEventScreenDrag:
	var ev := InputEventScreenDrag.new()
	ev.index = index
	ev.position = pos
	return ev


func _move_vector() -> Vector2:
	return Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")


func test_joystick_drives_movement() -> void:
	var game := make_game()
	var stick := _touch_controls(game)
	check(stick != null, "game has touch controls")
	stick._unhandled_input(_touch(0, Vector2(300, 200), true))
	check_eq(_move_vector(), Vector2.ZERO, "planting the stick does not move")
	stick._unhandled_input(_touch(1, Vector2(100, 100), true))  # second finger is ignored
	stick._unhandled_input(_drag(0, Vector2(360, 200)))
	check(_move_vector().x > 0.95, "dragging right moves right")
	stick._unhandled_input(_drag(1, Vector2(100, 300)))
	check(absf(_move_vector().y) < 0.05, "other fingers don't steer")
	# Dragging past the rim pulls the base along, so reversing responds at once.
	stick._unhandled_input(_drag(0, Vector2(300, 200)))
	check(_move_vector().x < -0.5, "back at the start point after an overshoot moves left")
	stick._unhandled_input(_touch(0, Vector2(300, 200), false))
	check_eq(_move_vector(), Vector2.ZERO, "lifting the finger stops")

	stick._unhandled_input(_touch(0, Vector2(300, 200), true))
	stick._unhandled_input(_drag(0, Vector2(300, 260)))
	check(_move_vector().y > 0.95, "dragging down moves down")
	tree.paused = true  # e.g. a level-up opens; the finger-up will never arrive
	await tree.process_frame
	check_eq(_move_vector(), Vector2.ZERO, "pausing drops the stick")
	await free_game(game)


func test_touch_pause_button() -> void:
	var game := make_game()
	RunState.active = true
	Device._set_touch_mode(true)
	check(game.hud._pause_button.visible, "pause button shown on touch")
	game.hud._pause_button.pressed.emit()
	check(game.pause_menu.visible and tree.paused, "pause button pauses")
	game.pause_menu.close()
	Device._set_touch_mode(false)
	check(not game.hud._pause_button.visible, "pause button hidden without touch")
	await free_game(game)


func test_view_stays_in_bounds() -> void:
	var view := Device.view_size()
	check(view.x >= Device.BASE.x and view.y >= Device.BASE.y, "view covers the design area")
	check(view.x <= Device.MAX_VIEW.x and view.y <= Device.MAX_VIEW.y, "view is capped")
