import os
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
            model = genai.GenerativeModel("gemini-pro")
            prompt = f"""
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
"""
            response = model.generate_content(prompt)
            result = response.text.strip()
            
            # Clean up markdown formatting and newlines
            result = result.replace('**', '').replace('\n', ' | ')
            result = re.sub(r'\s*\|\s*\|\s*', ' | ', result) 
            
            # Strip trailing pipes
            result = result.strip(' |')
            
            if len(result) > 10 and '|' in result:
                return result
        except Exception as e:
            print("Gemini summarizer failed, falling back:", e)

    return _generate_summary_fallback(text)


import os
import google.generativeai as genai
from dotenv import load_dotenv
import re

load_dotenv()
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
if GEMINI_API_KEY:
    genai.configure(api_key=GEMINI_API_KEY)

def _generate_summary_fallback(text: str) -> str:
    if not text or len(text.strip()) < 10:
        return "No content available."

    if GEMINI_API_KEY:
        try:
            model = genai.GenerativeModel("gemini-1.5-flash")
            prompt = f"""
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
"""
            response = model.generate_content(prompt)
            result = response.text.strip()
            
            # Clean up markdown formatting and newlines
            result = result.replace('**', '').replace('\n', ' | ')
            result = re.sub(r'\s*\|\s*\|\s*', ' | ', result) 
            
            # Strip trailing pipes
            result = result.strip(' |')
            
            if len(result) > 10 and '|' in result:
                return result
        except Exception as e:
            print("Gemini summarizer failed, falling back:", e)

    return _generate_summary_fallback(text)


import re

def _generate_summary_fallback(text: str) -> str:
    """
    ATCD-based smart summarizer
    Extracts key points from any notice text
    Returns pointwise summary separated by |
    """
    if not text or len(text.strip()) < 10:
        return "No content available."

    # Clean text
    # Clean text - remove markdown formatting
    text = re.sub(r'\*\*', '', text)  # remove **bold**
    text = re.sub(r'\*', '', text)    # remove *italic*
    text = re.sub(r'–', '-', text)    # normalize dashes
    text = re.sub(r'\s+', ' ', text).strip()
    text_lower = text.lower()

    summary_parts = []

    # ── ATCD STEP 1: LEXICAL ANALYSIS ─────────────────────────
    # Split into sentences (tokenization)
    sentences = re.split(r'(?<=[.!?\n])\s+', text)
    sentences = [s.strip() for s in sentences if len(s.strip()) > 8]

    # Generate a one-sentence summary to prepend
    scored = []
    keywords = ['workshop', 'seminar', 'exam', 'meeting', 'date',
               'venue', 'time', 'register', 'attend', 'scheduled',
               'conducted', 'organized', 'invited', 'requested',
               'scholarship', 'fee', 'deadline', 'eligible']
    for i, sentence in enumerate(sentences):
        score = sum(1 for kw in keywords if kw in sentence.lower())
        # Boost earlier sentences to prefer the main context over secondary details
        if i == 0:
            score += 2
        elif i == 1:
            score += 1
        if score > 0:
            scored.append((score, sentence))
    scored.sort(reverse=True)
    top_sentence = scored[0][1] if scored else (sentences[0] if sentences else text[:100])
    summary_parts.append(f"Summary: {top_sentence}")

    # ── ATCD STEP 2: PATTERN MATCHING (DFA) ───────────────────

    # 1. EVENT TYPE DETECTION
    event_map = {
        'Class Committee Meeting': r'class committee',
        'Workshop': r'\bworkshop\b',
        'Seminar': r'\bseminar\b',
        'Exam': r'\bexam\b|\btest\b|\bquiz\b',
        'Interview': r'\binterview\b',
        'Placement Drive': r'\bplacement\b|\bcampus drive\b|\brecruitment\b',
        'Internship': r'\binternship\b',
        'University Fair': r'university fair',
        'Fest': r'\bfest\b|\bfestival\b',
        'Meeting': r'\bmeeting\b',
        'Webinar': r'\bwebinar\b',
        'Hackathon': r'\bhackathon\b',
        'Competition': r'\bcompetition\b|\bcontest\b',
        'Training Program': r'\btraining\b|\bprogram\b',
        'Guest Lecture': r'\blecture\b|\bguest talk\b|\btalk\b',
        'Sports Event': r'\bsports\b|\btournament\b|\bmatch\b',
        'Club Activity': r'\bclub\b|\bassociation\b',
        'Cultural Event': r'\bcultural\b|\bdance\b|\bmusic\b',
        'Scholarship Registration': r'\bscholarship\b.*\bregistration\b|\bscholarship\b',
        'Fee Payment': r'\bfee\b.*\bpayment\b|\bfee payment\b',
    }
    for event_name, pattern in event_map.items():
        if re.search(pattern, text_lower):
            # Try to get the specific topic (e.g., Seminar on X)
            topic_match = re.search(f"(?:{pattern})\\s+(?:on|regarding|about)\\s+([A-Z][A-Za-z0-9\\s&,-]+?)(?=\\s+will|\\s+is|\\s+to be|\\s+organized|\\s+conducted|\\s+held|\\s+scheduled|\\s+for|\\s+by|\\.|\\n|,)", text, re.IGNORECASE)
            if topic_match and topic_match.group(1):
                topic = topic_match.group(1).strip()
                summary_parts.append(f"Event: {event_name} on {topic}")
            else:
                summary_parts.append(f"Event: {event_name}")
            break

    # 2. DATE EXTRACTION (only valid years 2024-2030)
    date_patterns = [
        r'\b(0?[1-9]|[12]\d|3[01])[\/\-](0?[1-9]|1[0-2])[\/\-](202[0-9])\b',
        r'\b(\d{1,2})\s+(January|February|March|April|May|June|July|August|'
        r'September|October|November|December)\s+(202[0-9])\b',
        r'\b(\d{1,2})\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)'
        r'\s+(202[0-9])\b',
        r'\b(\d{1,2})(?:st|nd|rd|th)\s+(January|February|March|April|May|June|'
        r'July|August|September|October|November|December)\s+(202[0-9])\b',
    ]
    all_dates = []
    for pattern in date_patterns:
        matches = re.findall(pattern, text, re.IGNORECASE)
        for match in matches:
            date_str = ' '.join([m for m in match if m]).strip()
            if date_str and date_str not in all_dates:
                all_dates.append(date_str)
    # We will append the date later to ensure we remove the deadline from it
    extracted_dates = []
    if all_dates:
        extracted_dates = all_dates[:3]

    # 3. TIME EXTRACTION
    time_match = re.search(
        r'\b(\d{1,2}[:.]\d{2}\s*(?:am|pm|AM|PM)?'
        r'(?:\s*(?:to|-|–)\s*\d{1,2}[:.]\d{2}\s*(?:am|pm|AM|PM)?)?)\b',
        text, re.IGNORECASE
    )
    if time_match:
        time_str = time_match.group(1).strip()
        if len(time_str) > 2:
            summary_parts.append(f"Time: {time_str}")

    # 4. VENUE EXTRACTION
    venue_found = False
    venue_explicit = re.search(
        r'(?:venue|held at|held in|place|location|conducted at|conducted in|organized at|organized in)'
        r'\s*[:\-]?\s*([A-Za-z0-9\s,\.]+?)(?:[.\n]|$)',
        text, re.IGNORECASE
    )
    if venue_explicit:
        venue = venue_explicit.group(1).strip()[:60]
        if len(venue) > 3:
            summary_parts.append(f"Venue: {venue}")
            venue_found = True

    if not venue_found:
        venue_match = re.search(
            r'(?:in the|at the|at)\s+([A-Za-z0-9\s,]+?'
            r'(?:room|hall|lab|ground|auditorium|audi|center|centre|block|building)'
            r'[A-Za-z0-9\s,]*)(?:[.\n]|$)',
            text, re.IGNORECASE
        )
        if venue_match:
            venue = venue_match.group(1).strip()[:60]
            if len(venue) > 3:
                summary_parts.append(f"Venue: {venue}")
                venue_found = True

    if not venue_found:
        known_venues = re.search(
            r'\b([A-Z][a-zA-Z\s]*'
            r'(?:Hall|Auditorium|Lab|Room|Ground|Center|Centre|Block|Audi))\b',
            text
        )
        if known_venues:
            venue = known_venues.group(1).strip()[:60]
            if len(venue) > 3:
                summary_parts.append(f"Venue: {venue}")

    # 5. DEADLINE / LAST DATE
    deadline_match = re.search(
        r'(?:last date|deadline|due date|submit by|apply by|'
        r'register by|registration closes?|remain open until|'
        r'open until|close on|on or before|before)\s*'
        r'(?:for\s+registration\s+is\s+|is\s+|for\s+submission\s+is\s+|to\s+apply\s+is\s+)?'
        r'[:\-,]?\s*([^\.\n]{3,60})',
        text, re.IGNORECASE
        )
    if deadline_match:
        deadline = deadline_match.group(1).strip()
        deadline = re.sub(r'\s+', ' ', deadline)[:60]
        if len(deadline) > 2:
            summary_parts.append(f"Last Date: {deadline}")
            # Remove deadline from extracted_dates if present to avoid duplication
            deadline_clean = re.sub(r'[^A-Za-z0-9]', '', deadline).lower()
            filtered_dates = []
            for d in extracted_dates:
                d_clean = re.sub(r'[^A-Za-z0-9]', '', d).lower()
                if d_clean not in deadline_clean and deadline_clean not in d_clean:
                    filtered_dates.append(d)
            extracted_dates = filtered_dates

    # Append dates after checking against deadline
    if extracted_dates:
        summary_parts.append(f"Date: {', '.join(extracted_dates)}")

    # 6. REGISTRATION LINK
    reg_link = re.search(
        r'(?:register at|registration link|forms?\.gle|bit\.ly|'
        r'google form|registration form)\s*[:\-]?\s*([^\s]+)',
        text, re.IGNORECASE
    )
    if reg_link:
        link = reg_link.group(1).strip()[:80]
        summary_parts.append(f"Register: {link}")

    # 7. TARGET AUDIENCE
    audience_patterns = [
        r'((?:VI|V|IV|III|II|I)\s+Sem\s+[A-Z]+(?:\s+students?)?)',
        r'((?:6th|5th|4th|3rd|2nd|1st|final)\s+sem(?:ester)?\s+[A-Za-z]+)',
        r'((?:UG|PG|1st|2nd|3rd|4th|final)\s*[-\s]?year\s*students?)',
        r'for\s+(?:all\s+)?([A-Za-z\s]+students?)',
        r'((?:CSE|CSBS|CSDS|AIML|EEE|EC|ME|Civil|MBA|MCA)'
        r'\s*(?:students?|dept|department)?)',
    ]
    for pattern in audience_patterns:
        match = re.search(pattern, text, re.IGNORECASE)
        if match:
            audience = match.group(0).strip()[:60]
            if len(audience) > 3:
                summary_parts.append(f"For: {audience}")
                break

    # 8. ORGANIZER / COORDINATOR
    coord_match = re.search(
        r'(?:coordinator|class advisor|hod|organized by|'
        r'faculty coordinator|contact)\s*[:\-]?\s*'
        r'((?:Dr|Mr|Ms|Mrs|Prof)\.?\s+[A-Za-z\s]+?)(?:[,.\n]|$)',
        text, re.IGNORECASE
    )
    if coord_match:
        coord = coord_match.group(1).strip()[:50]
        if len(coord) > 3:
            summary_parts.append(f"By: {coord}")

    # 9. DATE RANGE (from X to Y)
    date_range = re.search(
        r'(?:from|commence from|starting from)\s+'
        r'([^\n]{3,40}?)\s+(?:to|until|till|and will remain open until)\s+'
        r'([^\n.]{3,40})',
        text, re.IGNORECASE
    )
    if date_range and 'Date:' not in ' '.join(summary_parts):
        start = date_range.group(1).strip()[:40]
        end = date_range.group(2).strip()[:40]
        summary_parts.append(f"Duration: {start} to {end}")

    # 10. IMPORTANT NOTES
    important_patterns = [
        r'((?:mandatory|compulsory|all students must|'
        r'attendance is required|requested to attend|'
        r'kindly attend|strongly advised)[^.\n]{0,100})',
        r'(no further extensions?[^.\n]{0,80})',
        r'(incomplete application[^.\n]{0,80})',
    ]
    for pattern in important_patterns:
        match = re.search(pattern, text, re.IGNORECASE)
        if match:
            note = match.group(1).strip()[:120]
            summary_parts.append(f"Note: {note}")
            break

    # 11. DOCUMENTS REQUIRED
    docs_match = re.search(
        r'(?:documents?|documents? required|including|such as)\s*[,:]?\s*'
        r'([^.\n]{10,150})',
        text, re.IGNORECASE
    )
    if docs_match:
        docs = docs_match.group(1).strip()[:120]
        if any(word in docs.lower() for word in
               ['certificate', 'records', 'proof', 'details', 'id']):
            summary_parts.append(f"Documents: {docs}")

    # 12. CONTACT INFO
    contact_match = re.search(
        r'(?:contact|queries|assistance|helpdesk)\s*[^.\n]{0,30}'
        r'(scholarship cell|administrative office|department|'
        r'office[^.\n]{0,40})',
        text, re.IGNORECASE
    )
    if contact_match:
        contact = contact_match.group(0).strip()[:80]
        summary_parts.append(f"Contact: {contact}")

    # 13. ELIGIBILITY
    eligibility_text = None
    eligibility_explicit = re.search(
        r'(?:eligibility|criteria|who can apply)\s*[:\-,]\s*([^.\n]{5,100})',
        text, re.IGNORECASE
    )
    if eligibility_explicit:
        eligibility_text = eligibility_explicit.group(1).strip()
    else:
        # If no explicit label, look for a sentence containing 'eligible'
        for sentence in sentences:
            if 'eligible' in sentence.lower() or 'eligibility' in sentence.lower():
                eligibility_text = sentence.strip()
                break

    if eligibility_text:
        summary_parts.append(f"Eligibility: {eligibility_text[:100]}")

    # 14. PRIZE / BENEFIT INFO
    prize = re.search(
        r'((?:prize|cash prize|certificate|scholarship amount|'
        r'free|no registration fee|benefit)[^.\n]{0,80})',
        text, re.IGNORECASE
    )
    if prize:
        prize_text = prize.group(1).strip()[:80]
        if prize_text not in ' '.join(summary_parts):
            summary_parts.append(f"Benefit: {prize_text}")

    # ── ATCD STEP 3: PARSING & FORMATTING ─────────────────────
    props = {}
    for part in summary_parts:
        if part.startswith("Summary: "):
            props["Summary"] = part[9:]
        elif ": " in part:
            k, v = part.split(": ", 1)
            props[k] = v

    final_parts = []
    event_type = props.get("Event")
    
    # Check if it's a standard event or something else
    is_academic = event_type and any(k in event_type.lower() for k in ['exam', 'registration', 'fee', 'scholarship', 'internship', 'placement'])
    
    if is_academic or not event_type:
        # Dynamic format for Exams, Fees, Registrations, or unknown
        # 1. Notice Title / Topic
        topic_match = re.search(r'((?:Supplementary|End Semester|Mid Semester)?\s*(?:Exam|Examination|Test)\s*(?:Registration|Fee)?)(?:\s|\.|,)', text, re.IGNORECASE)
        if topic_match:
            topic = topic_match.group(1).title()
        else:
            topic = event_type or props.get("Summary", text[:50])
            if "Supplementary Exam" in text:
                topic = "Supplementary Exam Registration"
        final_parts.append(f"Notice: {topic}")
        
        # 2. Eligibility
        eligibility = props.get("Eligibility")
        if eligibility:
            # Shorten eligibility to "Students with backlogs" if that exists
            if "backlog" in text.lower():
                eligibility = "Students with backlogs"
            final_parts.append(f"Eligibility: {eligibility}")
        elif "backlog" in text.lower():
            final_parts.append("Eligibility: Students with backlogs")
            
        # 3. Last Date
        last_date = props.get("Last Date")
        if last_date:
            final_parts.append(f"Last Date: {last_date}")
            
        # 4. Action
        reg_link = props.get("Register")
        action_sent = ""
        if reg_link:
            action_sent = f"Register through exam portal via {reg_link}"
        elif "portal" in text.lower() and "exam" in text.lower():
            action_sent = "Register through exam portal"
        else:
            action_sent = "Complete required process as per notice"
        final_parts.append(f"Action: {action_sent}")
        
        # 5. Important
        note = props.get("Note")
        if note:
            final_parts.append(f"Important: {note}")
        elif "fees are paid" in text.lower() or "submit" in text.lower():
            final_parts.append("Important: Pay fees and submit form before deadline")
        else:
            final_parts.append("Important: Please read the full notice for details")
            
    else:
        # Standard Event Format
        if event_type:
            final_parts.append(f"Event: {event_type}")

        date_str = props.get("Date")
        if date_str:
            final_parts.append(f"Event Date: {date_str.replace(' ', '-')}")

        venue = props.get("Venue")
        if venue:
            final_parts.append(f"Venue: {venue}")

        eligibility = props.get("Eligibility")
        if eligibility:
            final_parts.append(f"Eligibility: {eligibility}")
            
        last_date = props.get("Last Date")
        if last_date:
            final_parts.append(f"Last Date: {last_date}")

        action_sent = ""
        reg_link = props.get("Register")
        note = props.get("Note")
        
        if reg_link:
            action_sent += f"Register at {reg_link}"
            if last_date:
                action_sent += f" before the deadline"
        elif last_date:
            action_sent += f"Register before the deadline"
        elif note:
            action_sent += f"Note: {note.lower()}"
        else:
            action_sent += "Please take necessary action"
            
        final_parts.append(f"Action: {action_sent}")
        
    return ' | '.join(final_parts)