from flask import Flask, request, jsonify, Response, stream_with_context
import requests
import os
import json

app = Flask(__name__)

OPENWEATHER_API_KEY = os.environ.get("OPENWEATHER_API_KEY", "YOUR_API_KEY_HERE")
OLLAMA_API_URL = os.environ.get("OLLAMA_API_URL", "http://localhost:11434/api/chat")

def get_weather_for(location, date):
    url = "http://api.openweathermap.org/data/2.5/forecast"
    params = {
        "q": location,
        "appid": OPENWEATHER_API_KEY,
        "units": "metric",
        "lang": "te"
    }
    resp = requests.get(url, params=params)
    if resp.status_code != 200 or not resp.json().get("list"):
        return f"Cannot fetch weather for {location}."
    data = resp.json()
    forecast = data["list"][0]
    desc = forecast["weather"][0]["description"]
    temp = forecast["main"]["temp"]
    return f"{location} వాతావరణం: {desc}, ఉష్ణోగ్రత: {temp}°C"

def is_weather_question(text):
    weather_keywords = ["వాతావరణం", "వర్షం", "weather", "rain", "పడుతుందా", "today", "tomorrow"]
    return any(word in text.lower() for word in weather_keywords)

@app.route('/mcp/chat', methods=['POST'])
def chat_handler():
    data = request.json
    user_message = data.get('message', '')
    location = data.get('location', 'Hyderabad')
    date = data.get('date', 'today')

    if is_weather_question(user_message):
        weather = get_weather_for(location, date)
        system_prompt = (
            "మీరు తెలుగులో మాట్లాడే రైతులకు సహాయపడే సహాయకుడు. "
            "వాతావరణం గురించి అడిగితే, క్రింది వాస్తవిక వాతావరణ సమాచారాన్ని ఉపయోగించి తెలుగులో స్నేహపూర్వకంగా సమాధానం ఇవ్వండి. "
            "ఎప్పుడూ తెలుగులో సమాధానం ఇవ్వండి.\n"
            f"వాస్తవిక వాతావరణ సమాచారం: {weather}"
        )
        messages = [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_message}
        ]
    else:
        messages = [
            {"role": "system", "content": "మీరు తెలుగులో మాట్లాడే రైతులకు సహాయపడే సహాయకుడు. ఎప్పుడూ తెలుగులో సమాధానం ఇవ్వండి."},
            {"role": "user", "content": user_message}
        ]

    def generate():
        ollama_payload = {
            "model": "gemma3:1b",
            "messages": messages,
            "stream": True
        }
        with requests.post(OLLAMA_API_URL, json=ollama_payload, stream=True) as ollama_resp:
            buffer = ''
            for chunk in ollama_resp.iter_content(chunk_size=None):
                if not chunk:
                    continue
                buffer += chunk.decode('utf-8')
                lines = buffer.split('\n')
                buffer = lines.pop()  # incomplete line
                for line in lines:
                    if not line.strip():
                        continue
                    try:
                        data = json.loads(line)
                        content = data.get('message', {}).get('content', '') or data.get('response', '')
                        if content:
                            yield json.dumps({"result": content}) + '\n'
                    except Exception:
                        continue
    return Response(stream_with_context(generate()), mimetype='application/json')

if __name__ == '__main__':
    app.run(port=5001) 