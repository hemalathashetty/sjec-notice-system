from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.orm import Session
from database import get_db
import models
from auth import require_role
import os
import re
from datetime import datetime, date
from dotenv import load_dotenv
import google.generativeai as genai

load_dotenv()

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
if GEMINI_API_KEY:
    genai.configure(api_key=GEMINI_API_KEY)

router = APIRouter(prefix="/chatbot", tags=["Chatbot"])


class ChatRequest(BaseModel):
    query: str


def _get_student_notices(db: Session, current_user: models.User):
    """Fetch all notices relevant to the logged-in student."""
    from sqlalchemy import or_
    conditions = [models.Notice.is_general == True]

    if current_user.department:
        conditions.append(models.Notice.department == current_user.department)
        conditions.append(
            models.Notice.target_departments.contains(current_user.department)
        )
    if current_user.year:
        conditions.append(models.Notice.year == current_user.year)
        conditions.append(
            models.Notice.target_years.contains(current_user.year)
        )

    notices = (
        db.query(models.Notice)
        .filter(or_(*conditions))
        .order_by(models.Notice.created_at.desc())
        .limit(50)
        .all()
    )
    return notices


def _days_until(due_date) -> int | None:
    """Return how many days until a due date (negative = already passed)."""
    if not due_date:
        return None
    try:
        if isinstance(due_date, datetime):
            delta = due_date.date() - date.today()
        else:
            delta = due_date - date.today()
        return delta.days
    except Exception:
        return None


def _build_rich_context(notices) -> str:
    """
    Build a rich, detailed context string from all notices.
    Passes full content so Gemini can answer accurately.
    """
    if not notices:
        return "No notices are currently available for this student."

    today_str = date.today().strftime("%d %B %Y")
    lines = [f"Today's date: {today_str}\n"]

    for i, n in enumerate(notices, 1):
        days = _days_until(n.due_date)
        deadline_label = ""
        if days is not None:
            if days < 0:
                deadline_label = f" ⚠️ DEADLINE PASSED ({abs(days)} days ago)"
            elif days == 0:
                deadline_label = " 🔴 DUE TODAY"
            elif days <= 3:
                deadline_label = f" 🟠 URGENT — due in {days} day(s)"
            elif days <= 7:
                deadline_label = f" 🟡 due in {days} day(s)"
            else:
                deadline_label = f" (due in {days} day(s))"

        section = [f"--- NOTICE {i} ---"]
        section.append(f"Title: {n.title}")
        if n.category:
            section.append(f"Category: {n.category.title()}")
        if n.department:
            section.append(f"Department: {n.department}")
        if n.due_date:
            due_str = str(n.due_date)[:10]
            section.append(f"Deadline/Due Date: {due_str}{deadline_label}")
        if n.created_at:
            section.append(f"Posted on: {str(n.created_at)[:10]}")

        # Prefer full content, fall back to summary
        content = (n.content or "").strip()
        summary = (n.summary or "").strip()

        if content and len(content) > 20:
            section.append(f"Full Content:\n{content}")
        elif summary:
            section.append(f"Summary: {summary}")

        lines.append("\n".join(section))

    return "\n\n".join(lines)


def _keyword_fallback(query: str, notices) -> str:
    """Rule-based fallback when Gemini API is unavailable."""
    query_lower = query.lower()
    today = date.today()

    # Deadline-specific query
    deadline_keywords = ['deadline', 'due', 'last date', 'expire', 'closing', 'submit by']
    if any(kw in query_lower for kw in deadline_keywords):
        with_deadlines = [(n, _days_until(n.due_date)) for n in notices if n.due_date]
        upcoming = sorted(
            [(n, d) for n, d in with_deadlines if d is not None and d >= 0],
            key=lambda x: x[1]
        )
        if not upcoming:
            return "There are no upcoming deadlines in your current notices."
        lines = ["📅 **Upcoming deadlines:**\n"]
        for n, days in upcoming[:5]:
            label = "Due today!" if days == 0 else f"in {days} day(s)"
            due_str = str(n.due_date)[:10]
            lines.append(f"• **{n.title}** — {due_str} ({label})")
        return "\n".join(lines)

    matched = []
    for n in notices:
        score = 0
        text = f"{n.title} {n.content or ''} {n.category or ''}".lower()
        for word in re.findall(r'\w+', query_lower):
            if len(word) > 2 and word in text:
                score += 1
        if score > 0:
            matched.append((score, n))

    matched.sort(key=lambda x: x[0], reverse=True)

    if not matched:
        return "I couldn't find any notices related to your question. Please try different keywords."

    lines = ["Here are the most relevant notices:\n"]
    for _, n in matched[:3]:
        line = f"• **{n.title}**"
        if n.due_date:
            days = _days_until(n.due_date)
            line += f" — Deadline: {str(n.due_date)[:10]}"
            if days is not None and days >= 0:
                line += f" (in {days} days)"
        if n.category:
            line += f" [{n.category.title()}]"
        content = (n.content or n.summary or "").strip()
        if content:
            line += f"\n  {content[:300]}"
        lines.append(line)

    return "\n".join(lines)


@router.post("/ask")
def ask_chatbot(
    request: ChatRequest,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(
        require_role(
            "student", "super_admin", "admin", "hod",
            "placement_cell", "club_coordinator", "sports_coordinator"
        )
    ),
):
    if not request.query or not request.query.strip():
        raise HTTPException(status_code=400, detail="Query cannot be empty.")

    notices = _get_student_notices(db, current_user)
    context = _build_rich_context(notices)

    if GEMINI_API_KEY:
        try:
            model = genai.GenerativeModel("gemini-1.5-flash")

            prompt = f"""You are an intelligent, friendly notice assistant for SJEC (St Joseph Engineering College).
You have been given the complete details of all notices currently posted for this student.

{context}

---

Student's question: {request.query}

Instructions:
1. Answer using ONLY the information from the notices above — do not make up facts.
2. If the student asks about a SPECIFIC notice (by name, topic, or keyword), find the best matching notice and describe its FULL details: what the notice is about, the date, venue, who it is for, what action is needed, etc.
3. If the student asks about DEADLINES or upcoming events, list them sorted by urgency (soonest first), and mention how many days are left.
4. If there are URGENT deadlines (≤ 3 days), highlight them clearly.
5. For GENERAL questions ("what notices are there?", "list all"), give a structured summary of all.
6. Use a natural, conversational tone — like a helpful college assistant.
7. Format your response clearly:
   - Use **bold** for notice titles and important dates.
   - Use bullet points for lists.
   - Keep it concise but complete — don't omit important details.
8. If the question has NO matching notice, say politely: "I don't have a notice about that right now."

Respond now:"""

            response = model.generate_content(prompt)
            answer = response.text.strip()
            return {
                "answer": answer,
                "source": "gemini",
                "notice_count": len(notices)
            }

        except Exception as e:
            # Fall through to keyword fallback
            pass

    # Fallback: keyword-based search
    answer = _keyword_fallback(request.query, notices)
    return {"answer": answer, "source": "fallback", "notice_count": len(notices)}
