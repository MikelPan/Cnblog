#!/usr/bin/env sysbench


-- require("oltp_common")

-- function prepare_statements()
--    -- use 1 query per event, rather than sysbench.opt.point_selects which
--    -- defaults to 10 in other OLTP scripts
--    sysbench.opt.point_selects=1

--    prepare_point_selects()
-- end

-- function event()
--    execute_point_selects()
-- end

function thread_init()
  print(string.format("start thread %d",sysbench.tid))
end

function thread_done()
  print(string.format("stop thread %d",sysbench.tid))
end

function event()
end

