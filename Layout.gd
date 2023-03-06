extends HSplitContainer

const PANEL_POSITIONS = {
	TopLeft="SplitLeft/Left/Top",
	BottomLeft="SplitLeft/Left/Bottom",
	TopRight="SplitRight/Right/Top",
	BottomRight="SplitRight/Right/Bottom"
}
var PANELS = [
	{ index=0, name="Top Right", position="TopRight" },
	{ index=1, name="Bottom Right", position="BottomRight" },
	{ index=2, name="Top Left", position="TopLeft" },
	{ index=3, name="Bottom Left", position="BottomLeft" },
]
const HIDE_PANELS = {
	photo_editing=[],
}

var panels = {}
var previous_width : float
var current_mode : String = "photo_editing"

func _ready() -> void:
	previous_width = get_rect().size.x
	$SplitLeft.connect("dragged",_on_Left_dragged)
	$SplitRight.connect("dragged",_on_Right_dragged)

func toggle_side_panels() -> void:
	# Toggle side docks' visibility to maximize the space available
	# for the graph panel. This is useful on smaller displays.
	$SplitLeft/Left.visible = not $SplitLeft/Left.visible
	$SplitRight/Right.visible = not $SplitRight/Right.visible

func load_panels() -> void:
	# Create panels
	for panel_pos in PANEL_POSITIONS.keys():
		var index = 0
		for panel in PANELS:
			if panel.position == panel_pos:
				index = panel.index
		get_node(PANEL_POSITIONS[panel_pos]).window_button.select(index)
		panels[PANELS[index].name] = get_node(PANEL_POSITIONS[panel_pos])
	# Split positions
	await get_tree().process_frame 
	if mt_globals.config.has_section_key("layout", "VSplitOffset"):
		split_offset = mt_globals.config.get_value("layout", "VSplitOffset")
	if mt_globals.config.has_section_key("layout", "LeftVSplitOffset"):
		$SplitLeft.split_offset = mt_globals.config.get_value("layout", "LeftVSplitOffset")
	if mt_globals.config.has_section_key("layout", "LeftHSplitOffset"):
		$SplitLeft/Left.split_offset = mt_globals.config.get_value("layout", "LeftHSplitOffset")
	if mt_globals.config.has_section_key("layout", "RightVSplitOffset"):
		$SplitRight.split_offset = mt_globals.config.get_value("layout", "RightVSplitOffset")
	if mt_globals.config.has_section_key("layout", "RightHSplitOffset"):
		$SplitRight/Right.split_offset = mt_globals.config.get_value("layout", "RightHSplitOffset")

func save_config() -> void:
	mt_globals.config.set_value("layout", "VSplitOffset", split_offset)
	mt_globals.config.set_value("layout", "LeftVSplitOffset", $SplitLeft.split_offset)
	mt_globals.config.set_value("layout", "LeftHSplitOffset", $SplitLeft/Left.split_offset)
	mt_globals.config.set_value("layout", "RightVSplitOffset", $SplitRight.split_offset)
	mt_globals.config.set_value("layout", "RightHSplitOffset", $SplitRight/Right.split_offset)

func get_panel(n) -> Control:
	return panels[n]

func get_panel_list() -> Array:
	var panels_list = panels.keys()
	panels_list.sort()
	return panels_list

func is_panel_visible(panel_name : String) -> bool:
	return panels[panel_name] != null

func set_panel_visible(panel_name : String, v : bool) -> void:
	var panel = panels[panel_name]
	panel.set_meta("hidden", !v)

func change_mode(m : String) -> void:
	current_mode = m
	for p in panels:
		set_panel_visible(p, !panels[p].get_meta("hidden"))


func _on_Left_dragged(_offset : int) -> void:
	$SplitLeft/Left.clamp_split_offset()

func _on_Right_dragged(_offset : int) -> void:
	$SplitRight/Right.clamp_split_offset()

