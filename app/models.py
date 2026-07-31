from db import get_connection


def get_all_products():
    """Return all products from the database as a list of dicts."""
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT id, name, description, price, stock FROM products ORDER BY id;"
            )
            rows = cur.fetchall()
    finally:
        conn.close()

    products = []
    for row in rows:
        products.append({
            "id": row[0],
            "name": row[1],
            "description": row[2],
            "price": float(row[3]),
            "stock": row[4],
        })
    return products


def get_product_by_id(product_id):
    """Return a single product dict, or None if not found."""
    conn = get_connection()
    try:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT id, name, description, price, stock FROM products WHERE id = %s;",
                (product_id,)
            )
            row = cur.fetchone()
    finally:
        conn.close()

    if row is None:
        return None

    return {
        "id": row[0],
        "name": row[1],
        "description": row[2],
        "price": float(row[3]),
        "stock": row[4],
    }
