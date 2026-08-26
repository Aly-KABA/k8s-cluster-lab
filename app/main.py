"""
API de supervision de KPIs réseau (latence, débit, taux de perte).
Simule un outil de monitoring réseau simplifié.

Endpoints :
- GET  /health       -> vérifie que l'API tourne (utilisé par les probes Kubernetes)
- POST /kpi          -> enregistre une mesure
- GET  /kpi          -> liste toutes les mesures
- GET  /kpi/alerts   -> retourne les mesures qui dépassent les seuils définis
"""

import os
import psycopg2
from fastapi import FastAPI
from pydantic import BaseModel

app = FastAPI(title="API Supervision KPIs Réseau")

# --- Configuration lue depuis les variables d'environnement ---
# (injectées par le ConfigMap et le Secret Kubernetes, voir manifests/)
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_NAME = os.getenv("DB_NAME", "kpidb")
DB_USER = os.getenv("DB_USER", "postgres")
DB_PASSWORD = os.getenv("DB_PASSWORD", "postgres")

# Seuils d'alerte (viennent du ConfigMap)
LATENCY_THRESHOLD_MS = float(os.getenv("LATENCY_THRESHOLD_MS", "50"))
LOSS_THRESHOLD_PERCENT = float(os.getenv("LOSS_THRESHOLD_PERCENT", "1"))


def get_connection():
    """Ouvre une connexion à la base PostgreSQL."""
    return psycopg2.connect(
        host=DB_HOST, dbname=DB_NAME, user=DB_USER, password=DB_PASSWORD
    )


def init_db():
    """Crée la table des mesures si elle n'existe pas encore."""
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("""
        CREATE TABLE IF NOT EXISTS kpi_measurements (
            id SERIAL PRIMARY KEY,
            site_name TEXT NOT NULL,
            latency_ms FLOAT NOT NULL,
            throughput_mbps FLOAT NOT NULL,
            packet_loss_percent FLOAT NOT NULL,
            recorded_at TIMESTAMP DEFAULT NOW()
        )
    """)
    conn.commit()
    cur.close()
    conn.close()


class KpiMeasurement(BaseModel):
    site_name: str
    latency_ms: float
    throughput_mbps: float
    packet_loss_percent: float


@app.on_event("startup")
def on_startup():
    init_db()


@app.get("/health")
def health():
    """Endpoint de health-check, utilisé par les probes Kubernetes."""
    return {"status": "ok"}


@app.post("/kpi")
def create_measurement(measurement: KpiMeasurement):
    """Enregistre une nouvelle mesure de KPI réseau."""
    conn = get_connection()
    cur = conn.cursor()
    cur.execute(
        """
        INSERT INTO kpi_measurements (site_name, latency_ms, throughput_mbps, packet_loss_percent)
        VALUES (%s, %s, %s, %s) RETURNING id
        """,
        (
            measurement.site_name,
            measurement.latency_ms,
            measurement.throughput_mbps,
            measurement.packet_loss_percent,
        ),
    )
    new_id = cur.fetchone()[0]
    conn.commit()
    cur.close()
    conn.close()
    return {"id": new_id, "message": "Mesure enregistrée"}


@app.get("/kpi")
def list_measurements():
    """Retourne toutes les mesures enregistrées."""
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("""
        SELECT id, site_name, latency_ms, throughput_mbps, packet_loss_percent, recorded_at
        FROM kpi_measurements ORDER BY recorded_at DESC
    """)
    rows = cur.fetchall()
    cur.close()
    conn.close()
    return [
        {
            "id": r[0],
            "site_name": r[1],
            "latency_ms": r[2],
            "throughput_mbps": r[3],
            "packet_loss_percent": r[4],
            "recorded_at": r[5].isoformat(),
        }
        for r in rows
    ]


@app.get("/kpi/alerts")
def list_alerts():
    """Retourne les mesures qui dépassent les seuils définis dans le ConfigMap."""
    conn = get_connection()
    cur = conn.cursor()
    cur.execute(
        """
        SELECT id, site_name, latency_ms, packet_loss_percent, recorded_at
        FROM kpi_measurements
        WHERE latency_ms > %s OR packet_loss_percent > %s
        ORDER BY recorded_at DESC
        """,
        (LATENCY_THRESHOLD_MS, LOSS_THRESHOLD_PERCENT),
    )
    rows = cur.fetchall()
    cur.close()
    conn.close()
    return {
        "thresholds": {
            "latency_ms": LATENCY_THRESHOLD_MS,
            "packet_loss_percent": LOSS_THRESHOLD_PERCENT,
        },
        "alerts": [
            {
                "id": r[0],
                "site_name": r[1],
                "latency_ms": r[2],
                "packet_loss_percent": r[3],
                "recorded_at": r[4].isoformat(),
            }
            for r in rows
        ],
    }
