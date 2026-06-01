extends SceneTree

const BriefingManagerScript := preload("res://scripts/briefing/BriefingManager.gd")

func _init() -> void:
	var briefing = BriefingManagerScript.new()
	var text: String = briefing.compose(
		2,
		"Weather: clear",
		"Order: none",
		"Milestone: none",
		"Animals: none",
		"Spring 2/7"
	)

	if not text.contains("Spring 2/7"):
		_fail("Briefing should include the current season day.")
		return

	print("PASS season_briefing_manager_test")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
