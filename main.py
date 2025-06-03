import os
from dotenv import load_dotenv
import mysql.connector
from flask import Flask, render_template, redirect, request
from sqids import Sqids

# load environment variables
load_dotenv()

app = Flask(__name__)

# Database configuration using environment variables for security
# This allows us to use our database credentials in a .env file instead of hardcoding them in our script.
# For docker, the host is set to 'mysql' which is the name of the MySQL container
# For local development, you can set it to 'localhost' or the appropriate host for your MySQL server.
db_config = {
    'host': os.getenv('MYSQL_HOST', 'mysql-service'),
    'user': os.getenv('MYSQL_USER', 'root'),
    'password': os.getenv('MYSQL_PASSWORD', 'had%CYM3#schcs'),
    'database': os.getenv('MYSQL_DATABASE', 'url_shortener'),
    'port': int(os.getenv('MYSQL_PORT', '3307')),  # Using environment variable for port
    'auth_plugin': 'mysql_native_password'
}

# Sqids is a library that generates short unique identifiers using alphanumeric values. So it basically is used to generate the short url code, which along with the localhost:5000 makes the short_url.

# initialize short_code with minimum length of 6
sqids = Sqids(min_length=6)

# function to connect to db
def get_db_connection():
    conn = mysql.connector.connect(**db_config)
    return conn

# '/' is the root url or the url/port/address on which the application runs
# 'GET' gets/loads the home application page
# 'POST' is for when the user enters the long url which then needs to be processed

@app.route("/", methods=["GET"])      
def index():
    return render_template("index.html")

@app.route("/shorten", methods=["POST"])
def shorten():
    long_url = request.form['long_url']

    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        # insert long url in the db
        cursor.execute('INSERT INTO redirections (long_url) VALUES (%s)', (long_url,))
        conn.commit()

        url_id = cursor.lastrowid

        # generate unique short code with minimum length of 6
        short_code = sqids.encode([url_id])

        # update Record with short code for that long_url
        cursor.execute('UPDATE redirections SET short_url = %s WHERE id = %s', (short_code, url_id))
        conn.commit()

        # Create full short URL
        short_url = request.host_url + short_code
        
        # Render results page with the short URL
        return render_template("result.html", short_url=short_url, long_url=long_url)
    
    finally:
        cursor.close()
        conn.close()

# goes to the shortened url ==> which is basically the localhost:5000/<short_url>  => has to be mapped to the original url for redirection
@app.route("/<short_code>")
def redirect_url(short_code):
    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        # Decode the short code - this returns a list
        decoded = sqids.decode(short_code)
        
        # Check if decoded is not empty
        if decoded:
            url_id = decoded[0]  # Take the first (and likely only) decoded ID
            cursor.execute('SELECT long_url FROM redirections WHERE id = %s', (url_id,))
            result = cursor.fetchone()

            if result:
                return redirect(result[0])

        return "URL not found", 404 
    
    finally:
        cursor.close()
        conn.close()
    
if __name__ == "__main__":
    app.run(debug=True)