from summarizer import generate_summary

text = """All students are hereby informed that the registration for the End Semester Examinations has begun. This registration is compulsory for all students who wish to appear for the examinations. Students must log in to the college portal and complete the registration process by selecting their subjects carefully.

The last date for exam registration is 30-04-2026. Students are advised to complete the registration well before the deadline, as late submissions will not be accepted.

Students must ensure that the required examination fees are paid and the form is successfully submitted. A confirmation receipt should be saved for future reference.

For any queries or issues, students may contact the Examination Cell."""

summary = generate_summary(text)
print("--- SUMMARY ---")
print(summary)
