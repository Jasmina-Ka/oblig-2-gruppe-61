-- Oppgave 2
-- Populering med testdata

-- =========================
-- VALUTAER
-- =========================
INSERT INTO "Valutaer" (guid, kode, navn, desimaler, hent_kurs_flag, kurs_kilde)
VALUES
    ('VALUTA00000000000000000000000001', 'NOK', 'Norske kroner', 100, 0, 'manuell'),
    ('VALUTA00000000000000000000000002', 'USD', 'Amerikanske dollar', 100, 0, 'manuell'),
    ('VALUTA00000000000000000000000003', 'SEK', 'Svenske kroner', 100, 0, 'manuell');

-- =========================
-- BØKER
-- =========================
INSERT INTO "Bøker" (guid, navn, organisasjonsnr, adresse, regnskapsaar)
VALUES
    ('BOK0000000000000000000000000001', 'DATA1500 Konsult AS Regnskap', '123456789', 'Oslo, Norge', '2026-01-01');

-- =========================
-- KONTOKLASSER
-- =========================
INSERT INTO "Kontoklasser" (klasse_nr, navn, type, normal_saldo, beskrivelse)
VALUES
    (1, 'Eiendeler', 'BALANSE', 'DEBET', 'Eiendeler og omløpsmidler'),
    (2, 'Egenkapital og gjeld', 'BALANSE', 'KREDIT', 'Egenkapital og forpliktelser'),
    (3, 'Salgsinntekter', 'RESULTAT', 'KREDIT', 'Driftsinntekter fra salg'),
    (4, 'Varekostnad', 'RESULTAT', 'DEBET', 'Kostnad knyttet til solgte varer'),
    (5, 'Lønnskostnad', 'RESULTAT', 'DEBET', 'Lønn og relaterte kostnader'),
    (6, 'Annen driftskostnad', 'RESULTAT', 'DEBET', 'Andre driftskostnader'),
    (7, 'Andre driftskostnader', 'RESULTAT', 'DEBET', 'Ytterligere driftskostnader'),
    (8, 'Finansposter', 'RESULTAT', 'DEBET', 'Finansinntekter og finanskostnader');

-- =========================
-- KONTOER
-- Rotkonto + klassekontoer + driftskontoer
-- =========================
INSERT INTO "Kontoer" (
    guid, bok_guid, overordnet_guid, valuta_guid, kontonummer, kontoklasse,
    gnucash_type, navn, beskrivelse, er_placeholder, er_skjult, mva_pliktig, mva_kode_guid
)
VALUES
    -- Rotkonto
    (
        'KONTO00000000000000000000000001',
        'BOK0000000000000000000000000001',
        NULL,
        'VALUTA00000000000000000000000001',
        NULL,
        1,
        'ROOT',
        'Rotkonto',
        'Øverste konto i kontohierarkiet',
        TRUE,
        FALSE,
        FALSE,
        NULL
    ),

    -- Klassekontoer (placeholders)
    (
        'KONTO00000000000000000000000011',
        'BOK0000000000000000000000000001',
        'KONTO00000000000000000000000001',
        'VALUTA00000000000000000000000001',
        NULL,
        1,
        'ASSET',
        'Eiendeler',
        'Klasse 1',
        TRUE,
        FALSE,
        FALSE,
        NULL
    ),
    (
        'KONTO00000000000000000000000012',
        'BOK0000000000000000000000000001',
        'KONTO00000000000000000000000001',
        'VALUTA00000000000000000000000001',
        NULL,
        2,
        'LIABILITY',
        'Egenkapital og gjeld',
        'Klasse 2',
        TRUE,
        FALSE,
        FALSE,
        NULL
    ),
    (
        'KONTO00000000000000000000000013',
        'BOK0000000000000000000000000001',
        'KONTO00000000000000000000000001',
        'VALUTA00000000000000000000000001',
        NULL,
        3,
        'INCOME',
        'Salgsinntekter',
        'Klasse 3',
        TRUE,
        FALSE,
        FALSE,
        NULL
    ),
    (
        'KONTO00000000000000000000000014',
        'BOK0000000000000000000000000001',
        'KONTO00000000000000000000000001',
        'VALUTA00000000000000000000000001',
        NULL,
        4,
        'EXPENSE',
        'Varekostnad',
        'Klasse 4',
        TRUE,
        FALSE,
        FALSE,
        NULL
    ),
    (
        'KONTO00000000000000000000000015',
        'BOK0000000000000000000000000001',
        'KONTO00000000000000000000000001',
        'VALUTA00000000000000000000000001',
        NULL,
        5,
        'EXPENSE',
        'Lønnskostnad',
        'Klasse 5',
        TRUE,
        FALSE,
        FALSE,
        NULL
    ),
    (
        'KONTO00000000000000000000000016',
        'BOK0000000000000000000000000001',
        'KONTO00000000000000000000000001',
        'VALUTA00000000000000000000000001',
        NULL,
        6,
        'EXPENSE',
        'Annen driftskostnad',
        'Klasse 6',
        TRUE,
        FALSE,
        FALSE,
        NULL
    ),
    (
        'KONTO00000000000000000000000017',
        'BOK0000000000000000000000000001',
        'KONTO00000000000000000000000001',
        'VALUTA00000000000000000000000001',
        NULL,
        7,
        'EXPENSE',
        'Andre driftskostnader',
        'Klasse 7',
        TRUE,
        FALSE,
        FALSE,
        NULL
    ),
    (
        'KONTO00000000000000000000000018',
        'BOK0000000000000000000000000001',
        'KONTO00000000000000000000000001',
        'VALUTA00000000000000000000000001',
        NULL,
        8,
        'EXPENSE',
        'Finansposter',
        'Klasse 8',
        TRUE,
        FALSE,
        FALSE,
        NULL
    ),

    -- Driftskontoer brukt i scenariene
    (
        'KONTO00000000000000000000001920',
        'BOK0000000000000000000000000001',
        'KONTO00000000000000000000000011',
        'VALUTA00000000000000000000000001',
        1920,
        1,
        'BANK',
        'Bankinnskudd',
        'Bedriftens bankkonto',
        FALSE,
        FALSE,
        FALSE,
        NULL
    ),
    (
        'KONTO00000000000000000000001500',
        'BOK0000000000000000000000000001',
        'KONTO00000000000000000000000011',
        'VALUTA00000000000000000000000001',
        1500,
        1,
        'RECEIVABLE',
        'Kundefordringer',
        'Fordringer på kunder',
        FALSE,
        FALSE,
        FALSE,
        NULL
    ),
    (
        'KONTO00000000000000000000001350',
        'BOK0000000000000000000000000001',
        'KONTO00000000000000000000000011',
        'VALUTA00000000000000000000000002',
        1350,
        1,
        'STOCK',
        'Aksjer i utenlandske selskaper',
        'Investeringer i utenlandske aksjer',
        FALSE,
        FALSE,
        FALSE,
        NULL
    ),
    (
        'KONTO00000000000000000000002000',
        'BOK0000000000000000000000000001',
        'KONTO00000000000000000000000012',
        'VALUTA00000000000000000000000001',
        2000,
        2,
        'EQUITY',
        'Aksjekapital',
        'Innskutt aksjekapital',
        FALSE,
        FALSE,
        FALSE,
        NULL
    ),
    (
        'KONTO00000000000000000000002400',
        'BOK0000000000000000000000000001',
        'KONTO00000000000000000000000012',
        'VALUTA00000000000000000000000001',
        2400,
        2,
        'PAYABLE',
        'Leverandørgjeld',
        'Gjeld til leverandører',
        FALSE,
        FALSE,
        FALSE,
        NULL
    ),
    (
        'KONTO00000000000000000000002600',
        'BOK0000000000000000000000000001',
        'KONTO00000000000000000000000012',
        'VALUTA00000000000000000000000001',
        2600,
        2,
        'LIABILITY',
        'Forskuddstrekk',
        'Skyldig forskuddstrekk',
        FALSE,
        FALSE,
        FALSE,
        NULL
    ),
    (
        'KONTO00000000000000000000002700',
        'BOK0000000000000000000000000001',
        'KONTO00000000000000000000000012',
        'VALUTA00000000000000000000000001',
        2700,
        2,
        'LIABILITY',
        'Utgående MVA, høy sats',
        'Skyldig utgående MVA',
        FALSE,
        FALSE,
        FALSE,
        NULL
    ),
    (
        'KONTO00000000000000000000002710',
        'BOK0000000000000000000000000001',
        'KONTO00000000000000000000000011',
        'VALUTA00000000000000000000000001',
        2710,
        2,
        'ASSET',
        'Inngående MVA, høy sats',
        'Fradragsberettiget inngående MVA',
        FALSE,
        FALSE,
        FALSE,
        NULL
    ),
    (
        'KONTO00000000000000000000002740',
        'BOK0000000000000000000000000001',
        'KONTO00000000000000000000000012',
        'VALUTA00000000000000000000000001',
        2740,
        2,
        'LIABILITY',
        'Oppgjørskonto MVA',
        'Oppgjørskonto for MVA',
        FALSE,
        FALSE,
        FALSE,
        NULL
    ),
    (
        'KONTO00000000000000000000002780',
        'BOK0000000000000000000000000001',
        'KONTO00000000000000000000000012',
        'VALUTA00000000000000000000000001',
        2780,
        2,
        'LIABILITY',
        'Skyldig arbeidsgiveravgift',
        'Skyldig arbeidsgiveravgift',
        FALSE,
        FALSE,
        FALSE,
        NULL
    ),
    (
        'KONTO00000000000000000000003100',
        'BOK0000000000000000000000000001',
        'KONTO00000000000000000000000013',
        'VALUTA00000000000000000000000001',
        3100,
        3,
        'INCOME',
        'Salgsinntekt, tjenester',
        'Inntekter fra salg av tjenester',
        FALSE,
        FALSE,
        TRUE,
        NULL
    ),
    (
        'KONTO00000000000000000000005000',
        'BOK0000000000000000000000000001',
        'KONTO00000000000000000000000015',
        'VALUTA00000000000000000000000001',
        5000,
        5,
        'EXPENSE',
        'Lønn til ansatte',
        'Bruttolønn',
        FALSE,
        FALSE,
        FALSE,
        NULL
    ),
    (
        'KONTO00000000000000000000005400',
        'BOK0000000000000000000000000001',
        'KONTO00000000000000000000000015',
        'VALUTA00000000000000000000000001',
        5400,
        5,
        'EXPENSE',
        'Arbeidsgiveravgift',
        'Arbeidsgiveravgift',
        FALSE,
        FALSE,
        FALSE,
        NULL
    ),
    (
        'KONTO00000000000000000000006560',
        'BOK0000000000000000000000000001',
        'KONTO00000000000000000000000016',
        'VALUTA00000000000000000000000001',
        6560,
        6,
        'EXPENSE',
        'Rekvisita',
        'Kontorrekvisita',
        FALSE,
        FALSE,
        TRUE,
        NULL
    ),
    (
        'KONTO00000000000000000000008160',
        'BOK0000000000000000000000000001',
        'KONTO00000000000000000000000018',
        'VALUTA00000000000000000000000001',
        8160,
        8,
        'EXPENSE',
        'Valutatap (disagio)',
        'Tap ved valutakursendring',
        FALSE,
        FALSE,
        FALSE,
        NULL
    );

-- =========================
-- OPPDATER BØKER MED ROTKONTO
-- =========================
UPDATE "Bøker"
SET rot_konto_guid = 'KONTO00000000000000000000000001'
WHERE guid = 'BOK0000000000000000000000000001';

-- =========================
-- MVA-KODER
-- =========================
INSERT INTO "MVA-koder" (guid, kode, navn, type, sats_teller, sats_nevner, mva_konto_guid, aktiv)
VALUES
    ('MVAKODE000000000000000000000001', '1', 'Utgående MVA, høy sats (25%)', 'UTGAAENDE', 25, 100, 'KONTO00000000000000000000002700', TRUE),
    ('MVAKODE000000000000000000000002', '11', 'Inngående MVA, høy sats (25%)', 'INNGAAENDE', 25, 100, 'KONTO00000000000000000000002710', TRUE);

-- =========================
-- KOBLE STANDARD MVA-KODER TIL KONTOER
-- =========================
UPDATE "Kontoer"
SET mva_kode_guid = 'MVAKODE000000000000000000000001'
WHERE guid = 'KONTO00000000000000000000003100';

UPDATE "Kontoer"
SET mva_kode_guid = 'MVAKODE000000000000000000000002'
WHERE guid = 'KONTO00000000000000000000006560';

-- =========================
-- REGNSKAPSPERIODER (12 måneder i 2026)
-- =========================
INSERT INTO "Regnskapsperioder" (guid, bok_guid, navn, fra_dato, til_dato, status)
VALUES
    ('PERIODE000000000000000000000001', 'BOK0000000000000000000000000001', 'Januar 2026',    '2026-01-01', '2026-01-31', 'AAPEN'),
    ('PERIODE000000000000000000000002', 'BOK0000000000000000000000000001', 'Februar 2026',   '2026-02-01', '2026-02-28', 'AAPEN'),
    ('PERIODE000000000000000000000003', 'BOK0000000000000000000000000001', 'Mars 2026',      '2026-03-01', '2026-03-31', 'AAPEN'),
    ('PERIODE000000000000000000000004', 'BOK0000000000000000000000000001', 'April 2026',     '2026-04-01', '2026-04-30', 'AAPEN'),
    ('PERIODE000000000000000000000005', 'BOK0000000000000000000000000001', 'Mai 2026',       '2026-05-01', '2026-05-31', 'AAPEN'),
    ('PERIODE000000000000000000000006', 'BOK0000000000000000000000000001', 'Juni 2026',      '2026-06-01', '2026-06-30', 'AAPEN'),
    ('PERIODE000000000000000000000007', 'BOK0000000000000000000000000001', 'Juli 2026',      '2026-07-01', '2026-07-31', 'AAPEN'),
    ('PERIODE000000000000000000000008', 'BOK0000000000000000000000000001', 'August 2026',    '2026-08-01', '2026-08-31', 'AAPEN'),
    ('PERIODE000000000000000000000009', 'BOK0000000000000000000000000001', 'September 2026', '2026-09-01', '2026-09-30', 'AAPEN'),
    ('PERIODE000000000000000000000010', 'BOK0000000000000000000000000001', 'Oktober 2026',   '2026-10-01', '2026-10-31', 'AAPEN'),
    ('PERIODE000000000000000000000011', 'BOK0000000000000000000000000001', 'November 2026',  '2026-11-01', '2026-11-30', 'AAPEN'),
    ('PERIODE000000000000000000000012', 'BOK0000000000000000000000000001', 'Desember 2026',  '2026-12-01', '2026-12-31', 'AAPEN');

-- =========================
-- VALUTAKURSER
-- =========================
INSERT INTO "Valutakurser" (
    guid, fra_valuta_guid, til_valuta_guid, dato, kilde, type, kurs_teller, kurs_nevner
)
VALUES
    ('KURS000000000000000000000000001', 'VALUTA00000000000000000000000002', 'VALUTA00000000000000000000000001',
     '2026-03-15 10:00:00', 'manuell', 'last', 1050, 100),
    ('KURS000000000000000000000000002', 'VALUTA00000000000000000000000003', 'VALUTA00000000000000000000000001',
     '2026-04-10 10:00:00', 'manuell', 'last', 102, 100),
    ('KURS000000000000000000000000003', 'VALUTA00000000000000000000000003', 'VALUTA00000000000000000000000001',
     '2026-05-10 10:00:00', 'manuell', 'last', 98, 100);

-- =========================
-- TRANSAKSJONER OG POSTERINGER
-- Alle scenarier 1–8
-- =========================
DO $$
DECLARE
    v_bok_guid      CHAR(32) := 'BOK0000000000000000000000000001';
    v_nok_guid      CHAR(32) := 'VALUTA00000000000000000000000001';

    v_jan_guid      CHAR(32) := 'PERIODE000000000000000000000001';
    v_feb_guid      CHAR(32) := 'PERIODE000000000000000000000002';
    v_mar_guid      CHAR(32) := 'PERIODE000000000000000000000003';
    v_apr_guid      CHAR(32) := 'PERIODE000000000000000000000004';
    v_mai_guid      CHAR(32) := 'PERIODE000000000000000000000005';

    v_konto_1920    CHAR(32) := 'KONTO00000000000000000000001920';
    v_konto_2000    CHAR(32) := 'KONTO00000000000000000000002000';
    v_konto_6560    CHAR(32) := 'KONTO00000000000000000000006560';
    v_konto_2710    CHAR(32) := 'KONTO00000000000000000000002710';
    v_konto_2400    CHAR(32) := 'KONTO00000000000000000000002400';
    v_konto_1500    CHAR(32) := 'KONTO00000000000000000000001500';
    v_konto_3100    CHAR(32) := 'KONTO00000000000000000000003100';
    v_konto_2700    CHAR(32) := 'KONTO00000000000000000000002700';
    v_konto_2740    CHAR(32) := 'KONTO00000000000000000000002740';
    v_konto_5000    CHAR(32) := 'KONTO00000000000000000000005000';
    v_konto_2600    CHAR(32) := 'KONTO00000000000000000000002600';
    v_konto_5400    CHAR(32) := 'KONTO00000000000000000000005400';
    v_konto_2780    CHAR(32) := 'KONTO00000000000000000000002780';
    v_konto_1350    CHAR(32) := 'KONTO00000000000000000000001350';
    v_konto_8160    CHAR(32) := 'KONTO00000000000000000000008160';

    v_mva_ut_guid   CHAR(32) := 'MVAKODE000000000000000000000001';
    v_mva_inn_guid  CHAR(32) := 'MVAKODE000000000000000000000002';

    v_tx_guid       CHAR(32);
BEGIN
    -- ==========================================
    -- SCENARIO 1: Innskudd av aksjekapital
    -- ==========================================
    v_tx_guid := 'TX000000000000000000000000000001';

    INSERT INTO "Transaksjoner" (
        guid, bok_guid, valuta_guid, bilagsnummer, bilagsdato,
        posteringsdato, registreringsdato, beskrivelse, kilde, periode_guid
    )
    VALUES (
        v_tx_guid, v_bok_guid, v_nok_guid,
        'BILAG-2026-001', '2026-01-02',
        '2026-01-02 09:00:00', '2026-01-02 09:00:00',
        'Stiftelse av selskapet – innskudd av aksjekapital',
        'manuell', v_jan_guid
    );

    INSERT INTO "Posteringer" (
        guid, transaksjon_guid, konto_guid, tekst, handling,
        avstemmingsstatus, avstemmingsdato,
        belop_teller, belop_nevner, antall_teller, antall_nevner, lot_guid
    )
    VALUES
    (
        'POST000000000000000000000000001',
        v_tx_guid, v_konto_1920, 'Innskudd på bankkonto', 'Stiftelse',
        'n', NULL,
        20000000, 100, 0, 1, NULL
    ),
    (
        'POST000000000000000000000000002',
        v_tx_guid, v_konto_2000, 'Aksjekapital innskutt', 'Stiftelse',
        'n', NULL,
        -20000000, 100, 0, 1, NULL
    );

    -- ==========================================
    -- SCENARIO 2: Kjøp av rekvisita på kreditt
    -- ==========================================
    v_tx_guid := 'TX000000000000000000000000000002';

    INSERT INTO "Transaksjoner" (
        guid, bok_guid, valuta_guid, bilagsnummer, bilagsdato,
        posteringsdato, registreringsdato, beskrivelse, kilde, periode_guid
    )
    VALUES (
        v_tx_guid, v_bok_guid, v_nok_guid,
        'BILAG-2026-002', '2026-01-15',
        '2026-01-15 10:00:00', '2026-01-15 10:00:00',
        'Kjøp av kontorrekvisita på kreditt',
        'manuell', v_jan_guid
    );

    INSERT INTO "Posteringer" (
        guid, transaksjon_guid, konto_guid, tekst, handling,
        avstemmingsstatus, avstemmingsdato,
        belop_teller, belop_nevner, antall_teller, antall_nevner, lot_guid
    )
    VALUES
    (
        'POST000000000000000000000000003',
        v_tx_guid, v_konto_6560, 'Kontorrekvisita ekskl. MVA', 'Kjøp',
        'n', NULL,
        350000, 100, 0, 1, NULL
    ),
    (
        'POST000000000000000000000000004',
        v_tx_guid, v_konto_2710, 'Inngående MVA 25%', 'Kjøp',
        'n', NULL,
        87500, 100, 0, 1, NULL
    ),
    (
        'POST000000000000000000000000005',
        v_tx_guid, v_konto_2400, 'Leverandørgjeld inkl. MVA', 'Kjøp',
        'n', NULL,
        -437500, 100, 0, 1, NULL
    );

    INSERT INTO "MVA-linjer" (
        guid, transaksjon_guid, mva_kode_guid,
        grunnlag_teller, grunnlag_nevner,
        mva_belop_teller, mva_belop_nevner
    )
    VALUES (
        'MVALINJE00000000000000000000001',
        v_tx_guid, v_mva_inn_guid,
        350000, 100,
        87500, 100
    );

    -- ==========================================
    -- SCENARIO 3: Fakturering av kunde
    -- ==========================================
    v_tx_guid := 'TX000000000000000000000000000003';

    INSERT INTO "Transaksjoner" (
        guid, bok_guid, valuta_guid, bilagsnummer, bilagsdato,
        posteringsdato, registreringsdato, beskrivelse, kilde, periode_guid
    )
    VALUES (
        v_tx_guid, v_bok_guid, v_nok_guid,
        'BILAG-2026-003', '2026-02-10',
        '2026-02-10 11:00:00', '2026-02-10 11:00:00',
        'Fakturering av kunde TechNord AS',
        'manuell', v_feb_guid
    );

    INSERT INTO "Posteringer" (
        guid, transaksjon_guid, konto_guid, tekst, handling,
        avstemmingsstatus, avstemmingsdato,
        belop_teller, belop_nevner, antall_teller, antall_nevner, lot_guid
    )
    VALUES
    (
        'POST000000000000000000000000006',
        v_tx_guid, v_konto_1500, 'Kundefordring inkl. MVA', 'Salg',
        'n', NULL,
        6250000, 100, 0, 1, NULL
    ),
    (
        'POST000000000000000000000000007',
        v_tx_guid, v_konto_3100, 'Salgsinntekt tjenester ekskl. MVA', 'Salg',
        'n', NULL,
        -5000000, 100, 0, 1, NULL
    ),
    (
        'POST000000000000000000000000008',
        v_tx_guid, v_konto_2700, 'Utgående MVA 25%', 'Salg',
        'n', NULL,
        -1250000, 100, 0, 1, NULL
    );

    INSERT INTO "MVA-linjer" (
        guid, transaksjon_guid, mva_kode_guid,
        grunnlag_teller, grunnlag_nevner,
        mva_belop_teller, mva_belop_nevner
    )
    VALUES (
        'MVALINJE00000000000000000000002',
        v_tx_guid, v_mva_ut_guid,
        5000000, 100,
        1250000, 100
    );

    -- ==========================================
    -- SCENARIO 4: Innbetaling fra kunde
    -- ==========================================
    v_tx_guid := 'TX000000000000000000000000000004';

    INSERT INTO "Transaksjoner" (
        guid, bok_guid, valuta_guid, bilagsnummer, bilagsdato,
        posteringsdato, registreringsdato, beskrivelse, kilde, periode_guid
    )
    VALUES (
        v_tx_guid, v_bok_guid, v_nok_guid,
        'BILAG-2026-004', '2026-02-20',
        '2026-02-20 12:00:00', '2026-02-20 12:00:00',
        'Innbetaling fra kunde',
        'manuell', v_feb_guid
    );

    INSERT INTO "Posteringer" (
        guid, transaksjon_guid, konto_guid, tekst, handling,
        avstemmingsstatus, avstemmingsdato,
        belop_teller, belop_nevner, antall_teller, antall_nevner, lot_guid
    )
    VALUES
    (
        'POST000000000000000000000000009',
        v_tx_guid, v_konto_1920, 'Betaling inn på bankkonto', 'Innbetaling',
        'n', NULL,
        6250000, 100, 0, 1, NULL
    ),
    (
        'POST000000000000000000000000010',
        v_tx_guid, v_konto_1500, 'Kundefordring oppgjort', 'Innbetaling',
        'n', NULL,
        -6250000, 100, 0, 1, NULL
    );

    -- ==========================================
    -- SCENARIO 5A: Lønn
    -- ==========================================
    v_tx_guid := 'TX000000000000000000000000000005';

    INSERT INTO "Transaksjoner" (
        guid, bok_guid, valuta_guid, bilagsnummer, bilagsdato,
        posteringsdato, registreringsdato, beskrivelse, kilde, periode_guid
    )
    VALUES (
        v_tx_guid, v_bok_guid, v_nok_guid,
        'BILAG-2026-005', '2026-03-31',
        '2026-03-31 12:00:00', '2026-03-31 12:00:00',
        'Lønn mars',
        'manuell', v_mar_guid
    );

    INSERT INTO "Posteringer" (
        guid, transaksjon_guid, konto_guid, tekst, handling,
        avstemmingsstatus, avstemmingsdato,
        belop_teller, belop_nevner, antall_teller, antall_nevner, lot_guid
    )
    VALUES
    (
        'POST000000000000000000000000011',
        v_tx_guid, v_konto_5000, 'Bruttolønn', 'Lønn',
        'n', NULL,
        4500000, 100, 0, 1, NULL
    ),
    (
        'POST000000000000000000000000012',
        v_tx_guid, v_konto_1920, 'Utbetalt nettolønn', 'Lønn',
        'n', NULL,
        -3300000, 100, 0, 1, NULL
    ),
    (
        'POST000000000000000000000000013',
        v_tx_guid, v_konto_2600, 'Skyldig forskuddstrekk', 'Lønn',
        'n', NULL,
        -1200000, 100, 0, 1, NULL
    );

    -- ==========================================
    -- SCENARIO 5B: Arbeidsgiveravgift
    -- ==========================================
    v_tx_guid := 'TX000000000000000000000000000006';

    INSERT INTO "Transaksjoner" (
        guid, bok_guid, valuta_guid, bilagsnummer, bilagsdato,
        posteringsdato, registreringsdato, beskrivelse, kilde, periode_guid
    )
    VALUES (
        v_tx_guid, v_bok_guid, v_nok_guid,
        'BILAG-2026-006', '2026-03-31',
        '2026-03-31 12:30:00', '2026-03-31 12:30:00',
        'Arbeidsgiveravgift',
        'manuell', v_mar_guid
    );

    INSERT INTO "Posteringer" (
        guid, transaksjon_guid, konto_guid, tekst, handling,
        avstemmingsstatus, avstemmingsdato,
        belop_teller, belop_nevner, antall_teller, antall_nevner, lot_guid
    )
    VALUES
    (
        'POST000000000000000000000000014',
        v_tx_guid, v_konto_5400, 'Arbeidsgiveravgift kostnad', 'Lønn',
        'n', NULL,
        634500, 100, 0, 1, NULL
    ),
    (
        'POST000000000000000000000000015',
        v_tx_guid, v_konto_2780, 'Skyldig arbeidsgiveravgift', 'Lønn',
        'n', NULL,
        -634500, 100, 0, 1, NULL
    );

    -- ==========================================
    -- SCENARIO 6: Kjøp av aksjer
    -- ==========================================
    v_tx_guid := 'TX000000000000000000000000000007';

    INSERT INTO "Transaksjoner" (
        guid, bok_guid, valuta_guid, bilagsnummer, bilagsdato,
        posteringsdato, registreringsdato, beskrivelse, kilde, periode_guid
    )
    VALUES (
        v_tx_guid, v_bok_guid, v_nok_guid,
        'BILAG-2026-007', '2026-03-15',
        '2026-03-15 13:00:00', '2026-03-15 13:00:00',
        'Kjøp av aksjer',
        'manuell', v_mar_guid
    );

    INSERT INTO "Posteringer" (
        guid, transaksjon_guid, konto_guid, tekst, handling,
        avstemmingsstatus, avstemmingsdato,
        belop_teller, belop_nevner, antall_teller, antall_nevner, lot_guid
    )
    VALUES
    (
        'POST000000000000000000000000016',
        v_tx_guid, v_konto_1350, 'Kjøp av 10 AAPL-aksjer', 'Kjøp',
        'n', NULL,
        1837500, 100, 10, 1, NULL
    ),
    (
        'POST000000000000000000000000017',
        v_tx_guid, v_konto_1920, 'Betalt fra bankkonto', 'Kjøp',
        'n', NULL,
        -1837500, 100, 0, 1, NULL
    );

    -- ==========================================
    -- SCENARIO 7: MVA-oppgjør
    -- ==========================================
    v_tx_guid := 'TX000000000000000000000000000008';

    INSERT INTO "Transaksjoner" (
        guid, bok_guid, valuta_guid, bilagsnummer, bilagsdato,
        posteringsdato, registreringsdato, beskrivelse, kilde, periode_guid
    )
    VALUES (
        v_tx_guid, v_bok_guid, v_nok_guid,
        'BILAG-2026-008', '2026-04-01',
        '2026-04-01 10:00:00', '2026-04-01 10:00:00',
        'MVA-oppgjør',
        'manuell', v_apr_guid
    );

    INSERT INTO "Posteringer" (
        guid, transaksjon_guid, konto_guid, tekst, handling,
        avstemmingsstatus, avstemmingsdato,
        belop_teller, belop_nevner, antall_teller, antall_nevner, lot_guid
    )
    VALUES
    (
        'POST000000000000000000000000018',
        v_tx_guid, v_konto_2700, 'Utgående MVA nulles ut', 'MVA',
        'n', NULL,
        1250000, 100, 0, 1, NULL
    ),
    (
        'POST000000000000000000000000019',
        v_tx_guid, v_konto_2710, 'Inngående MVA nulles ut', 'MVA',
        'n', NULL,
        -87500, 100, 0, 1, NULL
    ),
    (
        'POST000000000000000000000000020',
        v_tx_guid, v_konto_2740, 'Netto skyldig MVA overføres til oppgjørskonto', 'MVA',
        'n', NULL,
        -1162500, 100, 0, 1, NULL
    );

    -- ==========================================
    -- SCENARIO 8A: Fakturering i SEK
    -- ==========================================
    v_tx_guid := 'TX000000000000000000000000000009';

    INSERT INTO "Transaksjoner" (
        guid, bok_guid, valuta_guid, bilagsnummer, bilagsdato,
        posteringsdato, registreringsdato, beskrivelse, kilde, periode_guid
    )
    VALUES (
        v_tx_guid, v_bok_guid, v_nok_guid,
        'BILAG-2026-009', '2026-04-10',
        '2026-04-10 10:00:00', '2026-04-10 10:00:00',
        'Fakturering svensk kunde i SEK',
        'manuell', v_apr_guid
    );

    INSERT INTO "Posteringer" (
        guid, transaksjon_guid, konto_guid, tekst, handling,
        avstemmingsstatus, avstemmingsdato,
        belop_teller, belop_nevner, antall_teller, antall_nevner, lot_guid
    )
    VALUES
    (
        'POST000000000000000000000000021',
        v_tx_guid, v_konto_1500, 'Kundefordring svensk kunde', 'Salg',
        'n', NULL,
        5100000, 100, 0, 1, NULL
    ),
    (
        'POST000000000000000000000000022',
        v_tx_guid, v_konto_3100, 'Salgsinntekt svensk kunde', 'Salg',
        'n', NULL,
        -5100000, 100, 0, 1, NULL
    );

    -- ==========================================
    -- SCENARIO 8B: Betaling med valutatap
    -- ==========================================
    v_tx_guid := 'TX000000000000000000000000000010';

    INSERT INTO "Transaksjoner" (
        guid, bok_guid, valuta_guid, bilagsnummer, bilagsdato,
        posteringsdato, registreringsdato, beskrivelse, kilde, periode_guid
    )
    VALUES (
        v_tx_guid, v_bok_guid, v_nok_guid,
        'BILAG-2026-010', '2026-05-10',
        '2026-05-10 10:00:00', '2026-05-10 10:00:00',
        'Valutatap SEK',
        'manuell', v_mai_guid
    );

    INSERT INTO "Posteringer" (
        guid, transaksjon_guid, konto_guid, tekst, handling,
        avstemmingsstatus, avstemmingsdato,
        belop_teller, belop_nevner, antall_teller, antall_nevner, lot_guid
    )
    VALUES
    (
        'POST000000000000000000000000023',
        v_tx_guid, v_konto_1920, 'Innbetaling i NOK', 'Innbetaling',
        'n', NULL,
        4900000, 100, 0, 1, NULL
    ),
    (
        'POST000000000000000000000000024',
        v_tx_guid, v_konto_8160, 'Valutatap ved betaling', 'Valuta',
        'n', NULL,
        200000, 100, 0, 1, NULL
    ),
    (
        'POST000000000000000000000000025',
        v_tx_guid, v_konto_1500, 'Kundefordring oppgjort', 'Innbetaling',
        'n', NULL,
        -5100000, 100, 0, 1, NULL
    );

END $$;

-- =========================
-- VERIFIKASJON
-- Skal returnere 0 rader
-- =========================
SELECT
    t.guid,
    t.beskrivelse,
    SUM(p.belop_teller::numeric / p.belop_nevner) AS saldo
FROM "Transaksjoner" t
JOIN "Posteringer" p
    ON p.transaksjon_guid = t.guid
GROUP BY t.guid, t.beskrivelse
HAVING ABS(SUM(p.belop_teller::numeric / p.belop_nevner)) > 0.001;