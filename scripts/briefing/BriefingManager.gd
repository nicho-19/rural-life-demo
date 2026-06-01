extends RefCounted
class_name BriefingManager

func compose(day: int, weather_text: String, order_text: String, milestone_text: String, animal_text: String = "", npc_text: String = "") -> String:
	var lines: Array[String] = [
		"今日简报",
		"第 %d 天" % max(1, day),
		weather_text,
		order_text,
		milestone_text,
	]
	if not animal_text.strip_edges().is_empty():
		lines.append(animal_text)
	if not npc_text.strip_edges().is_empty():
		lines.append(npc_text)
	lines.append("建议：先看看农田、动物棚和背包，再自由安排今天。订单、图鉴和里程碑都只是参考。")
	if weather_text.contains("雨"):
		lines.append("雨天提示：已种下但没浇水的作物会得到雨水照顾。")
	return "\n".join(lines)
