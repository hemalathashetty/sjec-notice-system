import re
from datetime import datetime
from typing import List, Optional, Dict

# ─── ATCD CONCEPT 1: LEXICAL ANALYSIS (TOKENIZER) ──────────
def tokenize(text: str) -> List[str]:
    """
    Breaks notice text into tokens
    Like a compiler's lexer breaking code into tokens
    Example: "AI Workshop on 25 March" -> ["AI", "Workshop", "on", "25", "March"]
    """
    tokens = re.findall(r'\b\w+\b', text.lower())
    return tokens

# ─── ATCD CONCEPT 2: PATTERN MATCHING (REGEX / DFA) ────────
# Date patterns using regex (simulates DFA state transitions)
DATE_PATTERNS = [
    # DD/MM/YYYY or DD-MM-YYYY
    r'\b(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{2,4})\b',
    # DD Month YYYY (e.g. 25 March 2025)
    r'\b(\d{1,2})\s+(January|February|March|April|May|June|July|August|September|October|November|December)\s+(\d{4})\b',
    # DD Mon YYYY (e.g. 25 Mar 2025)
    r'\b(\d{1,2})\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+(\d{4})\b',
    # Month DD, YYYY (e.g. March 25, 2025)
    r'\b(January|February|March|April|May|June|July|August|September|October|November|December)\s+(\d{1,2}),?\s+(\d{4})\b',
]

# Deadline keywords (DFA pattern matching)
DEADLINE_KEYWORDS = [
    'deadline', 'due date', 'last date', 'submit by',
    'submission', 'before', 'on or before', 'by'
]

# Event keywords
EVENT_KEYWORDS = [
    'workshop', 'seminar', 'exam', 'test', 'interview',
    'placement', 'internship', 'fest', 'event', 'meeting',
    'webinar', 'hackathon', 'competition', 'last date'
]

# ─── ATCD CONCEPT 3: DFA - DATE EXTRACTOR ──────────────────
def extract_dates(text: str) -> List[str]:
    """
    DFA Concept: State machine for date extraction
    States: Start -> Digit -> Separator -> Month -> Year -> Accept
    """
    found_dates = []
    for pattern in DATE_PATTERNS:
        matches = re.findall(pattern, text, re.IGNORECASE)
        for match in matches:
            date_str = ' '.join([m for m in match if m])
            if date_str and date_str not in found_dates:
                found_dates.append(date_str)
    return found_dates

# ─── ATCD CONCEPT 4: KEYWORD PARSER ────────────────────────
def extract_keywords(text: str) -> dict:
    """
    Parser concept: analyzes token relationships
    Extracts structured info from unstructured notice text
    """
    text_lower = text.lower()
    tokens = tokenize(text)

    # Find deadline mentions
    has_deadline = any(
        keyword in text_lower for keyword in DEADLINE_KEYWORDS
    )

    # Find event type
    event_type = None
    for keyword in EVENT_KEYWORDS:
        if keyword in text_lower:
            event_type = keyword
            break

    # Extract department mentions
    dept_codes = ['cse', 'csbs', 'csds', 'aiml', 'eee', 'ec', 'me', 'civil', 'mba', 'mca']
    mentioned_depts = [dept.upper() for dept in dept_codes if dept in tokens]

    # Extract year mentions
    year_mentions = []
    year_patterns = ['1st year', '2nd year', '3rd year', '4th year',
                     'first year', 'second year', 'third year', 'fourth year',
                     'ug1', 'ug2', 'ug3', 'ug4', 'pg1', 'pg2']
    for yr in year_patterns:
        if yr in text_lower:
            year_mentions.append(yr)

    return {
        "tokens": tokens,  # return all tokens
        "has_deadline": has_deadline,
        "event_type": event_type,
        "mentioned_departments": mentioned_depts,
        "mentioned_years": year_mentions,
    }

# ─── ATCD CONCEPT 5: DFA - DUE DATE EXTRACTOR ──────────────
def extract_due_date(text: str) -> Optional[str]:
    """
    DFA for finding the most relevant due date in a notice
    Looks for dates near deadline keywords
    """
    text_lower = text.lower()

    # Check if text has deadline keywords
    has_deadline_keyword = any(
        kw in text_lower for kw in DEADLINE_KEYWORDS
    )

    # Extract all dates
    dates = extract_dates(text)

    if dates:
        # If deadline keyword found, return first date as due date
        if has_deadline_keyword:
            return dates[0]
        # Otherwise return last date mentioned (usually the event date)
        return dates[-1]

    return None

# ─── ATCD CONCEPT 6: SMART AUTO-CATEGORIZER (FA CLASSIFIER) ─
# DFA: each category has its own accepting state triggered by token matches
CATEGORY_DFA = [
    ("placement",   ["placement", "drive", "recruitment", "recruit", "company",
                     "hiring", "campus", "interview", "offer", "hr", "package"]),
    ("exam",        ["exam", "test", "quiz", "assessment", "marks", "grade",
                     "paper", "internal", "external", "cia", "semester", "result"]),
    ("workshop",    ["workshop", "training", "hands-on", "handson", "lab",
                     "session", "practical", "skill", "bootcamp"]),
    ("hackathon",   ["hackathon", "hack", "competition", "contest", "challenge",
                     "coding", "ideathon", "techfest"]),
    ("scholarship", ["scholarship", "stipend", "merit", "award", "fellowship",
                     "financial", "assistance", "bursary", "fee waiver"]),
    ("sports",      ["sports", "tournament", "match", "ground", "court", "cricket",
                     "football", "basketball", "athletics", "game"]),
    ("club",        ["club", "association", "society", "committee",
                     "cultural", "fest", "dance", "music", "drama"]),
    ("webinar",     ["webinar", "online", "virtual", "zoom", "meet", "teams"]),
    ("general",     []),
]

def auto_categorize(text: str) -> str:
    """
    ATCD: DFA-based category classifier.
    Scans tokens against each category's accepting-token set.
    First match wins (ordered by priority).
    """
    text_lower = text.lower()
    tokens_set = set(tokenize(text))
    for category, keywords in CATEGORY_DFA:
        if category == "general":
            continue
        if any(kw in text_lower or kw in tokens_set for kw in keywords):
            return category
    return "general"


# ─── ATCD CONCEPT 7: TOKEN COLOR CLASSIFIER (SYMBOL TABLE) ──
# Token Classification: assigns each token a semantic class + hex color
TOKEN_CLASSES = [
    ("EVENT",    ["workshop", "seminar", "exam", "test", "interview", "placement",
                  "internship", "fest", "meeting", "webinar", "hackathon",
                  "competition", "training", "lecture", "sports", "tournament",
                  "drive", "recruitment", "session"], "#FF9800"),
    ("DEADLINE", ["deadline", "submission", "submit", "apply", "register",
                  "registration", "before", "last", "due", "close",
                  "closes", "closing", "open"], "#F44336"),
    ("VENUE",    ["hall", "auditorium", "audi", "lab", "room", "ground",
                  "center", "centre", "block", "building", "campus",
                  "classroom", "seminar"], "#4CAF50"),
    ("PERSON",   ["dr", "mr", "ms", "mrs", "prof", "coordinator",
                  "advisor", "hod", "principal", "dean"], "#00BCD4"),
    ("LINK",     ["http", "https", "www", "form", "link", "url",
                  "forms", "bit", "gle"], "#607D8B"),
]

def classify_tokens(text: str) -> List[Dict]:
    """
    ATCD Token Classification: assigns each token to a semantic class.
    Implements a Symbol Table lookup — core compiler design concept.
    Returns list of {token, class, color} dicts.
    """
    tokens = tokenize(text)
    dates = extract_dates(text)
    keywords_data = extract_keywords(text)

    date_tokens   = set()
    for d in dates:
        date_tokens.update(d.lower().split())

    dept_tokens = set(kw.lower() for kw in keywords_data["mentioned_departments"])
    year_tokens = set()
    for yr in keywords_data["mentioned_years"]:
        year_tokens.update(yr.lower().split())

    # Time pattern tokens
    time_matches = re.findall(
        r'\b(\d{1,2}[:.]\d{2}\s*(?:am|pm)?)\b', text, re.IGNORECASE
    )
    time_tokens = set(t.lower() for t in time_matches)

    classified = []
    seen = set()
    for token in tokens:  # classify all tokens
        if token in seen:
            continue
        seen.add(token)

        # Priority order: DATE > TIME > DEPT > YEAR > EVENT/DEADLINE/VENUE/PERSON/LINK > KEYWORD
        if token in date_tokens:
            classified.append({"token": token, "class": "DATE", "color": "#2196F3"})
        elif token in time_tokens:
            classified.append({"token": token, "class": "TIME", "color": "#9C27B0"})
        elif token in dept_tokens:
            classified.append({"token": token, "class": "DEPT", "color": "#795548"})
        elif token in year_tokens:
            classified.append({"token": token, "class": "YEAR", "color": "#7B1FA2"})
        else:
            matched_class = "KEYWORD"
            matched_color = "#9E9E9E"
            for cls_name, cls_keywords, cls_color in TOKEN_CLASSES:
                if token in cls_keywords:
                    matched_class = cls_name
                    matched_color = cls_color
                    break
            classified.append({"token": token, "class": matched_class, "color": matched_color})

    return classified


# ─── MAIN ATCD PROCESSOR ────────────────────────────────────
def process_notice_text(text: str) -> dict:
    """
    Full ATCD pipeline:
    1. Lexical Analysis -> tokenize
    2. Pattern Matching -> find dates, keywords
    3. Parsing -> extract structured data
    4. Auto-Category DFA -> classify notice type
    5. Token Classifier -> symbol table lookup
    """
    tokens = tokenize(text)
    dates = extract_dates(text)
    keywords = extract_keywords(text)
    due_date = extract_due_date(text)
    auto_cat = auto_categorize(text)
    classified = classify_tokens(text)

    return {
        "tokens": tokens,
        "dates_found": dates,
        "due_date": due_date,
        "has_deadline": keywords["has_deadline"],
        "event_type": keywords["event_type"],
        "mentioned_departments": keywords["mentioned_departments"],
        "mentioned_years": keywords["mentioned_years"],
        "word_count": len(tokens),
        "auto_category": auto_cat,
        "classified_tokens": classified,
    }