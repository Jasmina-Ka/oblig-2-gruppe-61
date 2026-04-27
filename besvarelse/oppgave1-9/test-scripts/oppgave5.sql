-- Oppgave 5
-- Ytelsesanalyse med EXPLAIN ANALYZE og MATERIALIZED VIEW
-- Forutsetter at oppgave1.sql og oppgave2.sql allerede er kjørt

BEGIN;

-- =========================================================
-- DEL A: Opprett forretnings-tabeller
-- =========================================================

CREATE TABLE IF NOT EXISTS "Betalingsbetingelser" (
    guid                CHAR(32) PRIMARY KEY,
    navn                VARCHAR(100) NOT NULL,
    dager_til_forfall   INTEGER NOT NULL DEFAULT 30,
    rabatt_prosent      NUMERIC(5,2) DEFAULT 0,
    rabatt_dager        INTEGER DEFAULT 0
);

CREATE TABLE IF NOT EXISTS "Kunder" (
    guid                        CHAR(32) PRIMARY KEY,
    bok_guid                    CHAR(32) NOT NULL REFERENCES "Bøker"(guid),
    navn                        VARCHAR(200) NOT NULL,
    organisasjonsnr             VARCHAR(20),
    epost                       VARCHAR(200),
    betalingsbetingelse_guid    CHAR(32) REFERENCES "Betalingsbetingelser"(guid)
);

CREATE TABLE IF NOT EXISTS "Fakturaer" (
    guid                CHAR(32) PRIMARY KEY,
    bok_guid            CHAR(32) NOT NULL REFERENCES "Bøker"(guid),
    fakturanummer       VARCHAR(30) NOT NULL UNIQUE,
    type                VARCHAR(10) NOT NULL CHECK (type IN ('SALG', 'KJØP', 'UTGIFT')),
    status              VARCHAR(15) NOT NULL DEFAULT 'UTKAST'
                            CHECK (status IN ('UTKAST', 'SENDT', 'BETALT', 'KREDITERT')),
    kunde_guid          CHAR(32) REFERENCES "Kunder"(guid),
    fakturadato         DATE NOT NULL,
    forfallsdato        DATE NOT NULL,
    valuta_guid         CHAR(32) NOT NULL REFERENCES "Valutaer"(guid),
    transaksjon_guid    CHAR(32) REFERENCES "Transaksjoner"(guid)
);

CREATE TABLE IF NOT EXISTS "Fakturalinjer" (
    guid                    CHAR(32) PRIMARY KEY,
    faktura_guid            CHAR(32) NOT NULL REFERENCES "Fakturaer"(guid) ON DELETE CASCADE,
    beskrivelse             VARCHAR(500) NOT NULL,
    antall                  NUMERIC(12,4) NOT NULL DEFAULT 1,
    enhetspris_teller       BIGINT NOT NULL,
    enhetspris_nevner       INTEGER NOT NULL DEFAULT 100 CHECK (enhetspris_nevner > 0),
    mva_kode_guid           CHAR(32) REFERENCES "MVA-koder"(guid),
    inntektskonto_guid      CHAR(32) REFERENCES "Kontoer"(guid)
);

-- =========================================================
-- DEL B: Indekser for bedre ytelse
-- =========================================================

CREATE INDEX IF NOT EXISTS idx_kunder_bok_guid
    ON "Kunder"(bok_guid);

CREATE INDEX IF NOT EXISTS idx_fakturaer_bok_guid
    ON "Fakturaer"(bok_guid);

CREATE INDEX IF NOT EXISTS idx_fakturaer_kunde_guid
    ON "Fakturaer"(kunde_guid);

CREATE INDEX IF NOT EXISTS idx_fakturaer_transaksjon_guid
    ON "Fakturaer"(transaksjon_guid);

CREATE INDEX IF NOT EXISTS idx_fakturalinjer_faktura_guid
    ON "Fakturalinjer"(faktura_guid);

CREATE INDEX IF NOT EXISTS idx_fakturalinjer_mva_kode_guid
    ON "Fakturalinjer"(mva_kode_guid);

CREATE INDEX IF NOT EXISTS idx_fakturalinjer_inntektskonto_guid
    ON "Fakturalinjer"(inntektskonto_guid);

-- Ekstra indeks brukt i rapportdelen med EXPLAIN ANALYZE
CREATE INDEX IF NOT EXISTS idx_posteringer_konto_guid_oppg5
    ON "Posteringer"(konto_guid);

-- =========================================================
-- DEL C: Testdata
-- =========================================================

-- Betalingsbetingelser
INSERT INTO "Betalingsbetingelser" (guid, navn, dager_til_forfall, rabatt_prosent, rabatt_dager)
SELECT
    'BETALING000000000000000000000001',
    '30 dager netto',
    30,
    0,
    0
WHERE NOT EXISTS (
    SELECT 1
    FROM "Betalingsbetingelser"
    WHERE guid = 'BETALING000000000000000000000001'
);

-- Kunder
INSERT INTO "Kunder" (guid, bok_guid, navn, organisasjonsnr, epost, betalingsbetingelse_guid)
SELECT
    'KUNDE000000000000000000000000001',
    'BOK0000000000000000000000000001',
    'TechNord AS',
    '123456789',
    'regnskap@technord.no',
    'BETALING000000000000000000000001'
WHERE NOT EXISTS (
    SELECT 1
    FROM "Kunder"
    WHERE guid = 'KUNDE000000000000000000000000001'
);

INSERT INTO "Kunder" (guid, bok_guid, navn, organisasjonsnr, epost, betalingsbetingelse_guid)
SELECT
    'KUNDE000000000000000000000000002',
    'BOK0000000000000000000000000001',
    'Göteborg Tech AB',
    '556789012',
    'invoice@goteborgtech.se',
    'BETALING000000000000000000000001'
WHERE NOT EXISTS (
    SELECT 1
    FROM "Kunder"
    WHERE guid = 'KUNDE000000000000000000000000002'
);

-- Faktura 1: koblet til scenario 3 i oppgave2 (TechNord AS)
INSERT INTO "Fakturaer" (
    guid, bok_guid, fakturanummer, type, status, kunde_guid,
    fakturadato, forfallsdato, valuta_guid, transaksjon_guid
)
SELECT
    'FAKTURA000000000000000000000001',
    'BOK0000000000000000000000000001',
    'F-2026-001',
    'SALG',
    'BETALT',
    'KUNDE000000000000000000000000001',
    '2026-02-10',
    '2026-03-12',
    'VALUTA00000000000000000000000001',
    'TX000000000000000000000000000003'
WHERE NOT EXISTS (
    SELECT 1
    FROM "Fakturaer"
    WHERE guid = 'FAKTURA000000000000000000000001'
);

-- Fakturalinje 1: 50 timer à 1 000 NOK = 50 000 eks. mva
INSERT INTO "Fakturalinjer" (
    guid, faktura_guid, beskrivelse, antall,
    enhetspris_teller, enhetspris_nevner, mva_kode_guid, inntektskonto_guid
)
SELECT
    'FAKTURALINJE00000000000000000001',
    'FAKTURA000000000000000000000001',
    'Konsulentbistand februar 2026',
    50,
    100000,
    100,
    'MVAKODE000000000000000000000001',
    'KONTO00000000000000000000003100'
WHERE NOT EXISTS (
    SELECT 1
    FROM "Fakturalinjer"
    WHERE guid = 'FAKTURALINJE00000000000000000001'
);

-- Faktura 2: koblet til scenario 8A i oppgave2 (Göteborg Tech AB)
INSERT INTO "Fakturaer" (
    guid, bok_guid, fakturanummer, type, status, kunde_guid,
    fakturadato, forfallsdato, valuta_guid, transaksjon_guid
)
SELECT
    'FAKTURA000000000000000000000002',
    'BOK0000000000000000000000000001',
    'F-2026-002',
    'SALG',
    'BETALT',
    'KUNDE000000000000000000000000002',
    '2026-04-10',
    '2026-05-10',
    'VALUTA00000000000000000000000003',
    'TX000000000000000000000000000009'
WHERE NOT EXISTS (
    SELECT 1
    FROM "Fakturaer"
    WHERE guid = 'FAKTURA000000000000000000000002'
);

-- Fakturalinje 2: 100 timer à 500 SEK = 50 000 SEK, uten MVA
INSERT INTO "Fakturalinjer" (
    guid, faktura_guid, beskrivelse, antall,
    enhetspris_teller, enhetspris_nevner, mva_kode_guid, inntektskonto_guid
)
SELECT
    'FAKTURALINJE00000000000000000002',
    'FAKTURA000000000000000000000002',
    'Systemutvikling april 2026',
    100,
    50000,
    100,
    NULL,
    'KONTO00000000000000000000003100'
WHERE NOT EXISTS (
    SELECT 1
    FROM "Fakturalinjer"
    WHERE guid = 'FAKTURALINJE00000000000000000002'
);

COMMIT;

-- =========================================================
-- DEL D: VIEW for salgsrapport
-- =========================================================

CREATE OR REPLACE VIEW v_salgsrapport AS
SELECT
    k.navn AS kundenavn,
    f.fakturanummer,
    f.fakturadato,
    v.kode AS valuta,
    fl.beskrivelse,
    fl.antall,
    (fl.enhetspris_teller::numeric / fl.enhetspris_nevner) AS enhetspris_eks_mva,
    (fl.antall * (fl.enhetspris_teller::numeric / fl.enhetspris_nevner)) AS linjesum_eks_mva,
    COALESCE(mk.sats_teller::numeric / mk.sats_nevner, 0) AS mva_sats,
    (fl.antall * (fl.enhetspris_teller::numeric / fl.enhetspris_nevner))
        * COALESCE(mk.sats_teller::numeric / mk.sats_nevner, 0) AS mva_belop,
    (fl.antall * (fl.enhetspris_teller::numeric / fl.enhetspris_nevner))
        * (1 + COALESCE(mk.sats_teller::numeric / mk.sats_nevner, 0)) AS total_inkl_mva
FROM "Fakturaer" f
JOIN "Kunder" k
    ON f.kunde_guid = k.guid
JOIN "Valutaer" v
    ON f.valuta_guid = v.guid
JOIN "Fakturalinjer" fl
    ON fl.faktura_guid = f.guid
LEFT JOIN "MVA-koder" mk
    ON fl.mva_kode_guid = mk.guid;

-- =========================================================
-- DEL E: MATERIALIZED VIEW for saldo per konto
-- =========================================================

DROP MATERIALIZED VIEW IF EXISTS mv_saldo_per_konto;

CREATE MATERIALIZED VIEW mv_saldo_per_konto AS
SELECT
    k.guid,
    k.kontonummer,
    k.navn,
    COALESCE(SUM(p.belop_teller::numeric / p.belop_nevner), 0) AS saldo
FROM "Kontoer" k
LEFT JOIN "Posteringer" p
    ON p.konto_guid = k.guid
GROUP BY
    k.guid,
    k.kontonummer,
    k.navn;

CREATE INDEX IF NOT EXISTS idx_mv_saldo_per_konto_kontonummer
    ON mv_saldo_per_konto(kontonummer);

-- Oppdateres ved behov
REFRESH MATERIALIZED VIEW mv_saldo_per_konto;

-- =========================================================
-- DEL F: Verifikasjon
-- =========================================================

-- 1. Salgsrapport
SELECT * FROM v_salgsrapport ORDER BY fakturadato, fakturanummer;

-- 2. Materialized view
SELECT * FROM mv_saldo_per_konto ORDER BY kontonummer NULLS FIRST;

-- 3. EXPLAIN ANALYZE-eksempel
EXPLAIN ANALYZE
SELECT *
FROM "Posteringer"
WHERE konto_guid = 'KONTO00000000000000000000001920';