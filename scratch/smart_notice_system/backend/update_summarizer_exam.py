import os

with open('summarizer.py', 'r', encoding='utf-8') as f:
    code = f.read()

old_block = """    if is_academic or not event_type:
        # Dynamic format for Exams, Fees, Registrations, or unknown
        # 1. Notice Title / Topic
        topic = event_type or props.get("Summary", text[:50])
        final_parts.append(f"Notice: {topic}")
        
        # 2. Last Date
        last_date = props.get("Last Date")
        if last_date:
            final_parts.append(f"Last Date: {last_date}")
            
        # 3. Action
        reg_link = props.get("Register")
        action_sent = ""
        if reg_link:
            action_sent = f"Complete registration via {reg_link}"
        else:
            action_sent = "Complete required process as per notice"
        if last_date:
            action_sent += " before the deadline"
        final_parts.append(f"Action: {action_sent}")
        
        # 4. Important
        note = props.get("Note")
        if note:
            final_parts.append(f"Important: {note}")
        else:
            final_parts.append(f"Important: Please read the full notice for details")"""

new_block = """    if is_academic or not event_type:
        # Dynamic format for Exams, Fees, Registrations, or unknown
        # 1. Notice Title / Topic
        import re
        topic_match = re.search(r'((?:Supplementary|End Semester|Mid Semester)?\\s*(?:Exam|Examination|Test)\\s*(?:Registration|Fee)?)(?:\\s|\\.|,)', text, re.IGNORECASE)
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
            final_parts.append("Important: Please read the full notice for details")"""

if old_block in code:
    code = code.replace(old_block, new_block)
else:
    print("WARNING: old_block not found.")
    
with open('summarizer.py', 'w', encoding='utf-8') as f:
    f.write(code)
print("Updated summarizer.py")
