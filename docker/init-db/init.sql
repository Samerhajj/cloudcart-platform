CREATE TABLE IF NOT EXISTS products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price NUMERIC(10, 2) NOT NULL,
    stock INTEGER NOT NULL DEFAULT 0
);

INSERT INTO products (name, description, price, stock) VALUES
    ('Wireless Mouse', 'Ergonomic wireless mouse with USB receiver.', 19.99, 42),
    ('Mechanical Keyboard', 'Compact 65% mechanical keyboard, hot-swappable switches.', 74.50, 15),
    ('USB-C Hub', '7-in-1 USB-C hub with HDMI, SD card, and 100W passthrough.', 29.99, 60),
    ('Laptop Stand', 'Adjustable aluminum laptop stand, foldable.', 34.00, 25)
ON CONFLICT DO NOTHING;
