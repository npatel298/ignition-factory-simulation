-- Basic batch/MES tables (no TimescaleDB)
CREATE TABLE IF NOT EXISTS batches(
  id SERIAL PRIMARY KEY,
  product_code VARCHAR(64) NOT NULL,
  recipe_json JSON NOT NULL,
  state VARCHAR(16) NOT NULL DEFAULT 'Created',
  started_at TIMESTAMPTZ,
  ended_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS batch_steps(
  id SERIAL PRIMARY KEY,
  batch_id INT REFERENCES batches(id),
  step_no INT NOT NULL,
  unit VARCHAR(32) NOT NULL,
  phase VARCHAR(32) NOT NULL,
  params JSON NOT NULL,
  state VARCHAR(16) NOT NULL DEFAULT 'Pending',
  started_at TIMESTAMPTZ,
  ended_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS batch_events(
  id SERIAL PRIMARY KEY,
  batch_id INT REFERENCES batches(id),
  ts TIMESTAMPTZ DEFAULT now(),
  level VARCHAR(16),
  msg TEXT
);
