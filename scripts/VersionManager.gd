extends Node
## Singleton для управления версией проекта
##
## Автоматически определяет версию проекта на основе git-ветки:
## - В main: версия из файла VERSION
## - В feature-ветках: версия main + последние 5 символов имени ветки

var version: String = "0.1"
var branch: String = "unknown"

func _ready():
	_load_version()
	print("Elemental Blast версия: ", version)
	print("Git ветка: ", branch)

func _load_version():
	# Читаем VERSION файл (он всегда должен существовать)
	if FileAccess.file_exists("res://VERSION"):
		var file = FileAccess.open("res://VERSION", FileAccess.READ)
		if file:
			var base_version = file.get_as_text().strip_edges()
			file.close()
			
			# Пытаемся получить имя ветки через git
			var branch_output = []
			var branch_exit = OS.execute("git", ["rev-parse", "--abbrev-ref", "HEAD"], branch_output, true)
			if branch_exit == 0 and branch_output.size() > 0:
				branch = branch_output[0].strip_edges()
			
			# Если не в main, добавляем суффикс ветки
			if branch != "main" and branch != "unknown":
				var branch_suffix = branch.substr(max(0, branch.length() - 5))
				version = base_version + "." + branch_suffix
			else:
				version = base_version
		else:
			print("ОШИБКА: Не удалось открыть файл VERSION")
	else:
		print("ПРЕДУПРЕЖДЕНИЕ: Файл VERSION не найден, используется версия по умолчанию ", version)

func get_version() -> String:
	return version

func get_branch() -> String:
	return branch

func get_full_version_string() -> String:
	return "v" + version + " (" + branch + ")"
