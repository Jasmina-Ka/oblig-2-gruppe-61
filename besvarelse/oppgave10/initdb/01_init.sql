CREATE TABLE IF NOT EXISTS "Kurslogg" (
    id SERIAL PRIMARY KEY,
    fra_valuta VARCHAR(10) NOT NULL,
    til_valuta VARCHAR(10) NOT NULL,
    kurs NUMERIC(18,6),
    kilde VARCHAR(100),
    hendelse VARCHAR(20),
    ttl_sekunder INTEGER,
    responstid_ms INTEGER,
    tidspunkt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);