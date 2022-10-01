extends HSplitContainer

const PANEL_POSITIONS = {
	TopLeft="Left/Top",
	BottomLeft="Left/Bottom",
	TopRight="SplitRight/Right/Top",
	BottomRight="SplitRight/Right/Bottom"
}
var PANELS = [
	{ name="Tools", scene=preload("res://panels/tools/tools_panel.tscn"), position="TopLeft" },
#	{ name="Reference", scene=preload("res://panels/reference/reference_panel.tscn"), position="BottomLeft" },
	{ name="Layers", scene=preload("res://panels/layers/layers.tscn"), position="BottomRight" },
]
const HIDE_PANELS = {
	photo_editing=[],
}

var panels = {}
var previous_width : float
var current_mode : String = "photo_editing"

func _ready() -> void:
	previous_width = get_rect().size.x

func toggle_side_panels() -> void:
	# Toggle side docks' visibility to maximize the space available
	# for the graph panel. This is useful on smaller displays.
	$Left.visible = not $Left.visible
	$SplitRight/Right.visible = not $SplitRight/Right.visible

func load_panels() -> void:
	# Create panels
	for panel_pos in PANEL_POSITIONS.keys():
		get_node(PANEL_POSITIONS[panel_pos]).set_tabs_rearrange_group(1)
	for panel in PANELS:
		var node : Node = panel.scene.instantiate()
		node.name = panel.name
		if panel.has("parameters"):
			for p in panel.parameters.keys():
				node.set(p, panel.parameters[p])
		panels[panel.name] = node
		var tab = get_node(PANEL_POSITIONS[panel.position])
		var config_panel_name = panel.name.replace(" ", "_").replace("(", "_").replace(")", "_")
		if mt_globals.config.has_section_key("layout", config_panel_name+"_location"):
			tab = get_node(PANEL_POSITIONS[mt_globals.config.get_value("layout", config_panel_name+"_location")])
		if mt_globals.config.has_section_key("layout", config_panel_name+"_hidden") && mt_globals.config.get_value("layout", config_panel_name+"_hidden"):
			node.set_meta("parent_tab_container", tab)
			node.set_meta("hidden", true)
		else:
			tab.add_child(node)
			node.set_meta("hidden", false)
	# Split positions
	await get_tree().process_frame 
	if mt_globals.config.has_section_key("layout", "LeftVSplitOffset"):
		split_offset = mt_globals.config.get_value("layout", "LeftVSplitOffset")
	if mt_globals.config.has_section_key("layout", "LeftHSplitOffset"):
		$Left.split_offset = mt_globals.config.get_value("layout", "LeftHSplitOffset")
	if mt_globals.config.has_section_key("layout", "RightVSplitOffset"):
		$SplitRight.split_offset = mt_globals.config.get_value("layout", "RightVSplitOffset")
	if mt_globals.config.has_section_key("layout", "RightHSplitOffset"):
		$SplitRight/Right.split_offset = mt_globals.config.get_value("layout", "RightHSplitOffset")

func save_config() -> void:
	for p in panels:
		var config_panel_name = p.replace(" ", "_").replace("(", "_").replace(")", "_")
		var location = panels[p].get_parent()
		var hidden = false
		if location == null:
			hidden = panels[p].get_meta("hidden")
			location = panels[p].get_meta("parent_tab_container")
		mt_globals.config.set_value("layout", config_panel_name+"_hidden", hidden)
		for l in PANEL_POSITIONS.keys():
			if location == get_node(PANEL_POSITIONS[l]):
				mt_globals.config.set_value("layout", config_panel_name+"_location", l)
	mt_globals.config.set_value("layout", "LeftVSplitOffset", split_offset)
	mt_globals.config.set_value("layout", "LeftHSplitOffset", $Left.split_offset)
	mt_globals.config.set_value("layout", "RightVSplitOffset", $SplitRight.split_offset)
	mt_globals.config.set_value("layout", "RightHSplitOffset", $SplitRight/Right.split_offset)

func get_panel(n) -> Control:
	return panels[n]

func get_panel_list() -> Array:
	var panels_list = panels.keys()
	panels_list.sort()
	return panels_list

func is_panel_visible(panel_name : String) -> bool:
	return panels[panel_name].get_parent() != null

func set_panel_visible(panel_name : String, v : bool) -> void:
	var panel = panels[panel_name]
	panel.set_meta("hidden", !v)
	if panel.is_inside_tree():
		panel.set_meta("parent_tab_container", panel.get_parent())
	if v and HIDE_PANELS[current_mode].find(panel_name) == -1:
		if ! panel.is_inside_tree():
			panel.get_meta("parent_tab_container").add_child(panel)
	elif panel.is_inside_tree():
		panel.get_parent().remove_child(panel)
	update_panels()

func change_mode(m : String) -> void:
	current_mode = m
	for p in panels:
		set_panel_visible(p, !panels[p].get_meta("hidden"))
	update_panels()

func update_panels() -> void:
	var left_width = $Left.get_rect().size.x
	var left_requested = left_width
	var right_width = $SplitRight/Right.get_rect().size.x
	var right_requested = right_width
	if $Left/Top.get_tab_count() == 0:
		if $Left/Bottom.get_tab_count() == 0:
			left_requested = 10
			$Left.split_offset -= ($Left/Top.get_rect().size.y-$Left/Bottom.get_rect().size.y)/2
			$Left.clamp_split_offset()
		else:
			$Left.split_offset -= $Left/Top.get_rect().size.y-10
			$Left.clamp_split_offset()
	elif $Left/Bottom.get_tab_count() == 0:
		$Left.split_offset += $Left/Bottom.get_rect().size.y-10
		$Left.clamp_split_offset()
	if $SplitRight/Right/Top.get_tab_count() == 0:
		if $SplitRight/Right/Bottom.get_tab_count() == 0:
			right_requested = 10
			$SplitRight/Right.split_offset -= ($SplitRight/Right/Top.get_rect().size.y-$SplitRight/Right/Bottom.get_rect().size.y)/2
			$SplitRight/Right.clamp_split_offset()
		else:
			$SplitRight/Right.split_offset -= $SplitRight/Right/Top.get_rect().size.y-10
			$SplitRight/Right.clamp_split_offset()
	elif $SplitRight/Right/Bottom.get_tab_count() == 0:
		$SplitRight/Right.split_offset += $SplitRight/Right/Bottom.get_rect().size.y-10
		$SplitRight/Right.clamp_split_offset()
	split_offset += left_requested - left_width + right_requested - right_width
	clamp_split_offset()
	$SplitRight.split_offset += right_width - right_requested

func _on_Left_dragged(_offset : int) -> void:
	$Left.clamp_split_offset()

func _on_Right_dragged(_offset : int) -> void:
	$SplitRight/Right.clamp_split_offset()

func _on_tab_changed(_tab):
	update_panels()

func _on_Layout_resized():
# warning-ignore:narrowing_conversion
	split_offset -= get_rect().size.x - previous_width
	previous_width = get_rect().size.x
