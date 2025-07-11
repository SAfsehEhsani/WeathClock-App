from fastapi import FastAPI, Query
from fastapi.middleware.cors import CORSMiddleware
from weather import get_weather_time

app = FastAPI()

# Allow CORS for Flutter
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/weather_time")
async def weather_time(city: str = Query(...)):
    return await get_weather_time(city)
