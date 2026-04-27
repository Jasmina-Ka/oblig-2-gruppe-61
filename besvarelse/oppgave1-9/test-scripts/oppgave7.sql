BEGIN;

DO $$
DECLARE
    v_tx_guid CHAR(32) := REPLACE(gen_random_uuid()::text, '-', '');
    v_bok_guid CHAR(32);
    v_valuta_guid CHAR(32);
    v_periode_guid CHAR(32);

    v_konto_6560 CHAR(32);
    v_konto_2710 CHAR(32);
    v_konto_2400 CHAR(32);

BEGIN
    -- hent nødvendige GUID-er
    SELECT guid INTO v_bok_guid FROM "Bøker" LIMIT 1;
    SELECT guid INTO v_valuta_guid FROM "Valutaer" WHERE kode = 'NOK';
    SELECT guid INTO v_periode_guid FROM "Regnskapsperioder" LIMIT 1;

    SELECT guid INTO v_konto_6560 FROM "Kontoer" WHERE kontonummer = 6560;
    SELECT guid INTO v_konto_2710 FROM "Kontoer" WHERE kontonummer = 2710;
    SELECT guid INTO v_konto_2400 FROM "Kontoer" WHERE kontonummer = 2400;

    -- transaksjon
    INSERT INTO "Transaksjoner"
    (guid, bok_guid, valuta_guid, bilagsnummer, bilagsdato,
     posteringsdato, beskrivelse, periode_guid)
    VALUES
    (v_tx_guid, v_bok_guid, v_valuta_guid, 'B-2026-OK', CURRENT_DATE,
     NOW(), 'Kjøp rekvisita (OK)', v_periode_guid);

    -- posteringer (balanse = 0)
    INSERT INTO "Posteringer"
    (guid, transaksjon_guid, konto_guid, tekst,
     belop_teller, belop_nevner)
    VALUES
    (REPLACE(gen_random_uuid()::text, '-', ''), v_tx_guid, v_konto_6560, 'Rekvisita', 200000, 100),
    (REPLACE(gen_random_uuid()::text, '-', ''), v_tx_guid, v_konto_2710, 'MVA', 50000, 100),
    (REPLACE(gen_random_uuid()::text, '-', ''), v_tx_guid, v_konto_2400, 'Gjeld', -250000, 100);

END $$;

COMMIT;