# This class is the Controler in the MVC
# The View is scene called ScBioDyn2.tscn
# The Model is the 3D scene

extends Node

var _listAgents:ItemList 
enum Prop {EMPTY, ENTITY, BEHAVIOR, GRID, ENV }

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Tree of entities
	_listAgents = find_node("ListAgents", true, true)
	
# **********************************************************
#                         AGENTS                           *
# **********************************************************
func addAgent(var name) -> void:	
	# Create new Agent in GUI -----------------------------
	var lst:ItemList = _listAgents
	lst.add_item(name)
	lst.set_item_metadata(lst.get_item_count()-1, "Agent") # type of the item
	
	# Create new Agent Type in 3D Scene -----------------------------
	var rb:RigidBody = create_rigid_body_agent(name)
	rb.visible = false
	var node_entities:Node = get_node("%Entities")

	#  - add the Agent to the scene
	node_entities.add_child(rb)
	rb.set_owner(get_node("%Simulator"))
	
func create_rigid_body_agent(var name:String) -> RigidBody:
	#  - material
	var mat:SpatialMaterial = SpatialMaterial.new()
	mat.albedo_color = Color(1.0, 0.0, 0.0, 1.0)
	#  - mesh
	var mh:MeshInstance = MeshInstance.new()
	mh.mesh = SphereMesh.new()
	mh.set_material_override(mat)
	#  - collision
	var col:CollisionShape = CollisionShape.new()
	col.shape = SphereShape.new()
	#  - rigidbody
	var rb:RigidBody = RigidBody.new()
	rb.name = name
	rb.set_gravity_scale(0)
	rb.set_collision_layer_bit(0,true)
	rb.set_collision_mask_bit(0,true)
	rb.contacts_reported = 1
	rb.contact_monitor = true
	
	rb.add_child(mh)
	rb.add_child(col)
	
	return rb

func clone_rigid_body_agent(var rb0:RigidBody) -> RigidBody:
	return rb0.duplicate() as RigidBody 	# warning : parameters are not cloned (same ref)
										# it's ok now, but could be wrong for some param by ref
	
# Add Agent -----------------------------
func _on_ToolPlusAgent_pressed() -> void:
	var name:String = key_name_create()
	#_selected_name = name
	addAgent(name)


# Remove Agent -----------------------------
func _on_BtnDelAgent_pressed() -> void:
	var lst:ItemList = _listAgents
	var sel:PoolIntArray = lst.get_selected_items()
	if sel.size() > 0:
		lst.remove_item(sel[0])

# List of entities -----------------------------
var _selected_name:String = ""
func _on_ListAgents_item_selected(index: int) -> void:
	var sel:PoolIntArray = _listAgents.get_selected_items()
	if sel.size() > 0:
		#_listAgents.remove_item(sel[0])
		var entity_name:String = _listAgents.get_item_text(sel[0])
		var entity:Node = get_entity_from_GUI(entity_name)
		var tabs:TabContainer = get_node("%TabContainer")
		if entity is RigidBody:
			tabs.current_tab = Prop.ENTITY
			_selected_name = entity_name
			_fill_properties_of_agent(entity)
		else:
			tabs = get_node("%TabContainer")	
			if entity is Node:
				tabs.current_tab = Prop.EMPTY
			
func get_entity_from_GUI(var name:String) -> Node:
	var node_entities:Node = get_node("%Entities")
	return node_entities.find_node(name) as Node

# Agent => Properties ----------------------------
func _fill_properties_of_agent(var entity:Node):
	if entity is RigidBody:
		# name
		var box_name:LineEdit = get_node("%AgentName")
		box_name.text = entity.name
		# color
		var box_color:ColorPickerButton = get_node("%ColorAgent")
		var mesh:MeshInstance = entity.get_child(0)
		box_color.color = mesh.material_override.albedo_color
		# type
		var opt_type:OptionButton = get_node("%OptionAgentType")
		opt_type.select(0)
		# param
		agent_meta_to_param()
		
# Properties => Agent -----------------------------
# Agent COLOR
func _on_ColorAgent_color_changed(color: Color) -> void:
	var rb:RigidBody = find_node(_selected_name)
	var msh:MeshInstance = rb.get_child(0)
	var mat:SpatialMaterial = msh.material_override
	mat.albedo_color = color
# Agent NAME
func _on_AgentName_focus_exited() -> void:
	var line_edit:LineEdit = get_node("%AgentName")
	var new_name:String = line_edit.text
	if new_name == _selected_name:
		return
	if key_name_exists(new_name) == false: # The new name doesn't exists => can be applied
		var sel:PoolIntArray = _listAgents.get_selected_items()
		if sel.size() == 0:
			return
		var pos = sel[0] # pos of agent in list
		_listAgents.set_item_text(pos, new_name) # set new name
		# 3D ENV	
		var rb:RigidBody = find_node(_selected_name) # change in ENV
		rb.name = new_name
		_selected_name = new_name
	else: # the new name EXISTS => cannot be changed
		OS.alert("Ce nom est deja attribue", "Information")
		line_edit.text = _selected_name
		
func _on_AgentName_text_entered(new_text: String) -> void:
	_on_AgentName_focus_exited()

# Agent PARAMETERS
func _on_ButtonAddParam_button_down() -> void:
	# Crete a unique name for the parameter (Meta names are key of dictionnary)
	var key_param:String  = key_param_create()
	# Create the line of input boxes
	var vbox_param:	VBoxContainer = get_node("%VBoxAgentParam")
	var hbox_line :	HBoxContainer = get_node("%HBoxLineParam")
	var new_line: 	HBoxContainer = hbox_line.duplicate()
	new_line.get_child(0).set_text(key_param)
	new_line.visible = true
	vbox_param.add_child(new_line)
	# Save to meta
	agent_param_to_meta()


func _on_Button_button_down() -> void:
	var vbox_param:	VBoxContainer = get_node("%VBoxAgentParam")
	for i in vbox_param.get_child_count():
		var line:HBoxContainer = vbox_param.get_child(i)
		var btn_del:Button = line.get_child(3)
		if btn_del.has_focus():
			vbox_param.remove_child(line)
			break
	# Save to meta (new_name VALIDATED)
	agent_param_to_meta()
	
func agent_meta_to_param() -> void:
	#printerr(str("meta => PARAM for ", _selected_name))
	var rb:RigidBody = find_node(_selected_name)
	if rb==null:
		return
	var vbox_param:	VBoxContainer = get_node("%VBoxAgentParam")
	# Clear Param VBox
	for i in vbox_param.get_child_count()-1:
		var line:HBoxContainer = vbox_param.get_child(1)
		vbox_param.remove_child(line)
		line.queue_free()
	# Fill Param VBox
	for m in rb.get_meta_list().size():
		var meta_name :String  	= rb.get_meta_list()[m]
		var meta_value			= rb.get_meta(meta_name)
		#printerr(str(_selected_name , " : meta => PARAM (", meta_name , "," , meta_value))
		_on_ButtonAddParam_button_down()
		var line:HBoxContainer = vbox_param.get_child(vbox_param.get_child_count()-1)
		line.get_child(0).set_text(meta_name)
		line.get_child(2).set_text(meta_value)
	
func agent_param_to_meta() -> void:
	#printerr(str("PARAM => meta for ", _selected_name))
	var rb:RigidBody = find_node(_selected_name)
	if rb==null:
		return
	# Clear Meta
	rb.get_meta_list().empty()
	var vbox_param:	VBoxContainer = get_node("%VBoxAgentParam")
	# Fill Meta
	for i in vbox_param.get_child_count()-1:
		var line:HBoxContainer = vbox_param.get_child(i+1)
		var param_name :String  	= line.get_child(0).get_text()
		var param_value			= line.get_child(2).get_text()
		rb.set_meta(param_name, param_value)
		#printerr(str(_selected_name , " : PARAM => meta (" , param_name , "," , param_value))
		#printerr("param => meta")
		#printerr(param_name)
		#printerr(param_value)


func _on_Btn_test_button_down() -> void:
	agent_param_to_meta()
	#agent_meta_to_param()

# ************************************************************
#                          ENVIRONMENT                       *
# ************************************************************

# On Mouse Click -----------------------------
func _on_ViewportContainer_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
			if event.pressed:
				if _selected_name == "":
					return
				# Position of the mouse click
				var camera = get_node("%Camera")
				var from = camera.project_ray_origin(event.position)
				var to = camera.project_ray_normal(event.position) * 100
				var cursorPos = Plane(Vector3.UP, 0).intersects_ray(from, to)
				#print(cursorPos)
				# Spawn the new entity
				var n_entities:Node = get_node("%Environment")
				var rb:RigidBody = find_node(_selected_name)
				var entity:RigidBody  = clone_rigid_body_agent(rb) #load("res://addons/NetBioDyn-2/3-Agents/Agent-Blue.tscn").instance()
				entity.visible = true
				entity.set_gravity_scale(0)
				n_entities.add_child(entity)
				entity.global_transform.origin = cursorPos  #Vector3(event.position.x-50,0,event.position.y-10)/10 #Vector3(get_parent().get_mouse_position().x,0,get_parent().get_mouse_position().y)/10
				# to be saved as scene, the owner is the simulation "root" node
				#   - see https://godotengine.org/qa/903/how-to-save-a-scene-at-run-time
				#   - see https://github.com/godotengine/godot-proposals/issues/390
				entity.set_owner(get_node("%Simulator"))
				pass

# Show relevant property TAB ------------------------------
func _on_Button_pressed() -> void:
	var tabs:TabContainer = get_node("%TabContainer")
	tabs.current_tab = Prop.ENV
	
# ************************************************************
#                          Behaviors                         *
# ************************************************************
func _on_BtnAddBehav_pressed() -> void:
	# Create new Agent in GUI --------------------------------
	var lst:ItemList = get_node("%ListBehav")
	lst.add_item("Comportement")
	lst.set_item_metadata(lst.get_item_count()-1, "Reaction") # type of the item
	
	# Create new Behavior Type in 3D Scene -------------------	
	var script:GDScript = GDScript.new()
	script.source_code = """
extends Node

func step(agent) -> void:
	var proba:float = 0.01
	if rand_range(0,100) < proba:
		#print("DEAD")
		agent.queue_free()
"""
	script.reload()

	var n:Node = Node.new()
	n.set_script(script) #load("res://addons/NetBioDyn-2/4-Behaviors/DeathTest.gd"))

	
	var node_behaviors:Node = get_node("%Behaviors")
	node_behaviors.add_child(n)

func _on_BtnDelBehav_pressed() -> void:
	var lst:ItemList = get_node("%ListBehav")
	var sel:PoolIntArray = lst.get_selected_items()
	if sel.size() > 0:
		lst.remove_item(sel[0])

func _on_ListBehav_item_selected(index: int) -> void:
	var tabs:TabContainer = get_node("%TabContainer")
	tabs.current_tab = Prop.BEHAVIOR
		
# ************************************************************
#                           Groups                           *
# ************************************************************
func _on_BtnAddGp_pressed() -> void:
	var lst:ItemList = get_node("%ListGp")
	lst.add_item("Groupe")
	lst.set_item_metadata(lst.get_item_count()-1, "Reaction") # type of the item

func _on_BtnDelGp_pressed() -> void:
	var lst:ItemList = get_node("%ListGp")
	var sel:PoolIntArray = lst.get_selected_items()
	if sel.size() > 0:
		lst.remove_item(sel[0])
# ************************************************************
#                              Grids                         *
# ************************************************************
func _on_BtnAddGrid_pressed() -> void:
	var lst:ItemList = get_node("%ListGrids")
	lst.add_item("Grille")
	lst.set_item_metadata(lst.get_item_count()-1, "Reaction") # type of the item

func _on_BtnDelGrid_pressed() -> void:
	var lst:ItemList = get_node("%ListGrids")
	var sel:PoolIntArray = lst.get_selected_items()
	if sel.size() > 0:
		lst.remove_item(sel[0])

func _on_ListGrids_item_selected(index: int) -> void:
	var tabs:TabContainer = get_node("%TabContainer")
	tabs.current_tab = Prop.GRID
	


# ************************************************************
#                           Utilities                        *
# ************************************************************

# Key name Generator --------------------------
func key_name_create() -> String:
	var prefix:String = "Agent-"
	var simu:Node = get_node("%Simulator")
	for n in 999999:
		var key_name:String = prefix + String(n)
		var exists:bool = key_name_exists(key_name)
		if exists == false:
			return key_name
	return "FULL"
	
func key_name_exists(var key_name:String) -> bool:
		var node:Node = find_node(key_name)
		if node == null:
			return false
		else:
			return true

func key_param_create() -> String:
	var prefix:String = "Param-"
	var vbox:VBoxContainer = get_node("%VBoxAgentParam")
	for n in 999999:
		var key_name:String = prefix + String(n)
		#printerr(str("Try to create param : ", key_name))
		var exists:int = key_param_exists(key_name)
		if exists == 0:
			return key_name
	return "FULL"

func key_param_exists(var key_name:String) -> int:
	var vbox:VBoxContainer = get_node("%VBoxAgentParam")
	var nb_param:float = vbox.get_child_count()
	#printerr(str("func key_param_exists => ", "nb_param=" , nb_param))
	#printerr(str("range=",range(1,nb_param)))
	var nb:int = 0
	for n in range(1,nb_param):
		#printerr(str("	n=",n))
		var line:HBoxContainer = vbox.get_child(n)
		var name:String = line.get_child(0).get_text()
		#printerr(str("Verify : ", key_name, " with existing :", name))
		if key_name == name:
			nb = nb+1
	return nb	

# Window / App control -------------------------
func _on_BtnClose_pressed():
	get_tree().quit()




# ************************************************
# WORK in PROGRESS...
# ************************************************

var _selected_param_pos:int = -1
var _selected_param_name:String = ""

# TODO : 

# get the line number of param having possibly the focus
func get_param_line_has_focus() -> int :
	var vbox_param:	VBoxContainer = get_node("%VBoxAgentParam")
	for i in vbox_param.get_child_count():
		var line:HBoxContainer = vbox_param.get_child(i)
		var param_edit:LineEdit = line.get_child(0)
		var value_edit:LineEdit = line.get_child(2)
		var btn_del:Button = line.get_child(3)
		if param_edit.has_focus() or value_edit.has_focus() or btn_del.has_focus():
			return i
	return -1

func _on_ParamName_focus_exited() -> void:
	# Verif Name if unique
	var vbox_param:	VBoxContainer = get_node("%VBoxAgentParam")
	var i:int = _selected_param_pos
	var line:HBoxContainer = vbox_param.get_child(i)
	var old_name:String = _selected_param_name
	var new_name:String = line.get_child(0).get_text()
	if old_name==new_name: # Name NOT changed
		return
	if key_param_exists(new_name) == 2: # Name already EXISTS
		OS.alert("Ce nom est deja attribue", "Information")
		line.get_child(0).set_text(old_name)
		return
	# Save to meta (new_name VALIDATED)
	agent_param_to_meta()

func _on_ParamValue_focus_exited() -> void:
	# Save to meta
	agent_param_to_meta()

func _on_ParamName_focus_entered() -> void:
	_selected_param_pos = get_param_line_has_focus()
	var vbox_param:	VBoxContainer = get_node("%VBoxAgentParam")
	var line:HBoxContainer = vbox_param.get_child(_selected_param_pos)
	_selected_param_name = line.get_child(0).get_text()


func _on_ParamName_text_entered(new_text: String) -> void:
	_on_ParamName_focus_exited()
