--============================================================--
-- oil_rig Configuration File
-- Multi-framework support: ESX / QBCore / ox_core
--============================================================--

Config = {}

--============================================================--
-- 🔧 Core Settings
--============================================================--

-- Choose your active framework: 'esx' | 'qbcore' | 'ox'
Config.Framework = 'esx'

-- Choose your database driver: 'oxmysql' or 'ghmattimysql'
Config.DBDriver = 'oxmysql'

-- SQL table names (you can rename if needed)
Config.XPTable = 'oilrig_player_xp'
Config.StockTable = 'oilrig_selling_stock'

--============================================================--
-- ⚙️ Oil Rig Work Locations
--============================================================--
-- Each rig has:
-- id, name, coords (vector3), difficulty (1–5), basePay, baseXP, unlockLevel

Config.Rigs = {
    { id = 'rig_01', name = 'Shoreline Platform', coords = vector3(1234.56, 2345.67, 45.0), difficulty = 1, basePay = 150, baseXP = 20, unlockLevel = 1 },
    { id = 'rig_02', name = 'Deepwater A', coords = vector3(2345.00, 1900.00, 30.0), difficulty = 3, basePay = 350, baseXP = 65, unlockLevel = 3 },
    { id = 'rig_03', name = 'Horizon XL', coords = vector3(3000.00, 2500.00, 20.0), difficulty = 5, basePay = 700, baseXP = 150, unlockLevel = 6 },
}

--============================================================--
-- 🛒 Selling Points (Ports / Bunks)
--============================================================--
-- Each selling point: id, name, coords, sellMultiplier, initialStock

Config.SellingPoints = {
    { id = 'bunk_01', name = 'Port Bunk Alpha', coords = vector3(4000.0, 4500.0, 1.0), sellMultiplier = 1.0, initialStock = 50 },
}

--============================================================--
-- 🚚 Refiller Job
--============================================================--
-- Players with required level can refill stock at selling points for pay

Config.Refiller = {
    paymentPerUnit = 10,   -- payment for each stock unit refilled
    requiredLevel = 2,     -- minimum player level to become refiller
}

--============================================================--
-- 🎯 Level System
--============================================================--
-- Define XP requirements for each level

Config.Levels = {
    { level = 1, xp = 0 },
    { level = 2, xp = 200 },
    { level = 3, xp = 500 },
    { level = 4, xp = 1000 },
    { level = 5, xp = 2000 },
    { level = 6, xp = 3500 },
}

--============================================================--
-- 🧠 Server Security / Multipliers
--============================================================--
-- This prevents client-side tampering of speed or XP

Config.Server = {
    progressTimeMultiplier = 1.0, -- change task speed (1.0 = normal)
}

--============================================================--
-- ✅ Optional Target System (future use)
--============================================================--
-- You can integrate qb-target / ox_target later using this setting
-- Example: 'qb-target' | 'ox_target' | 'none'

Config.Target = 'none'
