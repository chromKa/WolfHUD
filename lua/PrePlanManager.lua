-- TODO:
-- 	Maybe colorization for save, on which assets would get added/removed or stay. (seems to be not possible...?)
-- 	Show and save default votes 

requiredScript = string.lower(RequiredScript)
if requiredScript == "lib/managers/menumanager" then
	local modifiy_node_preplanning_original = MenuPrePlanningInitiator.modifiy_node_preplanning

	function MenuPrePlanningInitiator:modifiy_node_preplanning(node, ...)
		-- Create Saved Plans node
		local open_menus = managers.menu and managers.menu._open_menus
		local active_menu = open_menus and open_menus[#open_menus]
		local pp_nodes = active_menu.logic and active_menu.logic._data._nodes
		if pp_nodes and not pp_nodes[PrePlanningManager.saved_plans_node] then
			local arugements = {
				_meta = "node",
				back_callback = "stop_preplanning_post_event",
				gui_class = "MenuNodePrePlanningGui",
				menu_components = "preplanning_map preplanning_chats",
				modifier = "MenuPrePlanningInitiator",
				name = PrePlanningManager.saved_plans_node,
				no_menu_wrapper = true,
				refresh = "MenuPrePlanningInitiator",
			}
			
			local node_class = CoreSerialize.string_to_classtable("MenuNodeTable")
			if node_class then
				pp_nodes[PrePlanningManager.saved_plans_node]  = node_class:new(arugements)
			end
			
			
			local callback_handler = CoreSerialize.string_to_classtable("MenuCallbackHandler")
			pp_nodes[PrePlanningManager.saved_plans_node]:set_callback_handler(callback_handler:new())
		end
		
		
		local return_values = { modifiy_node_preplanning_original(self, node, ...) }
		local new_node = table.remove(return_values, 1)
						
		-- Insert dividers
		self:create_divider(node, "end_regular_menu", nil, 16, nil)
		self:create_divider(node, "title_preplanning_manager", managers.localization:text("wolfhud_preplanning_manager_title"), nil, tweak_data.screen_colors.text)
		
		local item_data = {
			type = "CoreMenuItem.Item",
		}
		
		--Create custom Buttons
		local save_params = {
			name = "save_preplanning",
			text_id = "wolfhud_preplanning_save",
			callback = "save_preplanning",
			tooltip = {
				name = managers.localization:text("wolfhud_preplanning_save_tooltip_title"),
				desc = managers.localization:text("wolfhud_preplanning_save_tooltip_desc"),
				texture = "guis/textures/icon_saving",
--				texture_rect = {0, 0, 32, 32},
				errors = {},
			},
		}
		
		local load_params = {
			name = "load_preplanning",
			text_id = "wolfhud_preplanning_load",
			callback = "set_load_mode",
			next_node = PrePlanningManager.saved_plans_node,
			tooltip = {
				name = managers.localization:text("wolfhud_preplanning_load_tooltip_title"),
				desc = managers.localization:text("wolfhud_preplanning_load_tooltip_desc"),
				texture = "guis/textures/icon_loading",
--				texture_rect = {0, 0, 32, 32},
				errors = {},
			},
		}
		
		local delete_params = {
			name = "delete_preplanning",
			text_id = "wolfhud_preplanning_delete",
			callback = "set_delete_mode",
			next_node = PrePlanningManager.saved_plans_node,
			tooltip = {
				name = managers.localization:text("wolfhud_preplanning_delete_tooltip_title"),
				desc = managers.localization:text("wolfhud_preplanning_delete_tooltip_desc"),
				texture = "guis/dlcs/big_bank/textures/pd2/pre_planning/drawtools_atlas",
				texture_rect = {2, 0, 29, 29},
				errors = {},
			},
		}
		
		local reset_params = {
			name = "reset_preplanning",
			text_id = "wolfhud_preplanning_reset",
			callback = "reset_preplanning",
			tooltip = {
				name = managers.localization:text("wolfhud_preplanning_reset_tooltip_title"),
				desc = managers.localization:text("wolfhud_preplanning_reset_tooltip_desc"),
				texture = "guis/dlcs/big_bank/textures/pd2/pre_planning/drawtools_atlas",
				texture_rect = {30, 0, 29, 29},
				errors = {},
			},
		}
		
		local reset_all_params = {
			name = "full_reset_preplanning",
			text_id = "wolfhud_preplanning_reset_all",
			callback = "full_reset_preplanning",
			tooltip = {
				name = managers.localization:text("wolfhud_preplanning_reset_all_tooltip_title"),
				desc = managers.localization:text("wolfhud_preplanning_reset_all_tooltip_desc"),
				texture = "guis/dlcs/big_bank/textures/pd2/pre_planning/drawtools_atlas",
				texture_rect = {30, 0, 29, 29},
				errors = {},
			},
		}
		
		local save_item = new_node:create_item(item_data, save_params)
		new_node:add_item(save_item)
		
		
		local load_item = new_node:create_item(item_data, load_params)
		new_node:add_item(load_item)
		local delete_item = new_node:create_item(item_data, delete_params)
		new_node:add_item(delete_item)
		
		local reset_item = new_node:create_item(item_data, reset_params)
		new_node:add_item(reset_item)
		
		if Network:is_server() and not Global.game_settings.single_player then
			local reset_all_item = new_node:create_item(item_data, reset_all_params)
			new_node:add_item(reset_all_item)
		end
		
		return new_node, unpack(return_values)
	end
	
	function MenuPrePlanningInitiator:modifiy_node_preplanning_saved_plans(node, item_name, selected_item)
		local saved_plans = PrePlanningManager.get_saved_plans()
		
		if table.size(saved_plans) <= 0 then
			self:create_divider(node, "title_category_saved_plans", managers.localization:text("wolfhud_preplanning_error_no_saved_plans"), nil, tweak_data.screen_colors.text)
			selected_item = ""
		else
			if PrePlanningManager._PREPLANNING_DELETE_MODE then
				self:create_divider(node, "title_category_saved_plans", managers.localization:text("wolfhud_preplanning_delete"), nil, tweak_data.screen_colors.text)
			else
				self:create_divider(node, "title_category_saved_plans", managers.localization:text("wolfhud_preplanning_load"), nil, tweak_data.screen_colors.text)
			end
			
			for name, data in pairs(saved_plans) do			
				local item = node:item(name)
				if not item then
					local item_data = {
						type = "CoreMenuItem.Item",
					}
				
					local params = {
						name = name,
						text_id = name,
						localize = false,
						callback = "saved_plan_clbk",
						tooltip = {
							name = name,
							desc = managers.preplanning and managers.preplanning:saved_assets_name(name),
							texture = "guis/textures/pd2/feature_crimenet_heat"
						},
						enabled = true
					}
					
					local plan_item = node:create_item(item_data, params)
					node:add_item(plan_item)
					
					selected_item = selected_item or params.name
				end
			end
			
			table.sort(node:items(), function (a, b)
				if a._type == "divider" then
					return true
				elseif b._type == "divider" then
					return false
				end
				return tostring(a:parameters().name):upper() < tostring(b:parameters().name):upper()
			end)
		end
		
		return node, selected_item
	end
		
	function MenuCallbackHandler:save_preplanning(item)
		if managers.preplanning then
			managers.preplanning:save_preplanning()
		end
	end
	
	function MenuCallbackHandler:reset_preplanning(item)
		if managers.preplanning then
			managers.preplanning:reset_preplanning()
		end
	end
	
	function MenuCallbackHandler:full_reset_preplanning(item)
		if managers.preplanning then
			managers.preplanning:reset_preplanning(true)
		end
	end
	
	function MenuCallbackHandler:set_load_mode(item)
		PrePlanningManager._PREPLANNING_DELETE_MODE = false
	end
	
	function MenuCallbackHandler:set_delete_mode(item)
		PrePlanningManager._PREPLANNING_DELETE_MODE = true
	end
	
	function MenuCallbackHandler:saved_plan_clbk(item)
		local params = item:parameters()
		local plan_name = params.name or ""
		if managers.preplanning then
			if PrePlanningManager._PREPLANNING_DELETE_MODE then
				managers.preplanning:delete_preplanning(plan_name)
			else
				managers.preplanning:load_preplanning(plan_name)
			end
		end
	end
	
elseif requiredScript == "lib/managers/preplanningmanager" then
	
	if not PrePlanningManager._PREPLANNING_SETUP then
		PrePlanningManager._SAVE_FOLDER = SavePath .. "/Preplanned/"
		PrePlanningManager._SAVE_FILE = PrePlanningManager._SAVE_FOLDER .. "Unknown.json"
		PrePlanningManager._SAVED_PLANS = {}
		PrePlanningManager.saved_plans_node = "preplanning_saved_plans"
		PrePlanningManager._PREPLANNING_DELETE_MODE = false
		PrePlanningManager._PREPLANNING_MAX_PLANS = WolfHUD and WolfHUD:getTweakEntry("MAX_PRE_PLANS", "number", 10) or 10
		PrePlanningManager._DEFAULT_PLAN_NAMES = { "Alfa", "Bravo", "Charlie", "Delta", "Echo", "Foxtrott", "Golf", "Hotel", "India", "Juliett", "Kilo", "Lima", "Mike", "November", "Oscar"}
		
		function PrePlanningManager.load_plans()
			local file = io.open(PrePlanningManager._SAVE_FILE, "r")
			if file then
				PrePlanningManager._SAVED_PLANS = json.decode(file:read("*all"))
				file:close()
			end
		end
		
		function PrePlanningManager.has_saved_plans()
			return (table.size(PrePlanningManager._SAVED_PLANS) > 0)
		end
		
		function PrePlanningManager.has_free_save_slot()
			return (table.size(PrePlanningManager._SAVED_PLANS) < PrePlanningManager._PREPLANNING_MAX_PLANS)
		end
		
		function PrePlanningManager.has_current_plan()
			if managers.preplanning then
				local peer_id = managers.network:session() and managers.network:session():local_peer():id()
				local current_assets, current_votes = managers.preplanning._reserved_mission_elements or {}, peer_id and managers.preplanning:get_player_votes(peer_id) or {}
				return (table.size(current_assets) > 0) or (table.size(current_votes) >0)
			end
			return false
		end

		function PrePlanningManager.save_plans()
			if not file.DirectoryExists("./" .. PrePlanningManager._SAVE_FOLDER) then
				WolfHUD:print_log("[WolfHUD] Preplanned folder '" .. PrePlanningManager._SAVE_FOLDER .. "' is missing!", "warning")
				if SystemFS then
					SystemFS:make_dir("./" .. PrePlanningManager._SAVE_FOLDER)
				end
			end
			local file = io.open(PrePlanningManager._SAVE_FILE, "w+")
			if file then
				local tbl_str = "{}"
				if table.size(PrePlanningManager._SAVED_PLANS) > 0 then
					tbl_str = json.encode(PrePlanningManager._SAVED_PLANS)
				end
				file:write(tbl_str)
				file:close()
			end
		end
		
		function PrePlanningManager.get_saved_plans()
			return PrePlanningManager._SAVED_PLANS
		end
		
		PrePlanningManager._PREPLANNING_SETUP = true
	end
	
	local post_init_original = PrePlanningManager.init
	
	function PrePlanningManager:init(...)
		PrePlanningManager._SAVE_FILE = string.format("%s%s.json", PrePlanningManager._SAVE_FOLDER, managers.job and string.format("%s_%s", managers.job:current_real_job_id() or "Unknown", managers.job:current_level_id() or "Unknown") or "Unknown")
		PrePlanningManager.load_plans()
		return post_init_original(self, ...)
	end
	
	function PrePlanningManager:save_preplanning()
		if not PrePlanningManager.has_free_save_slot() then
			managers.preplanning:notify_user("wolfhud_preplanning_msg_no_save_slot", {}, true)
		elseif not PrePlanningManager.has_current_plan() then
			managers.preplanning:notify_user("wolfhud_preplanning_msg_no_current_plan", {}, true)
		else
			
			local default_name = ""
			for i = 1, #PrePlanningManager._DEFAULT_PLAN_NAMES do
				local name = PrePlanningManager._DEFAULT_PLAN_NAMES[i]
				if not PrePlanningManager._SAVED_PLANS[name] then
					default_name = name
					break
				end
			end
			
			local menu_options = {
				[1] = {
					text = managers.localization:text("wolfhud_dialog_save"),
					callback = function(cb_data, button_id, button, text)
						if managers.preplanning then
							managers.preplanning:save_preplanning_clbk(text)
						end
					end,
				},
				[2] = {
					text = managers.localization:text("dialog_cancel"),
					is_cancel_button = true,
				}
			}
			local plan_str = managers.preplanning and managers.preplanning:current_assets_name() or ""
			QuickInputMenu:new(managers.localization:text("wolfhud_preplanning_dialog_save"), managers.localization:text("wolfhud_preplanning_dialog_save_desc", {PLAN = plan_str}), default_name, menu_options, true)
		end
	end
		
	function PrePlanningManager:save_preplanning_clbk(name)
		self.input_gui_active = nil
		if name and name ~= "" then
			local peer_id = managers.network and managers.network:session():local_peer():id()
			
			local bought_assets = self._reserved_mission_elements
			local votes = self:get_player_votes(peer_id) or {}
			local default_votes = self:get_default_votes() or {}
			local saved_assets, saved_votes = {}, {}
			
			for element_id, mission_element in pairs(bought_assets) do
				if mission_element.peer_id == peer_id then
					element_type, element_index = unpack(mission_element.pack)
					table.insert(saved_assets, { id = element_id, type = element_type, index = element_index })
				end
			end
			
			for plan, data in pairs(votes) do
				element_type, element_index = unpack(data)
				table.insert(saved_votes, { id = self:get_mission_element_id(element_type, element_index), type = element_type, index = element_index })
				default_votes[plan] = nil
			end
			
			for plan, data in pairs(default_votes) do
				element_type, element_index = unpack(data)
				table.insert(saved_votes, { id = self:get_mission_element_id(element_type, element_index), type = element_type, index = element_index })
			end
			
			local preplanning_data = {
				assets = #saved_assets > 0 and saved_assets or nil,
				votes = #saved_votes > 0 and saved_votes or nil,
			}
			PrePlanningManager._SAVED_PLANS[name] = (preplanning_data.assets or preplanning_data.votes) and preplanning_data or nil
			PrePlanningManager.save_plans()
			
			managers.preplanning:notify_user("wolfhud_preplanning_msg_saved_success", {}, false)
		end
	end
	
	function PrePlanningManager:load_preplanning(name)
		if PrePlanningManager._SAVED_PLANS[name] then
			local saved_assets = PrePlanningManager._SAVED_PLANS[name].assets or {}
			local saved_votes = PrePlanningManager._SAVED_PLANS[name].votes or {}
			
			local missing_skill, missing_favours, missing_money = false, false, false
			for i, data in ipairs(saved_assets) do
				local lockData = tweak_data:get_raw_value("preplanning", "types", data.type, "upgrade_lock") or false
				if not lockData or managers.player:has_category_upgrade(lockData.category, lockData.upgrade) then
					local money_cost = self:_get_type_cost(data.type)
					local favours_cost = self:get_type_budget_cost(data.type, 0)
					local current_budget, total_budget = self:get_current_budget()
					if current_budget + favours_cost < total_budget then
						if managers.money:can_afford_preplanning_type(type) then
							self:reserve_mission_element(data.type, data.id)
						else
							missing_money = true
						end
					else
						missing_favours = true
					end
				else
					missing_skill = true
				end
			end
			
			for i, data in ipairs(saved_votes) do
				self:vote_on_plan(data.type, data.id)
			end
		end
		if not (missing_skill or missing_favours or missing_money) then
			managers.preplanning:notify_user("wolfhud_preplanning_msg_loaded_success", {}, false)
		else
			local error_msg = ""
			if missing_skill then
				error_msg = managers.localization:text("wolfhud_preplanning_msg_loaded_missing_skill")
			end
			if missing_favours then
				error_msg = string.format("%s%s %s", error_msg, (missing_skill and ";" or ""), managers.localization:text("wolfhud_preplanning_msg_loaded_missing_favours"))
			end
			if missing_money then
				error_msg = string.format("%s%s %s", error_msg, ((missing_skill or missing_favours) and ";" or ""), managers.localization:text("wolfhud_preplanning_msg_loaded_missing_money"))
			end
			managers.preplanning:notify_user("wolfhud_preplanning_msg_loaded_partitially", {ERRORMSG = error_msg}, true)
		end
	end
	
	function PrePlanningManager:reset_preplanning(full_reset)
		if not PrePlanningManager.has_current_plan() then
			managers.preplanning:notify_user("wolfhud_preplanning_msg_no_current_plan", {}, true)
		else
			local peer_id = managers.network and managers.network:session():local_peer():id()
			
			local bought_assets = self._reserved_mission_elements or {}
			local votes = self:get_player_votes(peer_id) or {}
			
			for element_id, mission_element in pairs(bought_assets) do
				if (full_reset and PrePlanningManager.server_master_planner) or mission_element.peer_id == peer_id then
					self:unreserve_mission_element(element_id)
				end
			end
			
			for plan, data in pairs(votes) do
				local location_data = self:_current_location_data()
				local default_plan = plan and location_data and location_data.default_plans and location_data.default_plans[plan]
				local default_element = self:get_default_plan_mission_element(default_plan)
				if default_plan and default_element then
					self:vote_on_plan(default_plan, default_element:id())
				end
			end
			
			managers.preplanning:notify_user("wolfhud_preplanning_msg_reseted_success", {}, true)
		end
	end
	
	function PrePlanningManager:delete_preplanning(name)
		local menu_options = {
			[1] = {
				text = managers.localization:text("dialog_yes"),
				callback = function(self, item)
					managers.preplanning:delete_preplanning_clbk(name)
					
					local open_menus = managers.menu and managers.menu._open_menus
					local active_menu = open_menus and open_menus[#open_menus]
					if active_menu and active_menu.logic and active_menu.logic then
						active_menu.logic:refresh_node(active_menu.logic:selected_node())
					end
				end,
			},
			[2] = {
				text = managers.localization:text("dialog_no"),
				is_cancel_button = true,
			}
		}
		QuickMenu:new( managers.localization:text("wolfhud_preplanning_dialog_delete"), managers.localization:text("wolfhud_preplanning_dialog_delete_desc", {NAME = name}), menu_options, true )
	end
	
	function PrePlanningManager:delete_preplanning_clbk(name)	
		if PrePlanningManager._SAVED_PLANS[name] then
			PrePlanningManager._SAVED_PLANS[name] = nil
			PrePlanningManager.save_plans()
			
			managers.preplanning:notify_user("wolfhud_preplanning_msg_deleted_success", {}, false)
		else
			managers.preplanning:notify_user("wolfhud_preplanning_msg_deleted_failed", {}, true)
		end
	end
	
	function PrePlanningManager:current_assets_name()
		local text = ""
		
		local peer_id = managers.network and managers.network:session():local_peer():id()
		local current_assets, current_votes, default_votes = self._reserved_mission_elements or {}, self:get_player_votes(peer_id) or {}, self:get_default_votes() or {}
		
		text = string.format("%s%s\n", text, managers.localization:text("wolfhud_preplanning_votes_title"))
		for plan, data in pairs(current_votes) do
			element_type, element_index = unpack(data)
			local plan_data = tweak_data and tweak_data.preplanning.types[element_type]
			local plan_name = plan_data and plan_data.name_id and managers.localization:text(plan_data.name_id) or ""
			text = string.format("%s - %s", text, plan_name)
			local element = self._mission_elements_by_type[element_type] and self._mission_elements_by_type[element_type][element_index]
			if element then
				text = string.format("%s (%s)\n", text, self:get_element_name(element))
			else
				text = string.format("%s\n", text)
			end
			default_votes[plan] = nil
		end
		
		for plan, data in pairs(default_votes) do
			element_type, element_index = unpack(data)
			local plan_data = tweak_data and tweak_data.preplanning.types[element_type]
			local plan_name = plan_data and plan_data.name_id and managers.localization:text(plan_data.name_id) or ""
			text = string.format("%s - %s", text, plan_name)
			local element = self._mission_elements_by_type[element_type] and self._mission_elements_by_type[element_type][element_index]
			local element_name = element and self:get_element_name(element)
			if element_name and not element_name:lower():find("error") and not plan_data.pos_not_important then
				text = string.format("%s (%s)\n", text, element_name)
			else
				text = string.format("%s\n", text)
			end
			default_votes[plan] = nil
		end
		
		text = string.format("%s\n%s\n", text, managers.localization:text("wolfhud_preplanning_assets_title"))
		for id, mission_element in pairs(current_assets) do
			if mission_element.peer_id == peer_id then
				element_type, index = unpack(mission_element.pack)
				local type_name = self:get_type_name(element_type)
				text = string.format("%s - %s", text, type_name)
				local element = self._mission_elements_by_type[element_type] and self._mission_elements_by_type[element_type][index]
				local element_name = element and self:get_element_name(element)
				if element_name and not element_name:lower():find("error") then
					text = string.format("%s (%s)\n", text, element_name)
				else
					text = string.format("%s\n", text)
				end
			end
		end
		
		local money_str = managers.experience:cash_string(self:get_reserved_local_cost())
		local favours_amnt = self:get_current_budget()
		text = string.format("%s%s", text, managers.localization:text("menu_pp_tooltip_costs", {money = money_str, budget = favours_amnt}))
		
		return text
	end
	
	function PrePlanningManager:saved_assets_name(plan_name)
		local text = ""
		
		if PrePlanningManager._SAVED_PLANS[plan_name] then
			local saved_assets, saved_votes = PrePlanningManager._SAVED_PLANS[plan_name].assets or {}, PrePlanningManager._SAVED_PLANS[plan_name].votes or {}
				
			text = string.format("%s%s\n", text, managers.localization:text("wolfhud_preplanning_votes_title"))
			for i, data in pairs(saved_votes) do
				local plan_data = tweak_data and tweak_data.preplanning.types[data.type]
				local plan_name = plan_data and plan_data.name_id and managers.localization:text(plan_data.name_id) or ""
				text = string.format("%s - %s", text, plan_name)
				local element = self._mission_elements_by_type[element_type] and self._mission_elements_by_type[data.type][data.index]
				local element_name = element and self:get_element_name(element)
				if element_name and not element_name:lower():find("error") and not plan_data.pos_not_important then
					text = string.format("%s (%s)\n", text, element_name)
				else
					text = string.format("%s\n", text)
				end
			end
			
			text = string.format("%s\n%s\n", text, managers.localization:text("wolfhud_preplanning_assets_title"))
			for id, mission_element in pairs(saved_assets) do
				local type_name = self:get_type_name(mission_element.type)
				text = string.format("%s - %s", text, type_name)
				local element = self._mission_elements_by_type[mission_element.type][mission_element.index]
				local element_name = element and self:get_element_name(element)
				if element_name and not element_name:lower():find("error") then
					text = string.format("%s (%s)\n", text, element_name)
				else
					text = string.format("%s\n", text)
				end
			end
		end
		
		local money_str, favours_amnt = self:get_saved_costs(plan_name)
		money_str = managers.experience:cash_string(money_str)
		text = string.format("%s%s", text, managers.localization:text("menu_pp_tooltip_costs", {money = money_str, budget = favours_amnt}))
		
		return text
	end
	
	function PrePlanningManager:get_saved_costs(name)
		local money_costs, favours = 0, 0
		
		if PrePlanningManager._SAVED_PLANS[name] then
			local saved_assets, saved_votes = PrePlanningManager._SAVED_PLANS[name].assets or {}, PrePlanningManager._SAVED_PLANS[name].votes or {}
			for i, data in pairs(saved_votes) do
				money_costs = money_costs + self:_get_type_cost(data.type)
				favours = favours + self:get_type_budget_cost(data.type, 0)
			end
			
			for id, mission_element in pairs(saved_assets) do
				money_costs = money_costs + self:_get_type_cost(mission_element.type)
				favours = favours + self:get_type_budget_cost(mission_element.type, 0)
			end
		end
		return money_costs, favours
	end
	
	function PrePlanningManager:get_default_votes()
		local default_votes = {} 	--{plan = {element_type, element_index}}
		
		local location_data = self:_current_location_data()
		local default_plans = location_data and location_data.default_plans and location_data.default_plans or {}
		
		for plan, element_type in pairs(default_plans) do
			local default_element = self:get_default_plan_mission_element(element_type)
			if element_type and default_element then
				default_votes[plan] = {element_type, default_element:id()}
			end
		end
		
		return default_votes
	end
	
	function PrePlanningManager:notify_user(text_id, macros, show_SP)
		local message = managers.localization:text(text_id, macros)
		if not Global.game_settings.single_player  then
			managers.chat:feed_system_message(ChatManager.GAME, message)
		elseif show_SP then
			QuickMenu:new(managers.localization:text("wolfhud_preplanning_manager_title"), message, { text = managers.localization:text("dialog_ok"), is_cancel_button = true }, true)
		end
	end
end