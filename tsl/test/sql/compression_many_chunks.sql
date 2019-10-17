-- This file and its contents are licensed under the Timescale License.
-- Please see the included NOTICE for copyright information and
-- LICENSE-TIMESCALE for a copy of the license.

-- test planning regression with many chunks
-- This test haves weirdly on arm so separate out
CREATE TABLE tags(id SERIAL PRIMARY KEY, name TEXT, fleet TEXT);
INSERT INTO tags (name, fleet) VALUES('n1', 'f1');

CREATE TABLE readings (time timestamptz, tags_id integer, fuel_consumption DOUBLE PRECISION);
CREATE INDEX ON readings(tags_id, "time" DESC);
CREATE INDEX ON readings("time" DESC);
SELECT create_hypertable('readings', 'time', partitioning_column => 'tags_id', number_partitions => 1, chunk_time_interval => 43200000000, create_default_indexes=>false);
ALTER TABLE readings SET (timescaledb.compress, timescaledb.compress_segmentby = 'tags_id', timescaledb.compress_orderby = 'time desc');

INSERT into readings select g, 1, 1.3 from generate_series('2001-03-01 01:01:01', '2003-02-01 01:01:01', '1 day'::interval) g;

SELECT count(compress_chunk(chunk.schema_name|| '.' || chunk.table_name))
FROM _timescaledb_catalog.chunk chunk
INNER JOIN _timescaledb_catalog.hypertable hypertable ON (chunk.hypertable_id = hypertable.id)
WHERE hypertable.table_name = 'readings' and chunk.compressed_chunk_id IS NULL;

SELECT t.fleet as fleet, min(r.fuel_consumption) AS avg_fuel_consumption
FROM tags t
INNER JOIN LATERAL(SELECT tags_id, fuel_consumption FROM readings r WHERE r.tags_id = t.id ) r ON true
GROUP BY fleet;
