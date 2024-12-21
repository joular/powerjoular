#!/usr/bin/env python3
from fastapi import FastAPI, HTTPException
from fastapi.responses import JSONResponse
from pydantic import BaseModel
import csv
from datetime import datetime
import uvicorn

app = FastAPI()

class PowerData(BaseModel):
    timestamp: str
    variation: float
    total_power: float
    cpu_power: float
    gpu_power: float

def read_latest_power_data():
    try:
        with open('/tmp/powerjoular-service.csv', 'r') as f:
            reader = csv.reader(f)
            last_row = list(reader)[-1]
            return PowerData(
                timestamp=last_row[0],
                variation=float(last_row[1]),
                total_power=float(last_row[2]),
                cpu_power=float(last_row[3]),
                gpu_power=float(last_row[4])
            )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error while reading data : {str(e)}")

@app.get("/power", response_model=PowerData)
async def get_power():
    return read_latest_power_data()

@app.get("/power/{metric}")
async def get_power_metric(metric: str):
    data = read_latest_power_data()
    if hasattr(data, metric):
        return JSONResponse(content={metric: getattr(data, metric)})
    else:
        raise HTTPException(status_code=404, detail=f"Metric '{metric}' not found")

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=22407)
