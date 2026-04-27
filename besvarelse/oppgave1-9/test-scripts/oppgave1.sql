-- =========================
-- BØKER
-- =========================
CREATE TABLE "Bøker" (
    guid CHAR(32) PRIMARY KEY,
    navn TEXT NOT NULL,
    organisasjonsnr TEXT,
    adresse TEXT,
    rot_konto_guid CHAR(32),
    regnskapsaar DATE
);

-- =========================
-- VALUTAER
-- =========================
CREATE TABLE "Valutaer" (
    guid CHAR(32) PRIMARY KEY,
    kode TEXT UNIQUE NOT NULL,
    navn TEXT NOT NULL,
    desimaler INTEGER NOT NULL CHECK (desimaler > 0),
    hent_kurs_flag INTEGER NOT NULL DEFAULT 0 CHECK (hent_kurs_flag IN (0,1)),
    kurs_kilde TEXT
);

-- =========================
-- VALUTAKURSER
-- =========================
CREATE TABLE "Valutakurser" (
    guid CHAR(32) PRIMARY KEY,
    fra_valuta_guid CHAR(32) NOT NULL REFERENCES "Valutaer"(guid),
    til_valuta_guid CHAR(32) NOT NULL REFERENCES "Valutaer"(guid),
    dato TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    kilde TEXT,
    type TEXT CHECK (type IN ('last','bid','ask','nav')),
    kurs_teller BIGINT NOT NULL,
    kurs_nevner BIGINT NOT NULL DEFAULT 100 CHECK (kurs_nevner > 0),
    CHECK (fra_valuta_guid <> til_valuta_guid)
);
-- =========================
-- KONTOKLASSER
-- =========================
CREATE TABLE "Kontoklasser" (
    klasse_nr INTEGER PRIMARY KEY,
    navn TEXT UNIQUE NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('BALANSE', 'RESULTAT')),
    normal_saldo TEXT NOT NULL CHECK (normal_saldo IN ('DEBET', 'KREDIT')),
    beskrivelse TEXT
);

-- =========================
-- KONTOER
-- =========================
CREATE TABLE "Kontoer" (
    guid CHAR(32) PRIMARY KEY,
    bok_guid CHAR(32) NOT NULL
        REFERENCES "Bøker"(guid) ON DELETE RESTRICT,
    overordnet_guid CHAR(32)
        REFERENCES "Kontoer"(guid) ON DELETE RESTRICT,
    valuta_guid CHAR(32) NOT NULL
        REFERENCES "Valutaer"(guid) ON DELETE RESTRICT,
    kontonummer INTEGER UNIQUE
        CHECK (kontonummer BETWEEN 1000 AND 8999),
    kontoklasse INTEGER NOT NULL
        REFERENCES "Kontoklasser"(klasse_nr) ON DELETE RESTRICT,
    gnucash_type TEXT,
    navn TEXT NOT NULL,
    beskrivelse TEXT,
    er_placeholder BOOLEAN NOT NULL DEFAULT FALSE,
    er_skjult BOOLEAN NOT NULL DEFAULT FALSE,
    mva_pliktig BOOLEAN NOT NULL DEFAULT FALSE,
    mva_kode_guid CHAR(32)
);
COMMENT ON TABLE "Kontoer" IS 'Hijerarhisk kontoplan. Kombinasjon av kontonummer og kontoklasse sikrer NS 4102-samsvar.';
COMMENT ON COLUMN "Kontoer".overordnet_guid IS 'Selvhenvisende FK. NULL = rotkonto. Bygger trestrukturen.';
COMMENT ON COLUMN "Kontoer".kontonummer IS '4-sifret NS 4102-kontonummer (1000-8999). NULL for placeholder-kontoer.';
COMMENT ON COLUMN "Kontoer".er_placeholder IS 'TRUE: kontoen er kun en beholder for underkontoer, kan ikke posteres på.';
COMMENT ON COLUMN "Kontoer".mva_pliktig IS 'TRUE: transaksjoner på denne kontoen er normalt MVA-pliktige.';

-- =========================
-- REGNSKAPSPERIODER
-- =========================
CREATE TABLE "Regnskapsperioder" (
    guid CHAR(32) PRIMARY KEY,
    bok_guid CHAR(32) NOT NULL
        REFERENCES "Bøker"(guid) ON DELETE RESTRICT,
    navn TEXT NOT NULL,
    fra_dato DATE NOT NULL,
    til_dato DATE NOT NULL,
    status TEXT NOT NULL DEFAULT 'AAPEN'
        CHECK (status IN ('AAPEN', 'LUKKET', 'LAAST'))
);

-- =========================
-- TRANSAKSJONER
-- =========================
CREATE TABLE "Transaksjoner" (
    guid CHAR(32) PRIMARY KEY,
    bok_guid CHAR(32) NOT NULL
        REFERENCES "Bøker"(guid) ON DELETE RESTRICT,
    valuta_guid CHAR(32) NOT NULL
        REFERENCES "Valutaer"(guid) ON DELETE RESTRICT,
    bilagsnummer TEXT NOT NULL,
    bilagsdato DATE,
    posteringsdato TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    registreringsdato TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    beskrivelse TEXT NOT NULL,
    kilde TEXT DEFAULT 'manuell'
        CHECK (kilde IN ('manuell', 'import', 'planlagt')),
    periode_guid CHAR(32) NOT NULL
        REFERENCES "Regnskapsperioder"(guid) ON DELETE RESTRICT
);

-- =========================
-- POSTERINGER
-- =========================
CREATE TABLE "Posteringer" (
    guid CHAR(32) PRIMARY KEY,
    transaksjon_guid CHAR(32) NOT NULL
        REFERENCES "Transaksjoner"(guid) ON DELETE CASCADE,
    konto_guid CHAR(32) NOT NULL
        REFERENCES "Kontoer"(guid) ON DELETE RESTRICT,
    tekst TEXT,
    handling TEXT,
    avstemmingsstatus TEXT NOT NULL DEFAULT 'n'
        CHECK (avstemmingsstatus IN ('n', 'c', 'y')),
    avstemmingsdato DATE,
    belop_teller BIGINT NOT NULL,
    belop_nevner BIGINT NOT NULL DEFAULT 100
        CHECK (belop_nevner > 0),
    antall_teller BIGINT NOT NULL DEFAULT 0,
    antall_nevner BIGINT NOT NULL DEFAULT 1
        CHECK (antall_nevner > 0),
    lot_guid CHAR(32)
);

-- =========================
-- MVA-KODER
-- =========================
CREATE TABLE "MVA-koder" (
    guid CHAR(32) PRIMARY KEY,
    kode TEXT UNIQUE NOT NULL,
    navn TEXT NOT NULL,
    type TEXT NOT NULL
        CHECK (type IN ('UTGAAENDE', 'INNGAAENDE', 'INGEN')),
    sats_teller BIGINT NOT NULL,
    sats_nevner BIGINT NOT NULL DEFAULT 100
        CHECK (sats_nevner > 0),
    mva_konto_guid CHAR(32) NOT NULL
        REFERENCES "Kontoer"(guid) ON DELETE RESTRICT,
    aktiv BOOLEAN NOT NULL DEFAULT TRUE
);

-- =========================
-- MVA-LINJER
-- =========================
CREATE TABLE "MVA-linjer" (
    guid CHAR(32) PRIMARY KEY,
    transaksjon_guid CHAR(32) NOT NULL
        REFERENCES "Transaksjoner"(guid) ON DELETE RESTRICT,
    mva_kode_guid CHAR(32) NOT NULL
        REFERENCES "MVA-koder"(guid) ON DELETE RESTRICT,
    grunnlag_teller BIGINT NOT NULL,
    grunnlag_nevner BIGINT NOT NULL DEFAULT 100
        CHECK (grunnlag_nevner > 0),
    mva_belop_teller BIGINT NOT NULL,
    mva_belop_nevner BIGINT NOT NULL DEFAULT 100
        CHECK (mva_belop_nevner > 0)
);

-- =========================
-- ALTER TABLE FOR CIRCULAR REFERENCES
-- =========================

ALTER TABLE "Bøker"
ADD CONSTRAINT fk_rot_konto
FOREIGN KEY (rot_konto_guid)
REFERENCES "Kontoer"(guid)
ON DELETE RESTRICT;

ALTER TABLE "Kontoer"
ADD CONSTRAINT fk_mva_kode
FOREIGN KEY (mva_kode_guid)
REFERENCES "MVA-koder"(guid)
ON DELETE RESTRICT;

-- =========================
-- INDEXES (YTELSE)
-- =========================

CREATE INDEX idx_kontoer_bok_guid
ON "Kontoer"(bok_guid);

CREATE INDEX idx_kontoer_kontonummer
ON "Kontoer"(kontonummer);

CREATE INDEX idx_kontoer_overordnet_guid
ON "Kontoer"(overordnet_guid);

CREATE INDEX idx_mva_linjer_transaksjon_guid
ON "MVA-linjer"(transaksjon_guid);

CREATE INDEX idx_posteringer_konto_guid
ON "Posteringer"(konto_guid);

CREATE INDEX idx_posteringer_transaksjon_guid
ON "Posteringer"(transaksjon_guid);

CREATE INDEX idx_transaksjoner_bok_guid
ON "Transaksjoner"(bok_guid);

CREATE INDEX idx_transaksjoner_periode_guid
ON "Transaksjoner"(periode_guid);

CREATE INDEX idx_transaksjoner_posteringsdato
ON "Transaksjoner"(posteringsdato);

-- =========================
-- COMMENTS
-- =========================

COMMENT ON TABLE "Bøker" IS 'Øverste beholder for hele regnskapet til én virksomhet.';
COMMENT ON TABLE "Valutaer" IS 'Valutaer brukt i regnskapet, basert på ISO 4217.';
COMMENT ON TABLE "Valutakurser" IS 'Historiske vekslingskurser mellom to valutaer.';
COMMENT ON TABLE "Kontoklasser" IS 'Oppslagstabell for de åtte NS 4102-kontoklassene.';
COMMENT ON TABLE "Kontoer" IS 'Hierarkisk kontoplan. Kombinasjon av kontonummer og kontoklasse sikrer NS 4102-samsvar.';
COMMENT ON TABLE "Regnskapsperioder" IS 'Regnskapsperioder med status som AAPEN, LUKKET eller LAAST.';
COMMENT ON TABLE "Transaksjoner" IS 'Bilagshode for finansielle hendelser.';
COMMENT ON TABLE "Posteringer" IS 'Debet- og kreditlinjer knyttet til transaksjoner.';
COMMENT ON TABLE "MVA-koder" IS 'Norske MVA-koder og tilhørende satser.';
COMMENT ON TABLE "MVA-linjer" IS 'Beregnet grunnlag og MVA-beløp per transaksjon.';

COMMENT ON COLUMN "Kontoer".overordnet_guid IS 'Selvhenvisende FK. NULL betyr rotkonto og bygger trestrukturen.';
COMMENT ON COLUMN "Kontoer".kontonummer IS '4-sifret NS 4102-kontonummer (1000-8999). NULL for placeholder-kontoer.';
COMMENT ON COLUMN "Kontoer".er_placeholder IS 'TRUE betyr at kontoen kun er en beholder for underkontoer.';
COMMENT ON COLUMN "Kontoer".mva_pliktig IS 'TRUE betyr at transaksjoner på denne kontoen normalt er MVA-pliktige.';
COMMENT ON COLUMN "Regnskapsperioder".status IS 'Tillatte verdier: AAPEN, LUKKET, LAAST.';
COMMENT ON COLUMN "Posteringer".avstemmingsstatus IS 'n = ikke avstemt, c = klarert, y = avstemt mot bank.';
COMMENT ON COLUMN "Posteringer".belop_teller IS 'Positivt beløp = debet, negativt beløp = kredit.';
COMMENT ON COLUMN "Valutakurser".kurs_nevner IS 'Nevner i brøkrepresentasjonen av valutakursen.';

