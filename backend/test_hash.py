import sqlite3, bcrypt
conn = sqlite3.connect('smart_notice.db')
cur = conn.cursor()
cur.execute("SELECT hashed_password FROM users WHERE email='superadmin@sjec.ac.in'")
hashed = cur.fetchone()[0]
print("HASH:", hashed)
print("IS MATCH:", bcrypt.checkpw('password123'.encode('utf-8'), hashed.encode('utf-8')))
