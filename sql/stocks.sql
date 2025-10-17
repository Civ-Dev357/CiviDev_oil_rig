--============================================================--
-- oil_rig Selling Stock Table
-- Keeps track of selling point stock (bunks / ports)
--============================================================--

CREATE TABLE IF NOT EXISTS oilrig_selling_stock (
  id VARCHAR(64) PRIMARY KEY,
  stock INT DEFAULT 0
);

--============================================================--
-- 🧾 Insert Example Stock Record
--============================================================--
INSERT INTO oilrig_selling_stock (id, stock)
VALUES ('bunk_01', 50)
ON DUPLICATE KEY UPDATE stock = stock;
