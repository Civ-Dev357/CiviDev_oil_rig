--============================================================--
-- 🔁 Exports for other scripts to access stock data
--============================================================--

exports('TryBuyFromStock', function(sellId, amount)
    local cb = promise.new()
    lib.callback.await('oilrig:server:buyFromStock', false, function(ok)
        cb:resolve(ok)
    end, sellId, amount)
    return cb:wait()
end)
