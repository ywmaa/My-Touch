extends Control


var start_time : int = 0

var auto : bool = true
var fast_counter : int = 0


func _ready() -> void:
	# GPU RAM tooltip
	$GpuRam.tooltip_text = "Adapter: %s\nVendor: %s" % [ RenderingServer.get_video_adapter_name(), RenderingServer.get_video_adapter_vendor() ]

func e3tok(value : float) -> String:
	var unit_modifier : String = ""
	if value > 100000000:
		value *= 0.000000001
		unit_modifier = "G"
	elif value > 100000:
		value *= 0.000001
		unit_modifier = "M"
	elif value > 100:
		value *= 0.001
		unit_modifier = "k"
	return "%.1f %sb " % [ value, unit_modifier ]

func _process(_delta):
	var fps : float = Performance.get_monitor(Performance.TIME_FPS)
	$FpsCounter.text = "%.1f FPS " % fps
	if auto:
		if fps > 50.0:
			fast_counter += 1
			if fast_counter > 5:
				pass
				# high performance, do more calculations
		else:
			fast_counter = 0
			if fps < 20.0:
				pass
				# low performance, reduce calculations

func _on_MemUpdateTimer_timeout():
	$GpuRam.text = e3tok(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED))
	var tooltip : String = "Adapter: %s\nVendor: %s" % [ RenderingServer.get_video_adapter_name(), RenderingServer.get_video_adapter_vendor() ]
	tooltip += "\nVideo mem.: "+e3tok(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED))
	tooltip += "\nTexture mem.: "+e3tok(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED))
	# todo tooltip += "\nVertex mem.: "+e3tok(Performance.get_monitor(Performance.RENDER_VERTEX_MEM_USED))
	$GpuRam.tooltip_text = tooltip


