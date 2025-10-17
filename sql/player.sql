--============================================================--
-- oil_rig Player XP Table
-- Stores each player's accumulated XP and level progression
--============================================================--

CREATE TABLE IF NOT EXISTS oilrig_player_xp (
  identifier VARCHAR(64) PRIMARY KEY,
  xp BIGINT DEFAULT 0
);
