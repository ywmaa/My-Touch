@tool
#class_name
extends Control

## Main UI of the addon

## Preloading section.tscn into a PackedScene ready to be instantiated
const SectionUI := preload("res://addons/godot_style/section_ui.tscn")

## Preloading markdown_implementation.gd as a helper
## (to keep codes seperate and relevant)
const Markdown := preload("res://addons/godot_style/markdown/markdown_implementation.gd")

## Passing Godot's SyntaxHighlighter to markdown_helper
var gdscript_syntax_highlighter: SyntaxHighlighter:
	set(value):
		gdscript_syntax_highlighter = value
		if markdown_helper:
			markdown_helper.gdscript_syntax_highlighter = gdscript_syntax_highlighter

## Sections of type SectionResource to be displayed
@export var sections: Array[SectionResource]

@onready var sections_container: VBoxContainer = $HBoxContainer/NavigationTrees/SectionsContainer
@onready var markdown_helper := Markdown.new()

func _ready() -> void:
	# Adding sections to container
	for section in sections:
		if not section:
			push_warning("Godot Style: Empty SectionResource")
			continue
		
		var section_ui := SectionUI.instantiate()
		sections_container.add_child(section_ui) ## Ensuring tree is ready
		
		section_ui.tree.item_selected.connect(
			_on_SectionUI_Tree_item_selected.bind(section_ui.tree)
			# Pass in the corresponding Tree to have access to the correct selected item
		)
		
		section_ui.tree.add_to_group("trees")
		section_ui.display(section)
		
	# Selecting the first item in first run
	var first_section_ui := sections_container.get_child(0)
	if not first_section_ui:
		push_warning("Godot Style: Cannot find any SectionUI")
		return
	
	first_section_ui.tree.set_selected(
		first_section_ui.tree.get_root().get_first_child(),
		0
	)
	return


func _on_SectionUI_Tree_item_selected(tree: Tree) -> void:
	var selected_tree_item: TreeItem = tree.get_selected()
	var item: ItemResource = selected_tree_item.get_metadata(0) # This was set in the display() function
	
	# De-selecting items in other trees
	for tr in get_tree().get_nodes_in_group("trees"):
		if tr == tree:
			continue
		tr.deselect_all()
	
	# Setting content title
	if item.content_title:
		%ItemName.text = item.content_title
	else:
		%ItemName.text = ""
	
	# Deleting existing contents
	for child in %Contents.get_children():
		%Contents.remove_child(child)
		child.queue_free()
		
	# Doesn't need to remove %Content yet
	
	# Adding Content of type file_path
	var viewer := markdown_helper.create_text_file_viewer(item.content_path)
	if viewer:
		%Contents.add_child(viewer)
	return
