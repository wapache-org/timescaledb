-- This file and its contents are licensed under the Timescale License.
-- Please see the included NOTICE for copyright information and
-- LICENSE-TIMESCALE for a copy of the license.


-- this should use DecompressChunk node
:PREFIX SELECT * FROM :TEST_TABLE WHERE device_id = 1 ORDER BY time LIMIT 5;

-- test RECORD by itself
:PREFIX SELECT * FROM :TEST_TABLE WHERE device_id = 1 ORDER BY time;

-- test expressions
:PREFIX SELECT
  time_bucket('1d',time),
  v1 + v2 AS "sum",
  COALESCE(NULL,v1,v2) AS "coalesce",
  NULL AS "NULL",
  'text' AS "text",
  :TEST_TABLE AS "RECORD"
FROM :TEST_TABLE WHERE device_id IN (1,2) ORDER BY time, device_id;

-- test empty targetlist
:PREFIX SELECT FROM :TEST_TABLE;

-- test empty resultset
:PREFIX SELECT * FROM :TEST_TABLE WHERE device_id < 0;

-- test targetlist not referencing columns
:PREFIX SELECT 1 FROM :TEST_TABLE;

-- test constraints not present in targetlist
:PREFIX SELECT v1 FROM :TEST_TABLE WHERE device_id = 1 ORDER BY v1;

-- test order not present in targetlist
:PREFIX SELECT v2 FROM :TEST_TABLE WHERE device_id = 1 ORDER BY v1;

-- test column with all NULL
:PREFIX SELECT v3 FROM :TEST_TABLE WHERE device_id = 1;

--
-- test qual pushdown
--

-- v3 is not segment by or order by column so should not be pushed down
:PREFIX SELECT * FROM :TEST_TABLE WHERE v3 > 10.0 ORDER BY time, device_id;

-- device_id constraint should be pushed down
:PREFIX SELECT * FROM :TEST_TABLE WHERE device_id = 1 ORDER BY time, device_id LIMIT 10;

-- test IS NULL / IS NOT NULL
:PREFIX SELECT * FROM :TEST_TABLE WHERE device_id IS NOT NULL ORDER BY time, device_id LIMIT 10;
:PREFIX SELECT * FROM :TEST_TABLE WHERE device_id IS NULL ORDER BY time, device_id LIMIT 10;

-- test IN (Const,Const)
:PREFIX SELECT * FROM :TEST_TABLE WHERE device_id IN (1,2) ORDER BY time, device_id LIMIT 10;

-- test cast pushdown
:PREFIX SELECT * FROM :TEST_TABLE WHERE device_id = '1'::text::int ORDER BY time, device_id LIMIT 10;

--test var op var with two segment by
:PREFIX SELECT * FROM :TEST_TABLE WHERE device_id = device_id_peer ORDER BY time, device_id LIMIT 10;
:PREFIX SELECT * FROM :TEST_TABLE WHERE device_id_peer < device_id ORDER BY time, device_id LIMIT 10;

-- test expressions
:PREFIX SELECT * FROM :TEST_TABLE WHERE device_id =  1 + 4/2 ORDER BY time, device_id LIMIT 10;

-- test function calls
-- not yet pushed down
:PREFIX SELECT * FROM :TEST_TABLE WHERE device_id = length(substring(version(),1,3)) ORDER BY time, device_id LIMIT 10;

--
-- test segment meta pushdown
--

-- order by column and const
:PREFIX SELECT * FROM :TEST_TABLE WHERE time = '2000-01-01 1:00:00+0' ORDER BY time, device_id LIMIT 10;
:PREFIX SELECT * FROM :TEST_TABLE WHERE time < '2000-01-01 1:00:00+0' ORDER BY time, device_id LIMIT 10;
:PREFIX SELECT * FROM :TEST_TABLE WHERE time <= '2000-01-01 1:00:00+0' ORDER BY time, device_id LIMIT 10;
:PREFIX SELECT * FROM :TEST_TABLE WHERE time >= '2000-01-01 1:00:00+0' ORDER BY time, device_id LIMIT 10;
:PREFIX SELECT * FROM :TEST_TABLE WHERE time > '2000-01-01 1:00:00+0' ORDER BY time, device_id LIMIT 10;
:PREFIX SELECT * FROM :TEST_TABLE WHERE '2000-01-01 1:00:00+0' < time ORDER BY time, device_id LIMIT 10;

--pushdowns between order by and segment by columns
:PREFIX SELECT * FROM :TEST_TABLE WHERE v0 < 1 ORDER BY time, device_id LIMIT 10;
:PREFIX SELECT * FROM :TEST_TABLE WHERE v0 < device_id ORDER BY time, device_id LIMIT 10;
:PREFIX SELECT * FROM :TEST_TABLE WHERE device_id < v0 ORDER BY time, device_id LIMIT 10;
:PREFIX SELECT * FROM :TEST_TABLE WHERE v1 = device_id ORDER BY time, device_id LIMIT 10;

--pushdown between two order by column (not pushed down)
:PREFIX SELECT * FROM :TEST_TABLE WHERE v0 = v1 ORDER BY time, device_id LIMIT 10;

--pushdown of quals on order by and segment by cols anded together
:PREFIX SELECT * FROM :TEST_TABLE WHERE time > '2000-01-01 1:00:00+0' and device_id = 1 ORDER BY time, device_id LIMIT 10;

--pushdown of quals on order by and segment by cols or together (not pushed down)
:PREFIX SELECT * FROM :TEST_TABLE WHERE time > '2000-01-01 1:00:00+0' or device_id = 1 ORDER BY time, device_id LIMIT 10;

--functions not yet optimized
:PREFIX SELECT * FROM :TEST_TABLE WHERE time < now() ORDER BY time, device_id LIMIT 10;

--
-- test constraint exclusion
--

-- test plan time exclusion
-- first chunk should be excluded
:PREFIX SELECT * FROM :TEST_TABLE WHERE time > '2000-01-08' ORDER BY time, device_id;

-- test runtime exclusion
-- first chunk should be excluded
:PREFIX SELECT * FROM :TEST_TABLE WHERE time > '2000-01-08'::text::timestamptz ORDER BY time, device_id;

-- test aggregate
:PREFIX SELECT count(*) FROM :TEST_TABLE;

-- test aggregate with GROUP BY
:PREFIX SELECT count(*) FROM :TEST_TABLE GROUP BY device_id ORDER BY device_id;

-- test window functions with GROUP BY
:PREFIX SELECT sum(count(*)) OVER () FROM :TEST_TABLE GROUP BY device_id ORDER BY device_id;

-- test CTE
:PREFIX WITH
q AS (SELECT v1 FROM :TEST_TABLE ORDER BY time)
SELECT * FROM q ORDER BY v1;

-- test CTE join
:PREFIX WITH
q1 AS (SELECT time, v1 FROM :TEST_TABLE WHERE device_id=1 ORDER BY time),
q2 AS (SELECT time, v2 FROM :TEST_TABLE WHERE device_id=2 ORDER BY time)
SELECT * FROM q1 INNER JOIN q2 ON q1.time=q2.time ORDER BY q1.time;

-- test prepared statement
PREPARE prep AS SELECT count(time) FROM :TEST_TABLE WHERE device_id = 1;
:PREFIX EXECUTE prep;
EXECUTE prep;
EXECUTE prep;
EXECUTE prep;
EXECUTE prep;
EXECUTE prep;
EXECUTE prep;
DEALLOCATE prep;

-- test explicit self-join
-- XXX FIXME
-- :PREFIX SELECT * FROM :TEST_TABLE m1 INNER JOIN :TEST_TABLE m2 ON m1.time = m2.time ORDER BY m1.time;

-- test implicit self-join
-- XXX FIXME
-- :PREFIX SELECT * FROM :TEST_TABLE m1, :TEST_TABLE m2 WHERE m1.time = m2.time ORDER BY m1.time;

-- test self-join with sub-query
-- XXX FIXME
-- :PREFIX SELECT * FROM (SELECT * FROM :TEST_TABLE m1) m1 INNER JOIN (SELECT * FROM :TEST_TABLE m2) m2 ON m1.time = m2.time ORDER BY m1.time;

-- test system columns
-- XXX FIXME
--SELECT xmin FROM :TEST_TABLE ORDER BY time;

