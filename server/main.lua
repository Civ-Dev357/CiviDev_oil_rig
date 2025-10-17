local Framework = Config.Framework

--============================================================--
-- 📦 Database Wrapper
--============================================================--
local function dbExecute(query, params, cb)
    if Config.DBDriver == 'oxmysql' then
        exports.oxmysql:execute(query, params or {}, function(result)
            if cb then cb(result) end
        end)
    else
        exports.ghmattimysql:execute(query, params or {}, function(result)
            if cb then cb(result) end
        end)
    end
end

local function dbQuery(query, params, cb)
    dbExecute(query, params, cb)
end

--============================================================--
-- 🧾 Auto-create SQL tables on resource start
--============================================================--
AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    -- Player XP Table
    dbExecute(([[
        CREATE TABLE IF NOT EXISTS %s (
            identifier VARCHAR(64) PRIMARY KEY,
            xp BIGINT DEFAULT 0
        );
    ]]):format(Config.XPTable))

    -- Selling Stock Table
    dbExecute(([[
        CREATE TABLE IF NOT EXISTS %s (
            id VARCHAR(64) PRIMARY KEY,
            stock INT DEFAULT 0
        );
    ]]):format(Config.StockTable))

    -- Insert initial stock for selling points
    for _, s in pairs(Config.SellingPoints) do
        dbExecute(
            'INSERT INTO '..Config.StockTable..' (id, stock) VALUES (@id, @stock) ON DUPLICATE KEY UPDATE stock = stock',
            { ['@id'] = s.id, ['@stock'] = s.initialStock }
        )
    end

    print("^2[oil_rig]^0 Tables verified and initialized successfully.")
end)

--============================================================--
-- 🧍 Get Player Identifier (framework-dependent)
--============================================================--
local function GetIdentifier(player)
    if Framework == 'esx' then
        return player.getIdentifier and player:getIdentifier() or player.identifier
    elseif Framework == 'qbcore' then
        return player.PlayerData.citizenid or player.PlayerData.identifier
    elseif Framework == 'ox' then
        return player.identifier
    end
end

--============================================================--
-- 📈 Player Level Callback
--============================================================--
lib.callback.register('oilrig:server:getPlayerLevel', function(source, cb)
    local src = source
    local identifier

    local ply
    if Framework == 'esx' then
        ply = ESX.GetPlayerFromId(src)
    elseif Framework == 'qbcore' then
        ply = QBCore.Functions.GetPlayer(src)
    elseif Framework == 'ox' then
        ply = exports.ox_core:GetPlayer(src)
    end

    if ply then
        identifier = GetIdentifier(ply)
    end

    if not identifier then
        return cb(1)
    end

    dbQuery('SELECT xp FROM '..Config.XPTable..' WHERE identifier=@id', { ['@id'] = identifier }, function(result)
        local xp = 0
        if result and result[1] then xp = tonumber(result[1].xp) or 0 end

        local level = 1
        for i = #Config.Levels, 1, -1 do
            if xp >= Config.Levels[i].xp then
                level = Config.Levels[i].level
                break
            end
        end
        cb(level)
    end)
end)

--============================================================--
-- ⚙️ Handle Task Completion
--============================================================--
RegisterNetEvent('oilrig:server:completeTask', function(rigId, action)
    local src = source
    local ply

    if Framework == 'esx' then
        ply = ESX.GetPlayerFromId(src)
    elseif Framework == 'qbcore' then
        ply = QBCore.Functions.GetPlayer(src)
    elseif Framework == 'ox' then
        ply = exports.ox_core:GetPlayer(src)
    end

    if not ply then return end
    local identifier = GetIdentifier(ply)

    -- Validate Rig
    local rig
    for _, r in pairs(Config.Rigs) do
        if r.id == rigId then rig = r break end
    end
    if not rig then
        TriggerClientEvent('oilrig:client:notify', src, { description = 'Invalid rig.' })
        return
    end

    -- Calculate XP & Money
    local xpGain = math.floor(rig.baseXP * (action == 'collect' and 1.2 or 1.0))
    local money = math.floor(rig.basePay * (1 + (rig.difficulty * 0.2)))

    -- Update XP
    dbQuery('INSERT INTO '..Config.XPTable..' (identifier, xp) VALUES (@id, @xp) ON DUPLICATE KEY UPDATE xp = xp + @inc', {
        ['@id'] = identifier,
        ['@xp'] = xpGain,
        ['@inc'] = xpGain
    }, function()
        -- Add money (framework specific)
        if Framework == 'esx' then
            ply.addMoney(money)
        elseif Framework == 'qbcore' then
            ply.Functions.AddMoney('bank', money)
        elseif Framework == 'ox' then
            exports.ox_core:AddMoney(src, money)
        end

        TriggerClientEvent('oilrig:client:notify', src, { description = ('✅ Task complete! +%d XP, +$%d'):format(xpGain, money) })
    end)
end)

--============================================================--
-- 💰 Handle Selling Products
--============================================================--
RegisterNetEvent('oilrig:server:sellProduct', function(sellId, amount)
    local src = source
    amount = tonumber(amount) or 0
    if amount <= 0 then
        TriggerClientEvent('oilrig:client:notify', src, { description = 'Invalid amount.' })
        return
    end

    dbQuery('SELECT stock FROM '..Config.StockTable..' WHERE id=@id', { ['@id'] = sellId }, function(result)
        if not result or not result[1] then
            TriggerClientEvent('oilrig:client:notify', src, { description = 'Selling point not found.' })
            return
        end

        local current = tonumber(result[1].stock)
        local newStock = current + amount

        dbQuery('UPDATE '..Config.StockTable..' SET stock=@s WHERE id=@id', { ['@s'] = newStock, ['@id'] = sellId })

        local s
        for _, v in pairs(Config.SellingPoints) do
            if v.id == sellId then s = v break end
        end

        local pay = math.floor((50 * (s and (s.sellMultiplier or 1) or 1)) * amount)

        local ply
        if Framework == 'esx' then
            ply = ESX.GetPlayerFromId(src)
            ply.addMoney(pay)
        elseif Framework == 'qbcore' then
            ply = QBCore.Functions.GetPlayer(src)
            ply.Functions.AddMoney('cash', pay)
        elseif Framework == 'ox' then
            exports.ox_core:AddMoney(src, pay)
        end

        TriggerClientEvent('oilrig:client:notify', src, { description = ('💰 Sold %d units for $%d'):format(amount, pay) })
    end)
end)

--============================================================--
-- 🧾 Buy From Stock (for other jobs / resources)
--============================================================--
lib.register('oilrig:server:buyFromStock', function(sellId, amount, cb)
    amount = tonumber(amount) or 0
    if amount <= 0 then return cb(false) end

    dbQuery('SELECT stock FROM '..Config.StockTable..' WHERE id=@id', { ['@id'] = sellId }, function(result)
        if not result or not result[1] then return cb(false) end
        local current = tonumber(result[1].stock)
        if current >= amount then
            local newStock = current - amount
            dbQuery('UPDATE '..Config.StockTable..' SET stock=@s WHERE id=@id', { ['@s'] = newStock, ['@id'] = sellId })
            cb(true)
        else
            cb(false)
        end
    end)
end)

--============================================================--
-- ⛽ Refiller Job (restocks selling points)
--============================================================--
RegisterNetEvent('oilrig:server:startRefill', function(sellId)
    local src = source
    local ply

    if Framework == 'esx' then
        ply = ESX.GetPlayerFromId(src)
    elseif Framework == 'qbcore' then
        ply = QBCore.Functions.GetPlayer(src)
    elseif Framework == 'ox' then
        ply = exports.ox_core:GetPlayer(src)
    end

    if not ply then return end

    -- Check Player Level
    lib.callback.await('oilrig:server:getPlayerLevel', nil, function(level)
        if level < Config.Refiller.requiredLevel then
            TriggerClientEvent('oilrig:client:notify', src, {
                description = 'You need level '..Config.Refiller.requiredLevel..' to be a refiller.'
            })
            return
        end

        local units = 10
        local pay = units * Config.Refiller.paymentPerUnit

        dbQuery('SELECT stock FROM '..Config.StockTable..' WHERE id=@id', { ['@id'] = sellId }, function(result)
            if not result or not result[1] then
                TriggerClientEvent('oilrig:client:notify', src, { description = 'Invalid selling area.' })
                return
            end

            local newStock = tonumber(result[1].stock) + units
            dbQuery('UPDATE '..Config.StockTable..' SET stock=@s WHERE id=@id', { ['@s'] = newStock, ['@id'] = sellId })

            if Framework == 'esx' then
                ply.addMoney(pay)
            elseif Framework == 'qbcore' then
                ply.Functions.AddMoney('bank', pay)
            elseif Framework == 'ox' then
                exports.ox_core:AddMoney(src, pay)
            end

            TriggerClientEvent('oilrig:client:notify', src, {
                description = ('🚛 Refill complete! +%d stock, +$%d'):format(units, pay)
            })
        end)
    end)
end)
