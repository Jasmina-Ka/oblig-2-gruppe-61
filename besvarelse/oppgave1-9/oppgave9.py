"""
Demonstrasjon av tapt oppdatering (Lost Update) — Oppgave 9
============================================================

Denne versjonen er tilpasset prosjektet vårt og bruker:
- psycopg2
- threading
- PostgreSQL i Docker
- Python-genererte GUID-er (uuid) i stedet for generate_guid() i databasen
"""

import os
import uuid
import time
import threading
import psycopg2

# ─────────────────────────────────────────────────────────────────────────────
# Konfigurasjon
# ─────────────────────────────────────────────────────────────────────────────


DB_NAME = "regnskap"
DB_USER = "admin"
DB_HOST = "127.0.0.1"
DB_PORT = "55432"

DSN = (
    f"dbname={DB_NAME} "
    f"user={DB_USER} "
    f"host={DB_HOST} "
    f"port={DB_PORT}"
)

KONTONUMMER = 1920
FORSINKELSE = 0.3   # sekunder mellom LES og SKRIV
BELOP_ANE = 300000  # 3 000 kr i øre
BELOP_BJORN = 150000  # 1 500 kr i øre

# ─────────────────────────────────────────────────────────────────────────────
# Hjelpefunksjoner
# ─────────────────────────────────────────────────────────────────────────────

def ny_tilkobling():
    return psycopg2.connect(DSN)


def gen_guid():
    return uuid.uuid4().hex.upper()


def hent_konto_guid(kontonummer: int):
    conn = ny_tilkobling()
    conn.autocommit = True
    try:
        with conn.cursor() as c:
            c.execute('SELECT guid FROM "Kontoer" WHERE kontonummer = %s', (kontonummer,))
            rad = c.fetchone()
            return rad[0] if rad else None
    finally:
        conn.close()


def hent_saldo_insert(konto_guid: str) -> int:
    """Saldo beregnet som SUM av posteringer — INSERT-basert modell."""
    conn = ny_tilkobling()
    conn.autocommit = True
    try:
        with conn.cursor() as c:
            c.execute(
                'SELECT COALESCE(SUM(belop_teller), 0) FROM "Posteringer" WHERE konto_guid = %s',
                (konto_guid,),
            )
            return c.fetchone()[0]
    finally:
        conn.close()


def hent_kontekst():
    """
    Henter nødvendige GUID-er for å kunne opprette demo-transaksjoner.
    """
    conn = ny_tilkobling()
    conn.autocommit = True
    try:
        with conn.cursor() as c:
            c.execute('SELECT guid FROM "Bøker" LIMIT 1')
            bok_rad = c.fetchone()
            if not bok_rad:
                raise RuntimeError('Fant ingen rad i "Bøker". Kjør oppgave1/oppgave2 først.')
            bok_guid = bok_rad[0]

            c.execute('SELECT guid FROM "Valutaer" WHERE kode = %s', ("NOK",))
            nok_rad = c.fetchone()
            if not nok_rad:
                raise RuntimeError('Fant ikke NOK i "Valutaer".')
            nok_guid = nok_rad[0]

            c.execute("""
                SELECT guid
                FROM "Regnskapsperioder"
                WHERE EXTRACT(MONTH FROM fra_dato) = 3
                  AND EXTRACT(YEAR  FROM fra_dato) = 2026
                LIMIT 1
            """)
            periode_rad = c.fetchone()

            if not periode_rad:
                c.execute('SELECT guid FROM "Regnskapsperioder" LIMIT 1')
                periode_rad = c.fetchone()

            if not periode_rad:
                raise RuntimeError('Fant ingen rad i "Regnskapsperioder".')

            periode_guid = periode_rad[0]

        return {
            "bok": bok_guid,
            "nok": nok_guid,
            "periode": periode_guid,
        }
    finally:
        conn.close()


def rydd_test():
    """
    Sletter demo-data fra tidligere kjøringer.
    """
    conn = ny_tilkobling()
    conn.autocommit = True
    try:
        with conn.cursor() as c:
            c.execute("""
                DELETE FROM "Posteringer"
                WHERE transaksjon_guid IN (
                    SELECT guid
                    FROM "Transaksjoner"
                    WHERE bilagsnummer LIKE 'DEMO-%'
                )
            """)
            c.execute("""
                DELETE FROM "Transaksjoner"
                WHERE bilagsnummer LIKE 'DEMO-%'
            """)
            c.execute("DROP TABLE IF EXISTS demo_konto_saldo")
    finally:
        conn.close()


# ─────────────────────────────────────────────────────────────────────────────
# SCENARIO A — INSERT-basert modell
# ─────────────────────────────────────────────────────────────────────────────

def insert_innbetaling(navn, belop, konto_guid, kontekst, barriere, resultater):
    """
    Begge tråder leser samme saldo og skriver deretter hver sin INSERT-rad.
    Dette gir ingen tapt oppdatering.
    """
    conn = ny_tilkobling()
    try:
        conn.autocommit = False

        # LES
        with conn.cursor() as c:
            c.execute(
                'SELECT COALESCE(SUM(belop_teller), 0) FROM "Posteringer" WHERE konto_guid = %s',
                (konto_guid,),
            )
            lest = c.fetchone()[0]

        print(f"  [{navn:6}] LES: saldo = {lest/100:,.0f} kr")

        # Begge må ha lest før noen får skrive
        barriere.wait()
        time.sleep(FORSINKELSE)

        tx_guid = gen_guid()
        pos_guid = gen_guid()

        with conn.cursor() as c:
            c.execute("""
                INSERT INTO "Transaksjoner"
                    (guid, bok_guid, valuta_guid, bilagsnummer, bilagsdato,
                     posteringsdato, registreringsdato, beskrivelse, kilde, periode_guid)
                VALUES
                    (%s, %s, %s, %s, CURRENT_DATE, NOW(), NOW(), %s, 'manuell', %s)
            """, (
                tx_guid,
                kontekst["bok"],
                kontekst["nok"],
                f"DEMO-INS-{navn[:3].upper()}",
                f"Innbetaling {navn}",
                kontekst["periode"],
            ))

            c.execute("""
                INSERT INTO "Posteringer"
                    (guid, transaksjon_guid, konto_guid, tekst, handling,
                     avstemmingsstatus, avstemmingsdato,
                     belop_teller, belop_nevner, antall_teller, antall_nevner, lot_guid)
                VALUES
                    (%s, %s, %s, %s, 'Demo',
                     'n', NULL,
                     %s, 100, 0, 1, NULL)
            """, (
                pos_guid,
                tx_guid,
                konto_guid,
                f"Innbetaling {navn}",
                belop,
            ))

        conn.commit()

        ny_saldo = hent_saldo_insert(konto_guid)
        print(f"  [{navn:6}] COMMIT: ny saldo = {ny_saldo/100:,.0f} kr  (+{belop/100:,.0f} kr)")
        resultater[navn] = {"lest": lest, "belop": belop, "ny": ny_saldo}

    except Exception as e:
        conn.rollback()
        print(f"  [{navn:6}] FEIL: {e}")
        resultater[navn] = {"feil": str(e)}
    finally:
        conn.close()


# ─────────────────────────────────────────────────────────────────────────────
# SCENARIO B — UPDATE-basert modell
# ─────────────────────────────────────────────────────────────────────────────

def setup_update_tabell(startsaldo: int):
    conn = ny_tilkobling()
    conn.autocommit = True
    try:
        with conn.cursor() as c:
            c.execute("DROP TABLE IF EXISTS demo_konto_saldo")
            c.execute("""
                CREATE TABLE demo_konto_saldo (
                    id    SERIAL PRIMARY KEY,
                    navn  TEXT NOT NULL,
                    saldo BIGINT NOT NULL
                )
            """)
            c.execute(
                "INSERT INTO demo_konto_saldo (navn, saldo) VALUES (%s, %s)",
                ("Bankinnskudd 1920", startsaldo),
            )
    finally:
        conn.close()


def hent_saldo_update() -> int:
    conn = ny_tilkobling()
    conn.autocommit = True
    try:
        with conn.cursor() as c:
            c.execute("SELECT saldo FROM demo_konto_saldo WHERE id = 1")
            return c.fetchone()[0]
    finally:
        conn.close()


def usikker_update(navn, belop, barriere, resultater):
    """
    Klassisk les-beregn-skriv uten låsing.
    Demonstrerer ekte tapt oppdatering.
    """
    conn = ny_tilkobling()
    try:
        conn.autocommit = False

        # LES
        with conn.cursor() as c:
            c.execute("SELECT saldo FROM demo_konto_saldo WHERE id = 1")
            lest = c.fetchone()[0]

        print(f"  [{navn:6}] LES: saldo = {lest/100:,.0f} kr")

        barriere.wait()
        time.sleep(FORSINKELSE)

        ny_saldo = lest + belop

        with conn.cursor() as c:
            c.execute("UPDATE demo_konto_saldo SET saldo = %s WHERE id = 1", (ny_saldo,))

        conn.commit()

        faktisk = hent_saldo_update()
        print(
            f"  [{navn:6}] COMMIT: satte saldo = {ny_saldo/100:,.0f} kr  "
            f"(lest {lest/100:,.0f} + {belop/100:,.0f})  |  faktisk nå: {faktisk/100:,.0f} kr"
        )
        resultater[navn] = {"lest": lest, "belop": belop, "skrevet": ny_saldo}

    except Exception as e:
        conn.rollback()
        print(f"  [{navn:6}] FEIL: {e}")
        resultater[navn] = {"feil": str(e)}
    finally:
        conn.close()


def sikker_update_for_update(navn, belop, _barriere, resultater):
    """
    Les-beregn-skriv med SELECT FOR UPDATE.
    Den andre tråden må vente til låsen frigis.
    """
    conn = ny_tilkobling()
    try:
        conn.autocommit = False

        with conn.cursor() as c:
            c.execute("SELECT saldo FROM demo_konto_saldo WHERE id = 1 FOR UPDATE")
            lest = c.fetchone()[0]

        print(f"  [{navn:6}] LES+LÅS: saldo = {lest/100:,.0f} kr")

        time.sleep(FORSINKELSE)

        ny_saldo = lest + belop

        with conn.cursor() as c:
            c.execute("UPDATE demo_konto_saldo SET saldo = %s WHERE id = 1", (ny_saldo,))

        conn.commit()

        faktisk = hent_saldo_update()
        print(
            f"  [{navn:6}] COMMIT+FRIGJØR LÅS: saldo = {faktisk/100:,.0f} kr  "
            f"(lest {lest/100:,.0f} + {belop/100:,.0f})"
        )
        resultater[navn] = {"lest": lest, "belop": belop, "skrevet": ny_saldo}

    except Exception as e:
        conn.rollback()
        print(f"  [{navn:6}] FEIL: {e}")
        resultater[navn] = {"feil": str(e)}
    finally:
        conn.close()


# ─────────────────────────────────────────────────────────────────────────────
# Kjørehjelper
# ─────────────────────────────────────────────────────────────────────────────

def kjor_to_tradder(funksjon_a, args_a, funksjon_b, args_b):
    t1 = threading.Thread(target=funksjon_a, args=args_a)
    t2 = threading.Thread(target=funksjon_b, args=args_b)
    t1.start()
    t2.start()
    t1.join()
    t2.join()


# ─────────────────────────────────────────────────────────────────────────────
# Hovedprogram
# ─────────────────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    print("\n" + "█" * 62)
    print("  DEMONSTRASJON: TAPT OPPDATERING (LOST UPDATE)")
    print("  Oppgave 9 — Samtidige transaksjoner i PostgreSQL")
    print("█" * 62)
    print(
        f"  Forsinkelse LES→SKRIV: {FORSINKELSE}s  |  "
        f"Ane: +{BELOP_ANE/100:,.0f} kr  |  Bjørn: +{BELOP_BJORN/100:,.0f} kr\n"
    )

    try:
        rydd_test()
        kontekst = hent_kontekst()
        konto_guid = hent_konto_guid(KONTONUMMER)

        if not konto_guid:
            raise RuntimeError(f"Fant ikke konto med kontonummer {KONTONUMMER}.")

        startsaldo_insert = hent_saldo_insert(konto_guid)
        startsaldo_update = startsaldo_insert
        forventet = startsaldo_insert + BELOP_ANE + BELOP_BJORN

        # SCENARIO A
        print("═" * 62)
        print("  SCENARIO A: INSERT-basert modell (GnuCash/NS 4102)")
        print("  Begge tråder leser samme saldo, men skriver uavhengige INSERT-rader.")
        print("  Resultat: INGEN tapt oppdatering — INSERT er immunt by design.")
        print("─" * 62)
        print(f"  Saldo FØR: {startsaldo_insert/100:,.0f} kr  |  Forventet: {forventet/100:,.0f} kr")
        print("─" * 62)

        res_a = {}
        bar_a = threading.Barrier(2)
        kjor_to_tradder(
            insert_innbetaling,
            ("Ane", BELOP_ANE, konto_guid, kontekst, bar_a, res_a),
            insert_innbetaling,
            ("Bjørn", BELOP_BJORN, konto_guid, kontekst, bar_a, res_a),
        )

        saldo_etter_a = hent_saldo_insert(konto_guid)
        avvik_a = saldo_etter_a - forventet

        print("─" * 62)
        print(
            f"  Saldo ETTER: {saldo_etter_a/100:,.0f} kr  |  Forventet: {forventet/100:,.0f} kr  |  "
            + ("⚠️  TAPT!" if avvik_a else "✓ Korrekt")
        )

        # SCENARIO B1
        print("\n" + "═" * 62)
        print("  SCENARIO B1: UPDATE-basert — USIKKER (anti-mønster)")
        print("  Begge tråder leser SAMME saldo, beregner ny verdi og")
        print("  overskriver hverandre med UPDATE. Den siste vinner.")
        print("─" * 62)

        setup_update_tabell(startsaldo_update)
        print(f"  Saldo FØR: {startsaldo_update/100:,.0f} kr  |  Forventet: {forventet/100:,.0f} kr")
        print("─" * 62)

        res_b1 = {}
        bar_b1 = threading.Barrier(2)
        kjor_to_tradder(
            usikker_update,
            ("Ane", BELOP_ANE, bar_b1, res_b1),
            usikker_update,
            ("Bjørn", BELOP_BJORN, bar_b1, res_b1),
        )

        saldo_etter_b1 = hent_saldo_update()
        avvik_b1 = saldo_etter_b1 - forventet

        print("─" * 62)
        print(
            f"  Saldo ETTER: {saldo_etter_b1/100:,.0f} kr  |  Forventet: {forventet/100:,.0f} kr  |  "
            + (
                f"⚠️  TAPT OPPDATERING: {abs(avvik_b1)/100:,.0f} kr gikk tapt!"
                if avvik_b1
                else "✓ Korrekt"
            )
        )

        # SCENARIO B2
        print("\n" + "═" * 62)
        print("  SCENARIO B2: UPDATE-basert — SIKKER (SELECT FOR UPDATE)")
        print("  Den første tråden låser raden. Den andre venter til låsen frigis.")
        print("  Ingen Barrier nødvendig — låsen er synkroniseringsmekanismen.")
        print("─" * 62)

        setup_update_tabell(startsaldo_update)
        print(f"  Saldo FØR: {startsaldo_update/100:,.0f} kr  |  Forventet: {forventet/100:,.0f} kr")
        print("─" * 62)

        res_b2 = {}
        kjor_to_tradder(
            sikker_update_for_update,
            ("Ane", BELOP_ANE, None, res_b2),
            sikker_update_for_update,
            ("Bjørn", BELOP_BJORN, None, res_b2),
        )

        saldo_etter_b2 = hent_saldo_update()
        avvik_b2 = saldo_etter_b2 - forventet

        print("─" * 62)
        print(
            f"  Saldo ETTER: {saldo_etter_b2/100:,.0f} kr  |  Forventet: {forventet/100:,.0f} kr  |  "
            + (f"⚠️  TAPT: {abs(avvik_b2)/100:,.0f} kr" if avvik_b2 else "✓ Korrekt")
        )

        # SAMMENDRAG
        print("\n" + "═" * 62)
        print("  SAMMENDRAG")
        print("─" * 62)
        print(f"  {'Scenario':<48} {'Avvik':>10}")
        print(f"  {'─' * 48} {'─' * 10}")
        for tittel, avvik in [
            ("A:  INSERT-basert (GnuCash/NS 4102) — ingen låsing", avvik_a),
            ("B1: UPDATE-basert — USIKKER (les-beregn-skriv)", avvik_b1),
            ("B2: UPDATE-basert — SIKKER  (SELECT FOR UPDATE)", avvik_b2),
        ]:
            status = f"{avvik/100:+,.0f} kr" if avvik else "0 kr ✓"
            print(f"  {tittel:<48} {status:>10}")
        print("═" * 62)
        print()

    finally:
        try:
            rydd_test()
        except Exception:
            pass