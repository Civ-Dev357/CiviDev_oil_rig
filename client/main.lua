local ox = exports.ox_lib
local framework = Config.Framework

local Framework = {}
--============================================================--
-- ⚙️ Framework Initialization
--============================================================--
if framework == 'esx' then
    Framework.GetPlayer = function() return ESX.GetPlayerData() end
elseif framework == 'qbcore' then
    Framework.GetPlayer = function() return QBCore.Functions.GetPlayerData() end
elseif framework == 'ox' then
    Framework.GetPlayer = function() return exports.ox_core:GetPlayer() end
end

--============================================================--
-- 🧰 Open Rig Menu
--============================================================--
local function OpenRigMenu(rig)
    local player = Framework.GetPlayer()
    if not player then return end

    -- Fetch level from server
    lib.callback.await('oilrig:server:getPlayerLevel', false, function(level)
        if level < rig.unlockLevel then
            ox:notify({description = 'You need level '..rig.unlockLevel..' to access this rig.'})
            return
        end

        local menu = ox:menu({
            title = rig.name,
            align = 'right',
            elements = {
                { label = 'Repair ('..rig.difficulty..')', action = 'repair' },
                { label = 'Tune Engine', action = 'tune' },
                { label = 'Collect Crude', action = 'collect' },
            }
        })

        menu:on('select', function(selected)
            local action = selected.action
            ox:progressBar({
                duration = math.floor(5000 * rig.difficulty * Config.Server.progressTimeMultiplier),
                label = action .. ' in progress',
                position = 'bottom'
            }, function(success)
                if success then
                    TriggerServerEvent('oilrig:server:completeTask', rig.id, action)
                else
                    ox:notify({description = 'Task canceled.'})
                end
            end)
        end)
    end)
end

--============================================================--
-- 🗺️ Create Blips for Rigs
--============================================================--
CreateThread(function()
    for _, rig in pairs(Config.Rigs) do
        local blip = AddBlipForCoord(rig.coords.x, rig.coords.y, rig.coords.z)
        SetBlipSprite(blip, 488) -- Oil platform icon
        SetBlipScale(blip, 0.8)
        SetBlipColour(blip, 5)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString('Oil Rig - '..rig.name)
        EndTextCommandSetBlipName(blip)
    end
end)

--============================================================--
-- 🧭 Rig Interaction (Press [E])
--============================================================--
CreateThread(function()
    while true do
        local pcoords = GetEntityCoords(PlayerPedId())
        for _, rig in pairs(Config.Rigs) do
            if #(pcoords - rig.coords) < 3.0 then
                ox:draw3dText(rig.coords, '[E] '..rig.name)
                if IsControlJustReleased(0, 38) then -- E Key
                    OpenRigMenu(rig)
                end
            end
        end
        Wait(0)
    end
end)

--============================================================--
-- 💰 Selling Point Menu
--============================================================--
local function OpenSellingMenu(sell)
    local menu = ox:menu({
        title = sell.name,
        align = 'right',
        elements = {
            { label = 'Sell Refined Oil', action = 'sell' },
            { label = 'Refill Stock (Refiller Job)', action = 'refill' }
        }
    })

    menu:on('select', function(selected)
        if selected.action == 'sell' then
            local input = ox:input({type='number', description='Units to sell', default = 1})
            if input and input > 0 then
                TriggerServerEvent('oilrig:server:sellProduct', sell.id, tonumber(input))
            end
        elseif selected.action == 'refill' then
            TriggerServerEvent('oilrig:server:startRefill', sell.id)
        end
    end)
end

--============================================================--
-- 🛒 Selling Point Interaction
--============================================================--
CreateThread(function()
    while true do
        local pcoords = GetEntityCoords(PlayerPedId())
        for _, s in pairs(Config.SellingPoints) do
            if #(pcoords - s.coords) < 3.0 then
                ox:draw3dText(s.coords, '[E] '..s.name)
                if IsControlJustReleased(0, 38) then
                    OpenSellingMenu(s)
                end
            end
        end
        Wait(0)
    end
end)

--============================================================--
-- 🔔 Notification Listener
--============================================================--
RegisterNetEvent('oilrig:client:notify', function(data)
    ox:notify(data)
end)
