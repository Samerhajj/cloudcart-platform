import os
import psycopg2

def get_connection():
    """Open and return a new connection to the Postgres database."""
    return psycopg2.connect(
        host=os.environ.get("DB_HOST", "localhost"),
        port=os.environ.get("DB_PORT", "5432"),
        dbname=os.environ.get("DB_NAME", "cloudcart"),
        user=os.environ.get("DB_USER", "cloudcart_user"),
        password=os.environ.get("DB_PASSWORD", ""),
    )