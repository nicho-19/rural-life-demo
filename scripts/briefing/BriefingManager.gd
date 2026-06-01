extends RefCounted
class_name BriefingManager

func compose(day: int, weather_text: String, order_text: String, milestone_text: String) -> String:
	var lines: Array[String] = [
		"今日简报",
		"第 %d 天" % max(1, day),
		weather_text,
		order_text,
		milestone_text,
		"建议：先看看农田和背包，再自由安排今天。订单、图鉴和里程碑都只是参考。"
	]
	if weather_text.contains("雨"):
		lines.append("雨天提示：已种下但没浇水的作物会得到雨水照顾。")
	return "\n".join(lines)
