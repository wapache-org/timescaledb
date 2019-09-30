-- This file and its contents are licensed under the Timescale License.
-- Please see the included NOTICE for copyright information and
-- LICENSE-TIMESCALE for a copy of the license.

\ir include/rand_generator.sql
\c :TEST_DBNAME :ROLE_SUPERUSER
\ir include/compression_utils.sql
\c :TEST_DBNAME :ROLE_DEFAULT_PERM_USER

CREATE TABLE test1 ("Time" timestamptz, i integer, b bigint, t text);
SELECT table_name from create_hypertable('test1', 'Time', chunk_time_interval=> INTERVAL '1 day');

INSERT INTO test1 SELECT t,  gen_rand_minstd(), gen_rand_minstd(), gen_rand_minstd()::text FROM generate_series('2018-03-02 1:00'::TIMESTAMPTZ, '2018-03-28 1:00', '1 hour') t;

ALTER TABLE test1 set (timescaledb.compress, timescaledb.compress_segmentby = '', timescaledb.compress_orderby = '"Time" DESC');

SELECT
  $$
  SELECT * FROM test1 ORDER BY "Time"
  $$ AS "QUERY" \gset

SELECT 'test1' AS "HYPERTABLE_NAME" \gset

\ir include/compression_test_hypertable.sql
\set TYPE timestamptz
\set ORDER_BY_COL_NAME Time
\set SEGMENT_META_COL_MIN _ts_meta_min_1
\set SEGMENT_META_COL_MAX _ts_meta_max_1
\ir include/compression_test_hypertable_segment_meta.sql

TRUNCATE test1;
/* should be no data in table */
SELECT * FROM test1;
/* nor compressed table */
SELECT * FROM _timescaledb_internal._compressed_hypertable_2;
/* the compressed table should have not chunks */
EXPLAIN (costs off) SELECT * FROM _timescaledb_internal._compressed_hypertable_2;

--add test for altered hypertable
CREATE TABLE test2 ("Time" timestamptz, i integer, b bigint, t text);
SELECT table_name from create_hypertable('test2', 'Time', chunk_time_interval=> INTERVAL '1 day');

--create some chunks with the old column numbers
INSERT INTO test2 SELECT t,  gen_rand_minstd(), gen_rand_minstd(), gen_rand_minstd()::text FROM generate_series('2018-03-02 1:00'::TIMESTAMPTZ, '2018-03-04 1:00', '1 hour') t;

ALTER TABLE test2 DROP COLUMN b;
--add default a value
ALTER TABLE test2 ADD COLUMN c INT DEFAULT -15;
--add default NULL
ALTER TABLE test2 ADD COLUMN d INT;

--write to both old chunks and new chunks with different column #s
INSERT INTO test2 SELECT t, gen_rand_minstd(), gen_rand_minstd()::text, gen_rand_minstd(), gen_rand_minstd() FROM generate_series('2018-03-02 1:00'::TIMESTAMPTZ, '2018-03-06 1:00', '1 hour') t;

ALTER TABLE test2 set (timescaledb.compress, timescaledb.compress_segmentby = '', timescaledb.compress_orderby = 'c, "Time" DESC');

SELECT
  $$
  SELECT * FROM test2 ORDER BY c, "Time"
  $$ AS "QUERY" \gset

SELECT 'test2' AS "HYPERTABLE_NAME" \gset
\ir include/compression_test_hypertable.sql

\set TYPE int
\set ORDER_BY_COL_NAME c
\set SEGMENT_META_COL_MIN _ts_meta_min_1
\set SEGMENT_META_COL_MAX _ts_meta_max_1
\ir include/compression_test_hypertable_segment_meta.sql

\set TYPE timestamptz
\set ORDER_BY_COL_NAME Time
\set SEGMENT_META_COL_MIN _ts_meta_min_2
\set SEGMENT_META_COL_MAX _ts_meta_max_2
\ir include/compression_test_hypertable_segment_meta.sql

--TEST4 create segments with > 1000 rows.
CREATE TABLE test4 (
      timec       TIMESTAMPTZ       NOT NULL,
      location    TEXT              NOT NULL,
      location2   char(10)          NOT NULL,
      temperature DOUBLE PRECISION  NULL,
      humidity    DOUBLE PRECISION  NULL
    );
--we want all the data to go into 1 chunk. so use 1 year chunk interval
select create_hypertable( 'test4', 'timec', chunk_time_interval=> '1 year'::interval);
alter table test4 set (timescaledb.compress, timescaledb.compress_segmentby = 'location', timescaledb.compress_orderby = 'timec');
insert into test4
select generate_series('2018-01-01 00:00'::timestamp, '2018-01-31 00:00'::timestamp, '1 day'), 'NYC', 'klick', 55, 75;
insert into test4
select generate_series('2018-02-01 00:00'::timestamp, '2018-02-14 00:00'::timestamp, '1 min'), 'POR', 'klick', 55, 75;
select table_name, num_chunks
from timescaledb_information.hypertable
where table_name like 'test4';

select location, count(*)
from test4
group by location;

SELECT $$ SELECT * FROM test4 ORDER BY timec $$ AS "QUERY" \gset

SELECT 'test4' AS "HYPERTABLE_NAME" \gset

\ir include/compression_test_hypertable.sql
\set TYPE TIMESTAMPTZ
\set ORDER_BY_COL_NAME timec
\set SEGMENT_META_COL_MIN _ts_meta_min_1
\set SEGMENT_META_COL_MAX _ts_meta_max_1
\ir include/compression_test_hypertable_segment_meta.sql


--add hypertable with order by a non by-val type with NULLs

CREATE TABLE test5 (
      time      TIMESTAMPTZ       NOT NULL,
      device_id   TEXT              NULL,
      temperature DOUBLE PRECISION  NULL
    );
--we want all the data to go into 1 chunk. so use 1 year chunk interval
select create_hypertable( 'test5', 'time', chunk_time_interval=> '1 day'::interval);
alter table test5 set (timescaledb.compress, timescaledb.compress_orderby = 'device_id, time');

insert into test5
select generate_series('2018-01-01 00:00'::timestamp, '2018-01-10 00:00'::timestamp, '2 hour'), 'device_1', gen_rand_minstd();
insert into test5
select generate_series('2018-01-01 00:00'::timestamp, '2018-01-10 00:00'::timestamp, '2 hour'), 'device_2', gen_rand_minstd();
insert into test5
select generate_series('2018-01-01 00:00'::timestamp, '2018-01-10 00:00'::timestamp, '2 hour'), NULL, gen_rand_minstd();


SELECT $$ SELECT * FROM test5 ORDER BY device_id, time $$ AS "QUERY" \gset

SELECT 'test5' AS "HYPERTABLE_NAME" \gset

\ir include/compression_test_hypertable.sql
\set TYPE TEXT
\set ORDER_BY_COL_NAME device_id
\set SEGMENT_META_COL_MIN _ts_meta_min_1
\set SEGMENT_META_COL_MAX _ts_meta_max_1
\ir include/compression_test_hypertable_segment_meta.sql

TRUNCATE test5;

SELECT * FROM test5;
