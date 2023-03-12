extends Node

#
func Assert(condition : bool, message : String) -> void:
	if OS.is_debug_build() && not condition:
		printerr(message)
		push_warning(message)

func PrintLog(logGroup : String, logString : String):
	print("[%d.%04d][%s] %s" % [Time.get_ticks_msec() / 1000.0, Time.get_ticks_msec() % 1000, logGroup, logString])
