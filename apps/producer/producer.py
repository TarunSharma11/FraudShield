import os, json, time, uuid, random
from kafka import KafkaProducer

BOOTSTRAP = os.getenv("KAFKA_BOOTSTRAP", "localhost:9092")
TOPIC = os.getenv("KAFKA_TOPIC", "transactions.raw")

producer = KafkaProducer(
    bootstrap_servers=BOOTSTRAP.split(","),
    value_serializer=lambda v: json.dumps(v).encode("utf-8"),
    acks="all",
    linger_ms=5,
)

def fake_event():
    return {
        "event_id": str(uuid.uuid4()),
        "ts": int(time.time()*1000),
        "account_id": f"A{random.randint(1000,9999)}",
        "amount": round(random.uniform(1.0, 250.0), 2),
        "currency": "USD",
        "merchant_id": f"M{random.randint(10,99)}",
        "device_id": f"D{random.randint(100,999)}",
        "channel": random.choice(["card_present","card_not_present","ach"]),
    }

if __name__ == "__main__":
    print(f"Producing to {BOOTSTRAP} topic {TOPIC} ... Ctrl+C to stop")
    while True:
        evt = fake_event()
        producer.send(TOPIC, evt)
        print("sent", evt["event_id"], evt["amount"])
        time.sleep(0.25)
