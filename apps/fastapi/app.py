from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import os, json
import redis
import boto3
from botocore.config import Config

app = FastAPI(title="FraudShield API")

REDIS_HOST = os.getenv("REDIS_HOST", "localhost")
REDIS_PORT = int(os.getenv("REDIS_PORT", "6379"))
TIMESTREAM_DB = os.getenv("TIMESTREAM_DB", "fraudshield_db")
AWS_REGION = os.getenv("AWS_REGION", "us-east-1")

r = redis.Redis(host=REDIS_HOST, port=REDIS_PORT, decode_responses=True)

timestream = boto3.client("timestream-write", region_name=AWS_REGION, config=Config(read_timeout=20, retries={'max_attempts': 3}))

class ScoreRequest(BaseModel):
    event_id: str
    account_id: str | None = None
    amount: float | None = None

@app.get("/health")
def health():
    try:
        r.ping()
        return {"status": "ok"}
    except Exception as e:
        return {"status": "degraded", "error": str(e)}

@app.post("/score")
def score(req: ScoreRequest):
    # This is a stub — real scoring happens in Flink. Here we just check cache.
    decision = r.get(f"decision:{req.event_id}")
    if decision:
        return json.loads(decision)
    # Fall back to a simple allow with low risk score
    resp = {"event_id": req.event_id, "action": "APPROVE", "score": 0.01, "source": "api-fallback"}
    return resp

@app.get("/decision/{event_id}")
def get_decision(event_id: str):
    decision = r.get(f"decision:{event_id}")
    if not decision:
        raise HTTPException(status_code=404, detail="Decision not found")
    return json.loads(decision)

@app.post("/feedback")
def feedback(payload: dict):
    # Example of appending feedback marker into Timestream (best-effort)
    try:
        timestream.write_records(
            DatabaseName=TIMESTREAM_DB,
            TableName="decisions",
            Records=[{
                "Dimensions": [{"Name":"type","Value":"feedback"}],
                "MeasureName": "label",
                "MeasureValue": payload.get("label","unknown"),
                "MeasureValueType": "VARCHAR",
                "Time": str(int(__import__("time").time() * 1000)),
                "TimeUnit": "MILLISECONDS"
            }]
        )
    except Exception as e:
        # swallow errors in this stub
        pass
    return {"ok": True}
