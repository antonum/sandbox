-- Based on:
-- - https://docs.timescale.com/tutorials/latest/blockchain-analyze/blockchain-dataset/
-- - https://docs.timescale.com/tutorials/latest/blockchain-analyze/analyze-blockchain-query/
\timing on

DROP TABLE transactions CASCADE;

-- Create regular PostgreSQL table for transactions
CREATE TABLE transactions (
   time TIMESTAMPTZ,
   block_id INT,
   hash TEXT,
   size INT,
   weight INT,
   is_coinbase BOOLEAN,
   output_total BIGINT,
   output_total_usd DOUBLE PRECISION,
   fee BIGINT,
   fee_usd DOUBLE PRECISION,
   details JSONB
);

-- Convert the regular table into a hypertable
SELECT create_hypertable('transactions', by_range('time', INTERVAL '1 day'));



-- Create an index on the hash column to make queries for individual transactions faster:
CREATE INDEX hash_idx ON public.transactions USING HASH (hash);

-- Create an index on the block_id column to make block-level queries faster:
CREATE INDEX block_idx ON public.transactions (block_id);

-- Create a unique index on the time and hash columns to make sure you don't accidentally insert duplicate records:
CREATE UNIQUE INDEX time_hash_idx ON public.transactions (time, hash);

-- Download data
\! wget https://assets.timescale.com/docs/downloads/bitcoin-blockchain/bitcoin_sample.zip

-- Unzip data
\! unzip bitcoin_sample.zip


-- Load data into the transactions table
\COPY transactions FROM 'tutorial_bitcoin_sample.csv' CSV HEADER;

-- Cleanup
\! rm bitcoin_sample.zip
\! rm tutorial_bitcoin_sample.csv

-- Preview data
select * from transactions 
limit 10;

ALTER TABLE transactions 
SET (
    timescaledb.enable_columnstore = true, 
    timescaledb.segmentby = '' 
    --'block_id' 265MB compressed 
    -- '' 265MB compressed
    timescaledb.compress_orderby='time DESC'
);
-- Create a compression policy to compress chunks older than 7 days
-- SELECT add_compression_policy('transactions', INTERVAL '7 days');

-- Manual compress/decompress
SELECT compress_chunk(c, true) FROM show_chunks('transactions') c;
 -- SELECT decompress_chunk(c, true) FROM show_chunks('transactions') c;

SELECT 
  pg_size_pretty(before_compression_total_bytes) as before,
  pg_size_pretty(after_compression_total_bytes) as after
FROM hypertable_compression_stats('transactions');
--  before  │ after  
-- ─────────┼────────
--  1680 MB │ 265 MB

select 
  chunk_name,
  pg_size_pretty(before_compression_total_bytes) as before_total,
  pg_size_pretty(after_compression_total_bytes) as after_total,
  pg_size_pretty(before_compression_table_bytes) as  before_table,
  pg_size_pretty(after_compression_table_bytes) as after_table,
  pg_size_pretty(before_compression_index_bytes) as before_index,
  pg_size_pretty(after_compression_index_bytes) as after_index,
  pg_size_pretty(before_compression_toast_bytes) as before_toast,
  pg_size_pretty(after_compression_toast_bytes) as after_toast
from chunk_compression_stats('transactions'); 


SELECT time_bucket('1 hour', time) AS bucket,
   block_id,
   sum(fee) AS block_fee_sat,
   sum(fee_usd) AS block_fee_usd,
   --stats_agg(fee) AS stats_tx_fee_sat,
   --avg(size) AS avg_tx_size,
   --avg(weight) AS avg_tx_weight,
   --sum(size) AS block_size,
   --sum(weight) AS block_weight,
   --max(size) AS max_tx_size,
   --max(weight) AS max_tx_weight,
   --min(size) AS min_tx_size,
   --min(weight) AS min_tx_weight
   count(*) AS tx_count
FROM transactions
WHERE is_coinbase IS NOT TRUE
GROUP BY bucket, block_id;