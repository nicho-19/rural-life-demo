extends SceneTree

const BriefingManagerScript := preload("res://scripts/briefing/BriefingManager.gd")

func _init() -> void:
	var briefing = BriefingManagerScript.new()
	var text: String = briefing.compose(
		2,
		"天气：多云。今天很安静。",
		"可选订单：萝卜 0/2 | 奖励 150 金",
		"小里程碑：已点亮 1 / 5。",
		"动物：鸡 2/4，牛 1/2，今天已喂 1/3。"
	)

	if not text.contains("今日简报"):
		_fail("Briefing should have a clear title.")
		return
	if not text.contains("第 2 天"):
		_fail("Briefing should include the current day.")
		return
	if not text.contains("天气：多云"):
		_fail("Briefing should include weather context.")
		return
	if not text.contains("可选订单"):
		_fail("Briefing should include optional order context.")
		return
	if not text.contains("动物：鸡 2/4"):
		_fail("Briefing should include animal context.")
		return
	if not text.contains("自由安排"):
		_fail("Briefing should remind players the day is flexible.")
		return

	print("PASS briefing_manager_test")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
