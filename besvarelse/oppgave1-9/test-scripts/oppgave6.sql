-- Oppgave 6
-- Databaseadministrasjon og tilgangskontroll
-- Safe versjon: oppretter roller, brukere, grants og RLS uten å stoppe på forventede feil

-- =========================================================
-- DEL A: Rydd opp hvis skriptet kjøres flere ganger
-- =========================================================

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'dba_ola') THEN
        REVOKE regnskap_admin FROM dba_ola;
        DROP ROLE dba_ola;
    END IF;

    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'revisor_kari') THEN
        REVOKE revisor FROM revisor_kari;
        DROP ROLE revisor_kari;
    END IF;

    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'bokforer_per') THEN
        REVOKE regnskapsforer FROM bokforer_per;
        DROP ROLE bokforer_per;
    END IF;

    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ekstern_revisor') THEN
        REVOKE les_tilgang FROM ekstern_revisor;
        DROP ROLE ekstern_revisor;
    END IF;

    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'regnskap_admin') THEN
        DROP ROLE regnskap_admin;
    END IF;

    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'revisor') THEN
        DROP ROLE revisor;
    END IF;

    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'regnskapsforer') THEN
        DROP ROLE regnskapsforer;
    END IF;

    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'les_tilgang') THEN
        DROP ROLE les_tilgang;
    END IF;
END $$;

-- =========================================================
-- DEL A: Opprett roller
-- =========================================================

CREATE ROLE regnskap_admin NOLOGIN;
CREATE ROLE revisor NOLOGIN;
CREATE ROLE regnskapsforer NOLOGIN;
CREATE ROLE les_tilgang NOLOGIN;

-- =========================================================
-- DEL A: Opprett brukere
-- =========================================================

CREATE USER dba_ola WITH PASSWORD 'dba_ola_2026';
CREATE USER revisor_kari WITH PASSWORD 'revisor_kari_2026';
CREATE USER bokforer_per WITH PASSWORD 'bokforer_per_2026';
CREATE USER ekstern_revisor WITH PASSWORD 'ekstern_revisor_2026';

-- =========================================================
-- DEL B: Tildel roller til brukere
-- =========================================================

GRANT regnskap_admin TO dba_ola;
GRANT revisor TO revisor_kari;
GRANT regnskapsforer TO bokforer_per;
GRANT les_tilgang TO ekstern_revisor;

-- =========================================================
-- DEL B: Schema-tilgang
-- =========================================================

GRANT USAGE ON SCHEMA public TO regnskap_admin;
GRANT USAGE ON SCHEMA public TO revisor;
GRANT USAGE ON SCHEMA public TO regnskapsforer;
GRANT USAGE ON SCHEMA public TO les_tilgang;

-- =========================================================
-- DEL B: Rettigheter per rolle
-- =========================================================

-- regnskap_admin: full tilgang
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO regnskap_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO regnskap_admin;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO regnskap_admin;

-- revisor: kun lesetilgang til alle tabeller
GRANT SELECT ON ALL TABLES IN SCHEMA public TO revisor;

-- regnskapsforer:
-- lesetilgang til alle tabeller
GRANT SELECT ON ALL TABLES IN SCHEMA public TO regnskapsforer;

-- kan sette inn og oppdatere transaksjonsdata
GRANT INSERT, UPDATE ON "Transaksjoner" TO regnskapsforer;
GRANT INSERT, UPDATE ON "Posteringer" TO regnskapsforer;
GRANT INSERT, UPDATE ON "MVA-linjer" TO regnskapsforer;

-- les_tilgang: kun oppslagstabeller
GRANT SELECT ON "Kontoer" TO les_tilgang;
GRANT SELECT ON "Kontoklasser" TO les_tilgang;
GRANT SELECT ON "Valutaer" TO les_tilgang;

-- =========================================================
-- DEL C.1: Verifisering av grants
-- =========================================================

SELECT
    grantee,
    table_name,
    privilege_type
FROM information_schema.role_table_grants
WHERE grantee IN ('regnskap_admin', 'revisor', 'regnskapsforer', 'les_tilgang')
ORDER BY grantee, table_name, privilege_type;

-- =========================================================
-- DEL D: Row Level Security (RLS)
-- =========================================================

ALTER TABLE "Transaksjoner" ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS policy_aar_filter ON "Transaksjoner";
DROP POLICY IF EXISTS policy_revisor_alt ON "Transaksjoner";

-- regnskapsforer kan kun se transaksjoner i inneværende år
CREATE POLICY policy_aar_filter
ON "Transaksjoner"
FOR SELECT
TO regnskapsforer
USING (
    EXTRACT(YEAR FROM bilagsdato) = EXTRACT(YEAR FROM CURRENT_DATE)
);

-- revisor kan se alle transaksjoner
CREATE POLICY policy_revisor_alt
ON "Transaksjoner"
FOR SELECT
TO revisor
USING (TRUE);

-- =========================================================
-- DEL D: Vis aktive policies
-- =========================================================

SELECT
    schemaname,
    tablename,
    policyname,
    roles,
    cmd
FROM pg_policies
WHERE tablename = 'Transaksjoner';