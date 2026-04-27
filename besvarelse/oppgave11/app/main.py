"""
main.py — FastAPI-applikasjonsserver med APScheduler cron-jobb
Oppgave 11: MongoDB Staging
"""

import logging
from contextlib import asynccontextmanager
from datetime import datetime

from apscheduler.schedulers.background import BackgroundScheduler
from fastapi import FastAPI, HTTPException

from config import APP
from database import (
    initialiser_skjema,
    hent_kurshistorikk,
    hent_etl_statistikk,
)

from etl_pipeline import (
    kjor_etl_for_ticker,
    kjor_full_etl,
    OVERVAKEDE_VERDIPAPIRER,
)

from staging import (
    initialiser_collections,
    hent_dokument_for_ticker,
    hent_ubehandlede_dokumenter,
    hent_staging_statistikk,
)

logging.basicConfig(
    level=getattr(logging, APP.log_level, logging.INFO),
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%H:%M:%S",
)
log = logging.getLogger(__name__)

scheduler = BackgroundScheduler()


@asynccontextmanager
async def lifespan(app: FastAPI):
    log.info("=== Oppgave 11: MongoDB Staging — Starter ===")

    try:
        initialiser_skjema()
        log.info("PostgreSQL-skjema klart")
    except Exception as e:
        log.error(f"PostgreSQL-initialisering feilet: {e}")

    try:
        initialiser_collections()
        log.info("MongoDB collections klare")
    except Exception as e:
        log.error(f"MongoDB-initialisering feilet: {e}")

    scheduler.add_job(
        kjor_full_etl,
        "interval",
        seconds=APP.etl_intervall,
        id="full_etl",
        replace_existing=True,
        max_instances=1,
    )
    scheduler.start()
    log.info(f"APScheduler startet — ETL kjøres hvert {APP.etl_intervall}s")

    yield

    scheduler.shutdown(wait=False)
    log.info("=== Oppgave 11-applikasjon avsluttet ===")


app = FastAPI(
    title="Oppgave 11: MongoDB Staging",
    description="ETL-pipeline for finansielle kursdata — NS 4102 Regnskapssystem",
    version="1.0.0",
    lifespan=lifespan,
)


@app.get("/helse", tags=["System"])
def helse():
    return {
        "status": "OK",
        "tidspunkt": datetime.now().isoformat(),
        "tjeneste": "Oppgave 11 MongoDB Staging",
    }


@app.get("/verdipapirer", tags=["Verdipapirer"])
def list_verdipapirer():
    return {"verdipapirer": OVERVAKEDE_VERDIPAPIRER}


@app.get("/kurser/{ticker}", tags=["Kurser"])
def hent_kurser(ticker: str, antall: int = 10):
    kurser = hent_kurshistorikk(ticker.upper(), antall)
    if not kurser:
        raise HTTPException(status_code=404, detail=f"Ingen kurser funnet for {ticker}")
    return {
        "ticker": ticker.upper(),
        "antall": len(kurser),
        "kurser": kurser,
    }


@app.post("/etl/alle", tags=["ETL"])
def kjor_etl_alle():
    log.info("Manuell full ETL-kjøring startet")
    resultater = kjor_full_etl()
    return {
        "totalt": len(resultater),
        "vellykkede": sum(1 for r in resultater if r["suksess"]),
        "resultater": resultater,
    }


@app.post("/etl/{ticker}", tags=["ETL"])
def kjor_etl_manuelt(ticker: str):
    log.info(f"Manuell ETL-kjøring for {ticker}")
    resultat = kjor_etl_for_ticker(ticker.upper())
    if not resultat["suksess"]:
        raise HTTPException(status_code=500, detail=resultat["feilmelding"])
    return resultat


@app.get("/staging/ubehandlet", tags=["MongoDB Staging"])
def hent_ubehandlet():
    dokumenter = hent_ubehandlede_dokumenter()
    for dok in dokumenter:
        dok["_id"] = str(dok["_id"])
    return {
        "antall": len(dokumenter),
        "dokumenter": dokumenter,
    }


@app.get("/staging/{ticker}", tags=["MongoDB Staging"])
def hent_staging_for_ticker(ticker: str, antall: int = 5):
    dokumenter = hent_dokument_for_ticker(ticker.upper(), antall)
    for dok in dokumenter:
        dok["_id"] = str(dok["_id"])
    return {
        "ticker": ticker.upper(),
        "antall": len(dokumenter),
        "dokumenter": dokumenter,
    }


@app.get("/statistikk/etl", tags=["Statistikk"])
def etl_statistikk():
    return {"statistikk": hent_etl_statistikk()}


@app.get("/statistikk/staging", tags=["Statistikk"])
def staging_statistikk():
    statistikk = hent_staging_statistikk()
    for s in statistikk:
        if "_id" in s:
            s["ticker"] = s.pop("_id")
    return {"statistikk": statistikk}