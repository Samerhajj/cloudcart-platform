# In-memory product catalog for CloudCart.
# No database yet — this is intentional for Phase 3.
# Postgres will replace this structure in Phase 6 (Docker Compose).

PRODUCTS = [
    {
        "id": 1,
        "name": "Wireless Mouse",
        "description": "Ergonomic wireless mouse with USB receiver.",
        "price": 19.99,
        "stock": 42,
    },
    {
        "id": 2,
        "name": "Mechanical Keyboard",
        "description": "Compact 65% mechanical keyboard, hot-swappable switches.",
        "price": 74.50,
        "stock": 15,
    },
    {
        "id": 3,
        "name": "USB-C Hub",
        "description": "7-in-1 USB-C hub with HDMI, SD card, and 100W passthrough.",
        "price": 29.99,
        "stock": 60,
    },
    {
        "id": 4,
        "name": "Laptop Stand",
        "description": "Adjustable aluminum laptop stand, foldable.",
        "price": 34.00,
        "stock": 25,
    },
]


def get_product_by_id(product_id):
    """Return a single product dict, or None if not found."""
    for product in PRODUCTS:
        if product["id"] == product_id:
            return product
    return None