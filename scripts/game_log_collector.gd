extends Logger
class_name GameLogCollector

# Кастомный логгер: буфер строк для копирования в буфер обмена из игры.
# Вызовы приходят с разных потоков — только Mutex и без print/push_error.

const _MAX_LINES := 5000

var _mutex: Mutex = Mutex.new()
var _lines: PackedStringArray = PackedStringArray()


func _log_message(message: String, error: bool) -> void:
	var prefix := "[stderr] " if error else ""
	_mutex.lock()
	_lines.append(prefix + message)
	_trim_if_needed()
	_mutex.unlock()


func _log_error(
	function: String,
	file: String,
	line: int,
	code: String,
	rationale: String,
	editor_notify: bool,
	error_type: int,
	script_backtraces: Array
) -> void:
	var parts: PackedStringArray = PackedStringArray()
	parts.append("[ERROR] %s" % rationale)
	parts.append("  at: %s (%s:%d)" % [function, file, line])
	if code != "":
		parts.append("  code: %s" % code)
	for bt in script_backtraces:
		parts.append("  trace: %s" % str(bt))
	_mutex.lock()
	_lines.append("\n".join(parts))
	_trim_if_needed()
	_mutex.unlock()


func take_snapshot_lines() -> PackedStringArray:
	_mutex.lock()
	var copy := _lines.duplicate()
	_mutex.unlock()
	return copy


func _trim_if_needed() -> void:
	while _lines.size() > _MAX_LINES:
		_lines.remove_at(0)
