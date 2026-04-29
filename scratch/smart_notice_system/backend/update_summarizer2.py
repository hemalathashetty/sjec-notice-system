import os
import re

with open('summarizer.py', 'r', encoding='utf-8') as f:
    code = f.read()

# Let's replace the _generate_summary_fallback logic at the end where final_parts are built.
# We will match the block starting with "final_parts = []" until the end.

old_block = """    final_parts = []
    
    # 1. Event
    event_type = props.get("Event")
    if event_type:
        final_parts.append(f"Event: {event_type}")

    # 2. Event Date
    date_str = props.get("Date")
    if date_str:
        final_parts.append(f"Event Date: {date_str.replace(' ', '-')}")

    # 3. Venue
    venue = props.get("Venue")
    if venue:
        final_parts.append(f"Venue: {venue}")

    # 4. Eligibility
    eligibility = props.get("Eligibility")
    if eligibility:
        final_parts.append(f"Eligibility: {eligibility}")
        
    # 5. Last Date
    last_date = props.get("Last Date")
    if last_date:
        final_parts.append(f"Last Date: {last_date}")

    # 6. Action
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
        
    return ' | '.join(final_parts)"""

new_block = """    final_parts = []
    event_type = props.get("Event")
    
    # Check if it's a standard event or something else
    is_academic = event_type and any(k in event_type.lower() for k in ['exam', 'registration', 'fee', 'scholarship', 'internship', 'placement'])
    
    if is_academic or not event_type:
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
            final_parts.append(f"Important: Please read the full notice for details")
            
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
        
    return ' | '.join(final_parts)"""

if old_block in code:
    code = code.replace(old_block, new_block)
else:
    print("Warning: old_block not found perfectly.")
    
with open('summarizer.py', 'w', encoding='utf-8') as f:
    f.write(code)
print("Updated summarizer.py")
