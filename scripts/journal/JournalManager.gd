extends RefCounted
class_name JournalManager

const MAX_ENTRIES := 40

var entries: Array[Dictionary] = []

func add_entry(day: int, message: String) -> void:
	if message.strip_edges().is_empty():
		return
	entries.append({
		"day": max(1, day),
		"message": message,
	})
	while entries.size() > MAX_ENTRIES:
		entries.pop_front()


func describe_recent(limit: int = 8) -> String:
	if entries.is_empty():
		return "农场日记\n还没有记录。随便种点什么，日子就会写下来。"

	var lines: Array[String] = ["农场日记"]
	var start_index: int = max(0, entries.size() - limit)
	for index in range(start_index, entries.size()):
		var entry: Dictionary = entries[index]
		lines.append("第 %d 天：%s" % [int(entry.get("day", 1)), String(entry.get("message", ""))])
	return "\n".join(lines)


func to_save_data() -> Dictionary:
	return {
		"entries": entries.duplicate(true),
	}


func load_save_data(data: Dictionary) -> void:
	entries.clear()
	var saved = data.get("entries", [])
	if not saved is Array:
		return
	for entry in saved:
		if not entry is Dictionary:
			continue
		add_entry(int(entry.get("day", 1)), String(entry.get("message", "")))
