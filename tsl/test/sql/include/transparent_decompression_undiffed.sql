-- This file and its contents are licensed under the Timescale License.
-- Please see the included NOTICE for copyright information and
-- LICENSE-TIMESCALE for a copy of the license.

-- run query with parallel enabled to ensure nothing is preventing parallel execution
-- this is just a sanity check, the result queries dont run with parallel disabled
SET max_parallel_workers_per_gather TO 4;

SET parallel_setup_cost = 0;
SET parallel_tuple_cost = 0;

EXPLAIN (costs off) SELECT * FROM metrics ORDER BY time, device_id;
EXPLAIN (costs off) SELECT time_bucket('10 minutes', time) bucket, avg(v0) avg_v0 FROM metrics GROUP BY bucket;

EXPLAIN (costs off) SELECT * FROM metrics_space ORDER BY time, device_id;

RESET parallel_setup_cost;
RESET parallel_tuple_cost;

SET enable_seqscan TO false;
-- should order compressed chunks using index
-- (we only EXPLAIN here b/c the resulting order is too inconsistent)
EXPLAIN (costs off) SELECT * FROM metrics WHERE time > '2000-01-08' ORDER BY device_id;
EXPLAIN (costs off) SELECT * FROM metrics_space WHERE time > '2000-01-08' ORDER BY device_id;

SET enable_seqscan TO true;
