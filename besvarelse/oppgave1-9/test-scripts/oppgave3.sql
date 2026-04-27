-- Oppgave 3
-- Grunnleggende SQL spørringer mot dobbelt bokholderi

-- ========================================
-- DEL A.1: Vis hele kontoplanen
-- ========================================
SELECT
    kontonummer,
    navn,
    kontoklasse
FROM "Kontoer"
WHERE kontonummer IS NOT NULL
ORDER BY kontonummer;

-- ========================================
-- DEL A.2: Vis alle kontoklasser
-- ========================================
SELECT
    klasse_nr,
    navn,
    type
FROM "Kontoklasser"
ORDER BY klasse_nr;

-- ========================================
-- DEL A.3: Koble kontoer med klasser
-- ========================================
SELECT
    k.kontonummer,
    k.navn AS kontonavn,
    kk.navn AS kontoklasse_navn
FROM "Kontoer" k
JOIN "Kontoklasser" kk
    ON k.kontoklasse = kk.klasse_nr
WHERE k.kontonummer IS NOT NULL
ORDER BY k.kontonummer;

-- ========================================
-- DEL B.1: Antall posteringer per transaksjon
-- ========================================
SELECT
    t.bilagsnummer,
    t.beskrivelse,
    t.bilagsdato,
    COUNT(p.guid) AS antall_posteringer
FROM "Transaksjoner" t
JOIN "Posteringer" p
    ON p.transaksjon_guid = t.guid
GROUP BY t.guid, t.bilagsnummer, t.beskrivelse, t.bilagsdato
ORDER BY t.bilagsdato;

-- ========================================
-- DEL B.2: Saldo per konto
-- ========================================
SELECT
    k.kontonummer,
    k.navn,
    SUM(p.belop_teller::numeric / p.belop_nevner) AS saldo
FROM "Kontoer" k
JOIN "Posteringer" p
    ON p.konto_guid = k.guid
GROUP BY k.guid, k.kontonummer, k.navn
ORDER BY k.kontonummer;

-- ========================================
-- DEL C.1: Finn MVA-pliktige eller placeholder-kontoer
-- ========================================
SELECT
    guid,
    kontonummer,
    navn,
    mva_pliktig,
    er_placeholder
FROM "Kontoer"
WHERE mva_pliktig = TRUE
   OR er_placeholder = TRUE
ORDER BY kontonummer NULLS FIRST, navn;

-- ========================================
-- DEL C.2: Vis lønnstransaksjonen med debet/kredit
-- ========================================
SELECT
    t.beskrivelse AS transaksjonsbeskrivelse,
    t.bilagsdato,
    k.kontonummer,
    k.navn AS kontonavn,
    (p.belop_teller::numeric / p.belop_nevner) AS belop,
    CASE
        WHEN p.belop_teller > 0 THEN 'Debet'
        WHEN p.belop_teller < 0 THEN 'Kredit'
        ELSE '0'
    END AS debet_kredit
FROM "Transaksjoner" t
JOIN "Posteringer" p
    ON p.transaksjon_guid = t.guid
JOIN "Kontoer" k
    ON p.konto_guid = k.guid
WHERE t.beskrivelse ILIKE '%lønn%'
ORDER BY t.bilagsdato, k.kontonummer;

-- ========================================
-- DEL C.3: Antall kontoer per klasse
-- ========================================
SELECT
    kk.klasse_nr,
    kk.navn AS kontoklasse,
    COUNT(k.guid) FILTER (
        WHERE k.er_placeholder = FALSE
          AND k.kontonummer IS NOT NULL
    ) AS antall_driftskontoer,
    COUNT(k.guid) FILTER (
        WHERE k.er_placeholder = FALSE
          AND k.kontonummer IS NOT NULL
          AND k.mva_pliktig = TRUE
    ) AS antall_mva_pliktige
FROM "Kontoklasser" kk
LEFT JOIN "Kontoer" k
    ON k.kontoklasse = kk.klasse_nr
GROUP BY kk.klasse_nr, kk.navn
ORDER BY kk.klasse_nr;

-- ========================================
-- DEL C.4: Saldo for alle eiendelskontoer
-- ========================================
SELECT
    k.kontonummer,
    k.navn,
    COALESCE(SUM(p.belop_teller::numeric / p.belop_nevner), 0) AS saldo
FROM "Kontoer" k
LEFT JOIN "Posteringer" p
    ON p.konto_guid = k.guid
WHERE k.kontoklasse = 1
  AND k.er_placeholder = FALSE
  AND k.kontonummer IS NOT NULL
GROUP BY k.guid, k.kontonummer, k.navn
ORDER BY k.kontonummer;

-- ========================================
-- DEL C.5: Finn ubalanserte transaksjoner
-- ========================================
SELECT
    t.guid,
    t.bilagsnummer,
    t.beskrivelse,
    SUM(p.belop_teller) AS sum_belop_teller
FROM "Transaksjoner" t
JOIN "Posteringer" p
    ON p.transaksjon_guid = t.guid
GROUP BY t.guid, t.bilagsnummer, t.beskrivelse
HAVING SUM(p.belop_teller) <> 0
ORDER BY t.bilagsnummer;

-- ========================================
-- DEL D.1: Vis alle MVA-beregninger
-- ========================================
SELECT
    mk.kode AS mva_kode,
    (ml.grunnlag_teller::numeric / ml.grunnlag_nevner) AS grunnlag,
    (ml.mva_belop_teller::numeric / ml.mva_belop_nevner) AS mva_belop,
    t.beskrivelse AS transaksjonsbeskrivelse
FROM "MVA-linjer" ml
JOIN "MVA-koder" mk
    ON ml.mva_kode_guid = mk.guid
JOIN "Transaksjoner" t
    ON ml.transaksjon_guid = t.guid
ORDER BY t.bilagsdato, mk.kode;

-- ========================================
-- DEL D.2: Vis alle valutakurser
-- ========================================
SELECT
    vf.kode AS fra_valuta,
    vt.kode AS til_valuta,
    (vk.kurs_teller::numeric / vk.kurs_nevner) AS kurs,
    vk.dato
FROM "Valutakurser" vk
JOIN "Valutaer" vf
    ON vk.fra_valuta_guid = vf.guid
JOIN "Valutaer" vt
    ON vk.til_valuta_guid = vt.guid
ORDER BY vk.dato DESC;

-- ========================================
-- DEL D.3: Antall transaksjoner per periode
-- ========================================
SELECT
    rp.navn AS periodenavn,
    rp.fra_dato,
    rp.til_dato,
    rp.status,
    COUNT(t.guid) AS antall_transaksjoner
FROM "Regnskapsperioder" rp
JOIN "Transaksjoner" t
    ON t.periode_guid = rp.guid
GROUP BY rp.guid, rp.navn, rp.fra_dato, rp.til_dato, rp.status
ORDER BY rp.fra_dato;

-- ========================================
-- DEL D.4: Total saldo per kontoklasse
-- ========================================
SELECT
    kk.klasse_nr,
    kk.navn AS klassenavn,
    kk.type,
    COALESCE(SUM(p.belop_teller::numeric / p.belop_nevner), 0) AS totalsaldo
FROM "Kontoklasser" kk
LEFT JOIN "Kontoer" k
    ON k.kontoklasse = kk.klasse_nr
LEFT JOIN "Posteringer" p
    ON p.konto_guid = k.guid
GROUP BY kk.klasse_nr, kk.navn, kk.type
ORDER BY kk.klasse_nr;

-- ========================================
-- DEL D.5: Detaljert analyse av resultatkontoer
-- ========================================
SELECT
    k.kontonummer,
    k.navn,
    COUNT(p.guid) AS antall_posteringer,
    COALESCE(SUM(p.belop_teller::numeric / p.belop_nevner), 0) AS netto_saldo,
    COALESCE(SUM(
        CASE WHEN p.belop_teller > 0
             THEN p.belop_teller::numeric / p.belop_nevner
             ELSE 0
        END
    ), 0) AS total_debet,
    COALESCE(SUM(
        CASE WHEN p.belop_teller < 0
             THEN ABS(p.belop_teller::numeric / p.belop_nevner)
             ELSE 0
        END
    ), 0) AS total_kredit,
    COALESCE(AVG(ABS(p.belop_teller::numeric / p.belop_nevner)), 0) AS gjennomsnittlig_transaksjonsbelop
FROM "Kontoer" k
LEFT JOIN "Posteringer" p
    ON p.konto_guid = k.guid
WHERE k.kontoklasse BETWEEN 3 AND 8
  AND k.er_placeholder = FALSE
  AND k.kontonummer IS NOT NULL
GROUP BY k.guid, k.kontonummer, k.navn
ORDER BY k.kontonummer;