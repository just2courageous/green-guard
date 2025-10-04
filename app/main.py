# Import FastAPI (web framework) so we can create HTTP endpoints
from fastapi import FastAPI

# Import time so we can simulate work by sleeping for N milliseconds
import time

# Create a FastAPI application instance (the web app object)
app = FastAPI()

# Define a GET endpoint at "/" (root URL)
@app.get("/")
def home():
    # Return JSON response (FastAPI auto-converts dict -> JSON)
    return {"ok": True, "msg": "Green-Guard demo"}

# Define a GET endpoint at "/healthz" used by probes/monitoring
@app.get("/healthz")
def health():
    # Respond with simple JSON to indicate the app is healthy
    return {"status": "healthy"}

# Define a GET endpoint at "/compute" that accepts a query param "ms"
@app.get("/compute")
def compute(ms: int = 50):  # ms has type int and default value 50
    # Pause the process for ms milliseconds to mimic some work/latency
    time.sleep(ms / 1000)
    # Return how long we slept so the caller can see the effect
    return {"slept_ms": ms}
