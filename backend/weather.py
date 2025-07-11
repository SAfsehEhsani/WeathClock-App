import httpx
from datetime import datetime
from zoneinfo import ZoneInfo

API_KEY ="abfd9c8add034aee7687d82779ece8b5"

async def get_weather_time(city: str):
    url = f"http://api.openweathermap.org/data/2.5/weather?q={city}&appid={API_KEY}&units=metric"
    
    async with httpx.AsyncClient() as client:
        response = await client.get(url)
        data = response.json()

    if response.status_code != 200:
        return {"error": "City not found"}

    temp = data["main"]["temp"]
    desc = data["weather"][0]["description"]
    timezone_seconds = data["timezone"]
    local_time = datetime.utcnow().timestamp() + timezone_seconds
    local_time_str = datetime.fromtimestamp(local_time).strftime("%H:%M:%S")

    return {
        "city": city,
        "temperature": temp,
        "description": desc,
        "local_time": local_time_str
    }
