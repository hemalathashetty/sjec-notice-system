import os

with open('summarizer.py', 'r', encoding='utf-8') as f:
    code = f.read()

code = code.replace('def generate_summary(', 'def _generate_summary_fallback(')

new_logic = """import os
import google.generativeai as genai
from dotenv import load_dotenv
import re

load_dotenv()
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
if GEMINI_API_KEY:
    genai.configure(api_key=GEMINI_API_KEY)

def generate_summary(text: str) -> str:
    if not text or len(text.strip()) < 10:
        return "No content available."

    if GEMINI_API_KEY:
        try:
            model = genai.GenerativeModel("gemini-1.5-flash")
            prompt = f\"\"\"
You are an intelligent notice summarizer for a college platform. 
Your task is to read the provided notice text and extract the most critical, actionable details into a highly structured, pointwise summary.

Adapt to the specific type of notice:
- If it's an Event (Workshop, Seminar): Extract Event, Event Date, Venue, Eligibility, Last Date, Action.
- If it's an Exam Registration: Extract Notice Title, Last Date, Action, Important Instructions.
- If it's a Fee Payment: Extract Purpose, Deadline, Amount (if present), Action.

Rules:
1. ONLY extract information that is explicitly stated. Do not make assumptions.
2. Structure the output strictly as key-value pairs separated by ' | '.
3. Keep it exceptionally concise (maximum 50 words total).
4. For action items, combine the link/method and deadline cleanly (e.g. "Action: Register before 05-05-2026").
5. Do NOT include bullet points, newlines, or asterisks. Output a single raw string separated by pipes.

Example Output format:
Notice: End Semester Exam Registration | Last Date: 30-04-2026 | Action: Complete registration through college portal | Important: Pay fees and submit form before deadline

Notice Text:
{text}

Summarize:
\"\"\"
            response = model.generate_content(prompt)
            result = response.text.strip()
            
            # Clean up markdown formatting and newlines
            result = result.replace('**', '').replace('\\n', ' | ')
            result = re.sub(r'\\s*\\|\\s*\\|\\s*', ' | ', result) 
            
            # Strip trailing pipes
            result = result.strip(' |')
            
            if len(result) > 10 and '|' in result:
                return result
        except Exception as e:
            print("Gemini summarizer failed, falling back:", e)

    return _generate_summary_fallback(text)
"""

with open('summarizer.py', 'w', encoding='utf-8') as f:
    f.write(new_logic + '\n\n' + code)
