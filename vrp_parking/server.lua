local Parking = class("Parking", vRP.Extension)

Parking.event = {}
Parking.User = class("User")

function Parking:addOwnedVehicle(user, model)
    if not user.cdata.vehicles then user.cdata.vehicles = {} end
    user.cdata.vehicles[model] = {
        garage_type = "owned",
        in_showroom_garage = true, 
        customization = {},
        condition = { health = 1000, engine = 1000 },
        fuel = 50
    }
    vRP:setCData(user.cid, "vRP:vehicle_state:" .. model, msgpack.pack(user.cdata.vehicles[model]))
    vRP.EXT.Base.remote._notify(user.source, "Your new vehicle is in the showroom! Retrieve it when ready.")
end

local function menu_showroom(self)
    local function buy_vehicle(menu, vehicle)
        local user = menu.user
        local model = vehicle.model
        local price = vehicle.price
        local uvehicles = user:getVehicles()

        if not uvehicles[model] and user:tryPayment(price) then
            uvehicles[model] = 1
            self:addOwnedVehicle(user, model) 

            vRP.EXT.Base.remote._notify(user.source, "You bought a " .. vehicle.name .. " for $" .. vRP.formatNumber(price))
            user:actualizeMenu() 
        else
            vRP.EXT.Base.remote._notify(user.source, "You don't have enough money or already own this vehicle!")
        end
    end

    vRP.EXT.GUI:registerMenuBuilder("showroom", function(menu)
        menu.title = "Showroom"
        menu.css.header_color = "rgba(255,125,0,0.75)"
        local user = menu.user
        local uvehicles = user:getVehicles()
        
        for _, vehicle in ipairs(self.cfg.showroom_vehicles) do
            if not uvehicles[vehicle.model] then 
                menu:addOption(vehicle.name .. " - $" .. vehicle.price, buy_vehicle, "Purchase this vehicle", vehicle)
            end
        end
    end)
end

local function menu_showroom_retrieve(self)
    local function veh_get(menu, model)
        local user = menu.user
        if user.cdata.vehicles[model] and user.cdata.vehicles[model].in_showroom_garage then
            local vstate = user:getVehicleState(model)
            local state = {
                customization = vstate.customization,
                condition = vstate.condition,
                locked = vstate.locked
            }

            user.cdata.vehicles[model].in_showroom_garage = false
            user.cdata.vehicles[model].garage_type = "out" 

            vRP:setCData(user.cid, "vRP:vehicle_state:" .. model, msgpack.pack(user.cdata.vehicles[model]))

            vRP.EXT.Garage.remote._spawnVehicle(user.source, model, state)
            vRP.EXT.Garage.remote._setOutVehicles(user.source, {[model] = {}})

            vRP.EXT.Base.remote._notify(user.source, "Your vehicle has been retrieved from the showroom!")
            user:closeMenu(menu)
        else
            vRP.EXT.Base.remote._notify(user.source, "This vehicle is no longer in the showroom garage!")
        end
    end

    vRP.EXT.GUI:registerMenuBuilder("showroom_retrieve", function(menu)
        menu.title = "Showroom Garage"
        menu.css.header_color = "rgba(0,255,0,0.75)" 
        local user = menu.user
        local found = false

        if user.cdata.vehicles then
            for model, vehicle_data in pairs(user.cdata.vehicles) do
                if type(vehicle_data) == "table" and vehicle_data.in_showroom_garage then
                    found = true
                    menu:addOption(vehicle_data.name or model, veh_get, "Retrieve this vehicle", model)
                end
            end
        end

        if not found then
            menu:addOption("No vehicles available", function() end, "You have no vehicles in the showroom.")
        end
    end)
end

local function menu_parking_space(self)
    local function get_slot_info(parking_name, slot_id)
        local rows = vRP:query("vRP/get_user_parking_slot", { parking_name = parking_name, slot_number = slot_id })
        if #rows > 0 then
            local slot = rows[1]
            if slot.owner_id and slot.vehicle_model and slot.vehicle_model ~= "" then
                return slot 
            else
                vRP:execute("vRP/update_parking_slot", {
                    owner_id = nil,
                    vehicle_model = nil,
                    parking_name = parking_name,
                    slot_number = slot_id,
                    available = true
                })
            end
        end
        return nil 
    end

    local function park_vehicle(menu)
        local user = menu.user
        local parking_name, slot_id = self:getParkSpace(user)
        if not parking_name or not slot_id then
            vRP.EXT.Base.remote._notify(user.source, "You are not in a valid parking slot.")
            return
        end
        local vehicle = vRP.EXT.Garage.remote.getNearestOwnedVehicle(user.source, 5)
        if not vehicle then
            vRP.EXT.Base.remote._notify(user.source, "You do not have a vehicle nearby.")
            return
        end
    
        if not user:getVehicles()[vehicle] then
            vRP.EXT.Base.remote._notify(user.source, "This is not your vehicle!")
            return
        end
        if get_slot_info(parking_name, slot_id) then
            vRP.EXT.Base.remote._notify(user.source, "This parking slot is already occupied!")
            return
        end
        vRP.EXT.Garage.remote._removeOutVehicles(user.source, {[vehicle] = true})
        if vRP.EXT.Garage.remote.despawnVehicle(user.source, vehicle) then
            if not user.cdata.vehicles then user.cdata.vehicles = {} end
            user.cdata.vehicles[vehicle] = {
                garage_type = "parked",
                in_showroom_garage = false
            }
            vRP:setCData(user.cid, "vRP:vehicle_state:" .. vehicle, msgpack.pack(user.cdata.vehicles[vehicle]))
            vRP:execute("vRP/update_parking_slot", {
                owner_id = user.cid,
                vehicle_model = vehicle,
                parking_name = parking_name,
                slot_number = slot_id,
                available = false
            })
            vRP.EXT.Base.remote._notify(user.source, "Your vehicle has been parked at " .. parking_name .. ", Slot #" .. slot_id)
        else
            vRP.EXT.Base.remote._notify(user.source, "Could not despawn the vehicle.")
        end
    end

    local function retrieve_vehicle(menu)
        local user = menu.user
        local parking_name, slot_id = self:getParkSpace(user)
    
        if not parking_name or not slot_id then
            vRP.EXT.Base.remote._notify(user.source, "You are not in a valid parking slot.")
            return
        end
    
        if vRP.EXT.Garage.remote.isInVehicle(user.source) then
            vRP.EXT.Base.remote._notify(user.source, "Exit your vehicle before retrieving it.")
            return
        end
    
        local slot = get_slot_info(parking_name, slot_id)
        if not slot or slot.owner_id ~= user.cid then
            vRP.EXT.Base.remote._notify(user.source, "You have no parked vehicles in this slot.")
            return
        end
    
        vRP:execute("vRP/update_parking_slot", {
            owner_id = nil,
            vehicle_model = nil,
            parking_name = parking_name,
            slot_number = slot_id,
            available = true
        })
    
        local vehicle_model = slot.vehicle_model
        local vstate = user:getVehicleState(vehicle_model)
        local state = {
            customization = vstate.customization,
            condition = vstate.condition,
            locked = vstate.locked,
            garage_type = "out"
        }
        vRP:setCData(user.cid, "vRP:vehicle_state:" .. vehicle_model, msgpack.pack(user.cdata.vehicles[vehicle_model]))
    
        local slot_data = self.cfg.parking_areas[parking_name].slots[slot_id]
        local spawn_position = slot_data and { x = slot_data.pos[1], y = slot_data.pos[2], z = slot_data.pos[3] } or {}
    
        vRP.EXT.Garage.remote._spawnVehicle(user.source, vehicle_model, state)
        vRP.EXT.Garage.remote._setOutVehicles(user.source, {[vehicle_model] = {state, spawn_position}})
    
        vRP.EXT.Base.remote._notify(user.source, "Your vehicle has been retrieved from " .. parking_name .. ", Slot #" .. slot_id)
    end
    

    vRP.EXT.GUI:registerMenuBuilder("parking_lot", function(menu)
        local user = menu.user
        local parking_name, slot_id = self:getParkSpace(user)
        if not parking_name or not slot_id then
            vRP.EXT.Base.remote._notify(user.source, "You are not in a valid parking slot.")
            return
        end

        menu.title = parking_name .. " - Slot #" .. slot_id
        menu.css.header_color = "rgba(0,150,255,0.75)"

        local vehicle = vRP.EXT.Garage.remote.getNearestOwnedVehicle(user.source, 5)
        local isInVehicle = vRP.EXT.Garage.remote.isInVehicle(user.source)

        local slot = get_slot_info(parking_name, slot_id)

        if slot then
            if slot.owner_id == user.cid then
                if not isInVehicle then
                    menu:addOption("Retrieve Vehicle", function(menu)
                        retrieve_vehicle(menu)
                    end, "Retrieve your parked vehicle.")
                else
                    user:closeMenu()
                    vRP.EXT.Base.remote._notify(user.source, "Exit your vehicle before retrieving it.")
                end
            else
                vRP.EXT.Base.remote._notify(user.source, "This parking slot is occupied by another player.")
            end
        else
            if vehicle then
                menu:addOption("Park Vehicle", function(menu)
                    park_vehicle(menu)
                end, "Park your vehicle in this slot.")
            else
                user:closeMenu()
                vRP.EXT.Base.remote._notify(user.source, "You need to be near your owned vehicle to park here.")
            end
        end
    end)
end

local function menu_multi_parking(self)
    local function get_available_slots(parking_name)
        local result = vRP:query("vRP/get_available_parking_slot", { parking_name = parking_name }) or {}
        local occupied_slots = {}
        for _, slot in ipairs(result) do
            occupied_slots[slot.slot_number] = true
        end
        for i = 1, self.cfg.multy_parking[parking_name].slots do
            if not occupied_slots[i] then
                return i  
            end
        end
        return nil  
    end
    
    local function get_owner_multy_parked(parking_name, owner_id)
        local parked_vehicles = vRP:query("vRP/get_owner_multy_parked", { parking_name = parking_name, owner_id = owner_id }) 
        return parked_vehicles
    end

    local function multi_parking_vehicle(menu)
        local user = menu.user
        local parking_name, _ = self:getParkSpace(user)
    
        if not parking_name or not self.cfg.multy_parking[parking_name] then
            vRP.EXT.Base.remote._notify(user.source, "Invalid parking location.")
            return
        end
    
        local available_slot = get_available_slots(parking_name)
        if not available_slot then
            vRP.EXT.Base.remote._notify(user.source, "This parking lot is full!")
            return
        end
    
        local vehicle = vRP.EXT.Garage.remote.getNearestOwnedVehicle(user.source, 5)
        if not vehicle then
            vRP.EXT.Base.remote._notify(user.source, "You do not have a vehicle nearby.")
            return
        end
    
        local vehicles = user:getVehicles()
        if not vehicles[vehicle] then
            vRP.EXT.Base.remote._notify(user.source, "This is not your vehicle!")
            return
        end
    
        vRP.EXT.Garage.remote._removeOutVehicles(user.source, {[vehicle] = true})
    
        if vRP.EXT.Garage.remote.despawnVehicle(user.source, vehicle) then
            if not user.cdata.vehicles then user.cdata.vehicles = {} end
    
            user.cdata.vehicles[vehicle] = {
                garage_type = "parked",
                in_showroom_garage = false
            }
    
            vRP:setCData(user.cid, "vRP:vehicle_state:" .. vehicle, msgpack.pack(user.cdata.vehicles[vehicle]))
    
            vRP:execute("vRP/update_parking_slot", {
                owner_id = user.cid,
                vehicle_model = vehicle,
                parking_name = parking_name,
                slot_number = available_slot, 
                available = false
            })
    
            vRP.EXT.Base.remote._notify(user.source, "Your vehicle has been parked at " .. parking_name)
        else
            vRP.EXT.Base.remote._notify(user.source, "Could not despawn the vehicle.")
        end
    end

    local function retrieve_vehicle_mp(menu, vehicle_model, slot_number)
        local user = menu.user
        local parking_name, _ = self:getParkSpace(user)
    
        if not parking_name or not self.cfg.multy_parking[parking_name] then
            vRP.EXT.Base.remote._notify(user.source, "Invalid parking location.")
            return
        end
    
        if vRP.EXT.Garage.remote.isInVehicle(user.source) then
            vRP.EXT.Base.remote._notify(user.source, "Exit your vehicle before retrieving it.")
            return
        end
    
        vRP:execute("vRP/update_parking_slot", {
            owner_id = nil,
            vehicle_model = nil,
            parking_name = parking_name,
            slot_number = slot_number,
            available = true
        })
    
        local vstate = user:getVehicleState(vehicle_model)
        local state = {
            customization = vstate.customization,
            condition = vstate.condition,
            locked = vstate.locked,
            garage_type = "out"
        }
    
        vRP:setCData(user.cid, "vRP:vehicle_state:" .. vehicle_model, msgpack.pack(user.cdata.vehicles[vehicle_model]))
        
    
        local spawn_position = self.cfg.multy_parking[parking_name].location
    
        vRP.EXT.Garage.remote._spawnVehicle(user.source, vehicle_model, state)
        vRP.EXT.Garage.remote._setOutVehicles(user.source, {[vehicle_model] = {state, spawn_position}})
    
        vRP.EXT.Base.remote._notify(user.source, "Your vehicle has been retrieved from " .. parking_name .. ", Slot #" .. slot_number)
    end
    

    vRP.EXT.GUI:registerMenuBuilder("multi_parking.owned", function(menu)
        menu.title = "Your Parked Vehicles"
        menu.css.header_color = "rgba(200,100,0,0.75)"
        local user = menu.user
        local parking_name = menu.data.parking_name

        local parked_vehicles = get_owner_multy_parked(parking_name, user.cid)

        if #parked_vehicles > 0 then
            for _, slot in ipairs(parked_vehicles) do
                local vehicle_name = slot.vehicle_model or "Unknown Vehicle"
                menu:addOption(vehicle_name, function(sub_menu)
                    retrieve_vehicle_mp(sub_menu, slot.vehicle_model, slot.slot_number)
                end, "Retrieve " .. vehicle_name)
            end
        else
            menu:addOption("No Parked Vehicles", function() end, "You have no parked vehicles here.")
        end
    end)

    vRP.EXT.GUI:registerMenuBuilder("multi_parking", function(menu)
        local user = menu.user
        local parking_name, _ = self:getParkSpace(user)

        if not parking_name or not self.cfg.multy_parking[parking_name] then
            vRP.EXT.Base.remote._notify(user.source, "Invalid parking location.")
            return
        end

        menu.title = parking_name .. " Parking"
        menu.css.header_color = "rgba(255,150,0,0.75)"

        local available_slots = get_available_slots(parking_name)
        if available_slots > 0 then
            menu:addOption("Park Vehicle", function(menu)
                multi_parking_vehicle(menu)
            end, "Park your vehicle in this location.")
        else
            vRP.EXT.Base.remote._notify(user.source, "This parking lot is full!")
        end

        local parked_vehicles = get_owner_multy_parked(parking_name, user.cid)

        if #parked_vehicles > 0 then
            menu:addOption("Parked Vehicles", function(menu)
                local smenu = menu.user:openMenu("multi_parking.owned", menu.data)
                menu:listen("remove", function(menu)
                    menu.user:closeMenu(smenu)
                end)
            end, "View and retrieve your parked vehicles.")
        end
    end)
end


function Parking:__construct()
    vRP.Extension.__construct(self)
    
    self.cfg = module("vrp_parking", "cfg")

    menu_showroom_retrieve(self)
    menu_showroom(self)
    menu_parking_space(self) 
    menu_multi_parking(self)

    async(function()
        vRP:prepare("vRP/park", [[
            CREATE TABLE IF NOT EXISTS vrp_parking_slots (
            parking_name VARCHAR(100) NOT NULL,
            slot_number INT NOT NULL,
            vehicle_model VARCHAR(50) DEFAULT NULL,
            owner_id INT DEFAULT NULL, 
            available BOOLEAN DEFAULT TRUE,
            PRIMARY KEY (parking_name, slot_number)
        );
        ]])

        vRP:execute("vRP/park")
         vRP:prepare("vRP/insert_parking_slot", [[
            INSERT IGNORE INTO vrp_parking_slots (parking_name, slot_number, available)
            VALUES (@parking_name, @slot_number, TRUE)
        ]])

        vRP:prepare("vRP/get_available_parking_slot", [[
            SELECT slot_number FROM vrp_parking_slots WHERE parking_name = @parking_name AND owner_id IS NOT NULL ORDER BY slot_number ASC
        ]])

        vRP:prepare("vRP/get_user_parking_slot", [[
            SELECT * FROM vrp_parking_slots WHERE parking_name = @parking_name AND slot_number = @slot_number
        ]])

        vRP:prepare("vRP/get_owner_multy_parked", [[
            SELECT * FROM vrp_parking_slots WHERE parking_name = @parking_name AND owner_id = @owner_id
        ]])

           
        vRP:prepare("vRP/update_parking_slot", [[
            UPDATE vrp_parking_slots SET 
                owner_id = @owner_id, 
                vehicle_model = @vehicle_model, 
                available = @available
            WHERE parking_name = @parking_name AND slot_number = @slot_number
        ]])

        for parking_name, data in pairs(self.cfg.parking_areas) do
            for _, slot in ipairs(data.slots) do
                vRP:execute("vRP/insert_parking_slot", {
                    parking_name = parking_name,
                    slot_number = slot.id
                })
            end
        end

        for parking_name, data in pairs(self.cfg.multy_parking) do
            for i = 1, data.slots do
                vRP:execute("vRP/insert_parking_slot", {
                    parking_name = parking_name,
                    slot_number = i
                })
            end
        end
    end)
end

function Parking:getParkSpace(user)
    for parking_name, data in pairs(self.cfg.parking_areas) do
        for _, slot in pairs(data.slots) do
            local area_id = "vRP:ParkingLot:" .. parking_name .. "::" .. slot.id
            if user:inArea(area_id) then
                return parking_name, slot.id 
            end
        end
    end
    for parking_name, _ in pairs(self.cfg.multy_parking) do
        local area_id = "vRP:MultiParking:" .. parking_name
        if user:inArea(area_id) then
            return parking_name, nil  
        end
    end

    return nil, nil 
end


function Parking.event:playerSpawn(user, first_spawn)
    if first_spawn then 
        for k, v in pairs(self.cfg.showrooms) do
            local x, y, z = table.unpack(v)
            local showroom_entity = clone(self.cfg.showroom_map)
            showroom_entity[2].title = "Showroom"
            showroom_entity[2].pos = {x, y, z - 1}
            vRP.EXT.Map.remote._addEntity(user.source, showroom_entity[1], showroom_entity[2])

            local function enter_showroom(user)
                user:openMenu("showroom")
            end

            local function leave(user)
                user:closeMenu()
            end

            user:setArea("vRP:Showroom:" .. k, x, y, z, 1.5, 1.5, enter_showroom, leave)
        end

        for k, v in pairs(self.cfg.owned) do
            local x, y, z = table.unpack(v)
            local owned_entity = clone(self.cfg.owned_map)
            owned_entity[2].title = "Owned Garage"
            owned_entity[2].pos = {x, y, z - 1}
            vRP.EXT.Map.remote._addEntity(user.source, owned_entity[1], owned_entity[2])

            local function enter_owned(user)
                user:openMenu("showroom_retrieve")
            end

            local function leave(user)
                user:closeMenu()
            end

            user:setArea("vRP:OwnedGarage:" .. k, x, y, z, 1.5, 1.5, enter_owned, leave)
        end

        for parking_name, data in pairs(self.cfg.parking_areas) do
            for _, slot in ipairs(data.slots) do
                local x, y, z = table.unpack(slot.pos)
                local parking_entity = clone(self.cfg.parking_map)
                parking_entity[2].title = parking_name .. " - Slot #" .. slot.id
                parking_entity[2].pos = {x, y, z - 1}
                vRP.EXT.Map.remote._addEntity(user.source, parking_entity[1], parking_entity[2])

                local function enter_parking(user)
                    user:openMenu("parking_lot", {area = parking_name, id_park = slot.id})
                end

                local function leave(user)
                    user:closeMenu()
                end

                local area_id = "vRP:ParkingLot:" .. parking_name .. "::" .. slot.id
                user:setArea(area_id, x, y, z, 1.5, 1.5, enter_parking, leave)
            end
        end

        for parking_name, data in pairs(self.cfg.multy_parking) do
            local x, y, z = table.unpack(data.location)
            local multi_parking_entity = clone(self.cfg.parking_map)
            multi_parking_entity[2].title = parking_name .. " Parking"
            multi_parking_entity[2].pos = {x, y, z - 1}
            vRP.EXT.Map.remote._addEntity(user.source, multi_parking_entity[1], multi_parking_entity[2])

            local function enter_multi_parking(user)
                user:openMenu("multi_parking", {parking_name = parking_name})
            end

            local function leave(user)
                user:closeMenu()
            end

            local area_id = "vRP:MultiParking:" .. parking_name
            user:setArea(area_id, x, y, z, 2.0, 2.0, enter_multi_parking, leave)
        end
    end
end

vRP:registerExtension(Parking)
