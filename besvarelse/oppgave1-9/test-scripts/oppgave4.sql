-- Oppgave 4
-- Hierarkisk kontoplan med WITH RECURSIVE

-- ========================================
-- DEL A: Rekursiv traversering av kontoplanen
-- ========================================
WITH RECURSIVE kontoplan AS (
    -- Start med rotkonto
    SELECT
        k.guid,
        k.overordnet_guid,
        k.kontonummer,
        k.navn,
        0 AS nivaa,
        k.navn::TEXT AS sti
    FROM "Kontoer" k
    WHERE k.overordnet_guid IS NULL

    UNION ALL

    -- Finn underkontoer rekursivt
    SELECT
        k.guid,
        k.overordnet_guid,
        k.kontonummer,
        k.navn,
        kp.nivaa + 1 AS nivaa,
        (kp.sti || ' > ' || k.navn)::TEXT AS sti
    FROM "Kontoer" k
    JOIN kontoplan kp
        ON k.overordnet_guid = kp.guid
)
SELECT
    nivaa,
    COALESCE(kontonummer::TEXT, '—') AS kontonr,
    LPAD('', nivaa * 2, ' ') || navn AS navn,
    sti
FROM kontoplan
ORDER BY sti;

-- ========================================
-- DEL B: Aggregert saldo oppover i hierarkiet
-- ========================================

WITH RECURSIVE
saldo_per_konto AS (
    SELECT
        k.guid,
        k.overordnet_guid,
        k.kontonummer,
        k.navn,
        k.kontoklasse,
        COALESCE(SUM(p.belop_teller::numeric / p.belop_nevner), 0) AS egen_saldo
    FROM "Kontoer" k
    LEFT JOIN "Posteringer" p
        ON p.konto_guid = k.guid
    GROUP BY
        k.guid,
        k.overordnet_guid,
        k.kontonummer,
        k.navn,
        k.kontoklasse
),

konto_tre AS (
    -- Hver konto er sin egen descendant
    SELECT
        k.guid AS ancestor_guid,
        k.guid AS descendant_guid
    FROM "Kontoer" k

    UNION ALL

    -- Knyt alle barn videre opp til samme ancestor
    SELECT
        kt.ancestor_guid,
        k.guid AS descendant_guid
    FROM konto_tre kt
    JOIN "Kontoer" k
        ON k.overordnet_guid = kt.descendant_guid
)

SELECT
    parent.kontonummer,
    parent.navn,
    parent.kontoklasse,
    SUM(spk.egen_saldo) AS total_saldo
FROM konto_tre kt
JOIN saldo_per_konto spk
    ON spk.guid = kt.descendant_guid
JOIN "Kontoer" parent
    ON parent.guid = kt.ancestor_guid
WHERE parent.kontoklasse IN (1, 2)
GROUP BY
    parent.kontonummer,
    parent.navn,
    parent.kontoklasse
ORDER BY
    parent.kontonummer NULLS FIRST;