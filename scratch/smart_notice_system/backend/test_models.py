from google import genai
import os
from dotenv import load_dotenv

load_dotenv()
client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))

try:
    response = client.models.generate_content(
        model='gemini-2.5-flash',
        contents='hello'
    )
    print("gemini-2.5-flash worked:", response.text)
except Exception as e:
    print("gemini-2.5-flash failed:", e)

try:
    response = client.models.generate_content(
        model='gemini-1.5-flash',
        contents='hello'
    )
    print("gemini-1.5-flash worked:", response.text)
except Exception as e:
    print("gemini-1.5-flash failed:", e)
