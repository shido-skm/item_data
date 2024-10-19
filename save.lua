local player = game.Players.LocalPlayer
local inventoryGui = player.PlayerGui:FindFirstChild("InventoryUi")
local itemScrollingFrame = inventoryGui.Main.Display.Gear:FindFirstChild("ItemScrollingFrame")


local function fire_sell_item_event(itemType,ID)
	local args = {
	        [1] = {
	        	[itemType] = {ID}
	        }
	    }

	game:GetService("ReplicatedStorage").remotes.sellItemEvent:FireServer(unpack(args))
end


local function player_raw_data()
	local player_raw_data = {}
	
	for z, item in pairs(itemScrollingFrame:GetChildren()) do
	    if item:IsA("TextButton") then
	        local itemName = item.Name
	        local itemType = item:GetAttribute("ItemType")
	        local rarity = item:GetAttribute("Rarity")
	        
	    	table.insert(player_raw_data, {itemName, itemType, rarity})
	    end
	end
	return player_raw_data
end


local function consolidate(consolidatedItems, itemName, category, rarity)
    
    for _, item in ipairs(consolidatedItems) do
        if item[1] == itemName and item[2] == category and item[3] == rarity then
            item[4] = item[4] + 1 -- Increase count if item already exists
            return
        end
    end
    -- If item does not exist, add it with a count of 1
    table.insert(consolidatedItems, {itemName, category, rarity, 1})
end


local function get_consolidated_table(raw_data)
	consolidatedItems = {}
	
	for _, item in ipairs(raw_data) do
	    local itemName = item[1]
	    local category = item[2]
	    local rarity = item[3]
	    consolidate(consolidatedItems,itemName, category, rarity)
	end

	return consolidatedItems
end


 local function count_items(item_list)
 	local helmets, chests, weapons, abilities = 0,0,0,0

 	for _, item in ipairs(item_list) do
 		if item[2] == 'helmet' then
 			helmets = helmets + item[4]

 		elseif item[2] == 'chest' then
 			chests = chests + item[4]

 		elseif item[2] == 'weapon' then
 			weapons = weapons + item[4]

 		elseif item[2] == 'ability' then
 			abilities = abilities + item[4]

 		end
 	end

 	return helmets, chests, weapons, abilities
 end


local function saveTable(item_data_table, filename)
    local saveFolder = "folder"
    if not isfolder(saveFolder) then makefolder(saveFolder) end
    local content = "return {\n"
    for _, v in ipairs(item_data_table) do
        content = content .. (string.format("    {%q, %q, %q, %d},\n", v[1], v[2], v[3], v[4]))
    end
    content = content .. "}"
    writefile(saveFolder .. "/" .. filename, content)
end


local function loadTable(filename)
    local f = loadfile(filename)
    if f then
        return f()  -- Call the loaded function to get the table
    end
    return nil
end
--local loadedTableB = loadTable("tableB.lua")

local function NewItem(item, tbl)
    for _, existingItem in ipairs(tbl) do
        if existingItem[1] == item[1] and existingItem[2] == item[2] and existingItem[3] == item[3] then
            return existingItem[4] < item[4] -- Return true if count in B is higher
        end
    end
    return true -- If not found in A, it's a new item
end

-- Find new elements in table B that are not in table A or have a higher count. Table B = items at an instant ; Table A = items from save data
local function ReturnNewItem(tableA, tableB)
	local tableC = {}
	for _, item in ipairs(tableB) do
	    if NewItem(item, tableA) then
	        table.insert(tableC, item)
	    end
	end
	return tableC
end

-------------------------------------------------------------------------------------------------------------------------

local function save_state_button_function()
	local r_data = player_raw_data() --raw data of the player
	local consolidated_data = get_consolidated_table(r_data) --processed data of the player
	
	saveTable(consolidated_data, 'save_data.lua')

end

local function sell_toggle_button_function()
	local legendary_weapon = false
	local legendary_ability = false

	local r_data = player_raw_data() --raw data of the player
	local r_data_output = ''
	local consolidated_data_output = ''
	local saved_data_output = ''
	local loot_data_output = ''
	
	------------------------------
	for _,item in r_data do
		r_data_output = r_data_output ..item[1]..' '..item[2]..' '..item[3]..'\n'
	end 
	writefile('output/raw_data.txt', r_data_output)
	------------------------------
	
	local instant_items = get_consolidated_table(r_data) --processed data of the player, items that the player has at the time of execution of function
	------------------------------
	for _,item in instant_items do
		consolidated_data_output = consolidated_data_output ..item[1]..' '..item[2]..' '..item[3]..' '..item[4]..'\n'
	end 
	writefile('output/consolidated_data.txt', consolidated_data_output)
	------------------------------	
	
	local saved_items = loadTable('folder/save_data.lua') --saved items
	
	------------------------------
	for _,item in saved_items do
		saved_data_output = saved_data_output ..item[1]..' '..item[2]..' '..item[3]..' '..item[4]..'\n'
	end 
	writefile('output/saved_data.txt', saved_data_output)
	------------------------------		
	
	local loot = ReturnNewItem(saved_items, instant_items)

	------------------------------
	for _,item in loot do
		loot_data_output = loot_data_output ..item[1]..' '..item[2]..' '..item[3]..' '..item[4]..'\n'
	end 
	writefile('output/loot_data.txt', loot_data_output)
	------------------------------
	
	for _, new_item in loot do
		if new_item[3] == 'rare' and new_item[2] == 'ability' then
			legendary_ability = true
		end

		if new_item[3] == 'rare' and new_item[2] == 'weapon' then
			legendary_weapon = true
		end
	end

	--writefile('output/bool.txt', 'ability: '..legendary_ability..'\nweapon: '..legendary_weapon)
	--writefile('output/bool.txt', 'ability: '..tostring(legendary_ability)..'\nweapon: '..tostring(legendary_weapon))
	writefile('output/bool.txt', 'true')


	helmets, chests, weapons, abilities = count_items(saved_items)
	writefile('output/count.txt','helmets: '..helmets..'\nchests: '..chests..'\nweapons: '..weapons..'\nabilities: '..abilities)

	if legendary_ability and legendary_weapon then
		for i = helmets + 1, 9 do
			fire_sell_item_event('helmet',i)
		end

		for i = chests + 1, 9 do
			fire_sell_item_event('chest',i)
		end
		save_state_button_function()

	elseif legendary_weapon then
		for i = helmets + 1, 9 do
			fire_sell_item_event('helmet',i)
		end

		for i = chests + 1, 9 do
			fire_sell_item_event('chest',i)
		end

		for i = abilities + 1, 9 do
			fire_sell_item_event('ability',i)
		end
		save_state_button_function()

	elseif legendary_ability then
		for i = helmets + 1, 9 do
			fire_sell_item_event('helmet',i)
		end

		for i = chests + 1, 9 do
			fire_sell_item_event('chest',i)
		end

		for i = weapons + 1, 9 do
			fire_sell_item_event('weapon',i)
		end

		save_state_button_function()

	else
		for i = helmets + 1, 9 do
			fire_sell_item_event('helmet',i)
		end

		for i = chests + 1, 9 do
			fire_sell_item_event('chest',i)
		end

		for i = weapons + 1, 9 do
			fire_sell_item_event('weapon',i)
		end

		for i = abilities + 1, 9 do
			fire_sell_item_event('ability',i)
		end
	end
end

--writefile('output/progress.txt', 'script started!')
save_state_button_function()
