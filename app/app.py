from flask import Flask, render_template, redirect, url_for, session
from models import PRODUCTS, get_product_by_id

app = Flask(__name__)
app.secret_key = "dev-secret-key-change-in-production"

@app.route("/")
def health_check():
    return "CloudCart is running", 200

@app.route("/products")
def product_list():
    return render_template("products.html", products=PRODUCTS)

@app.route("/product/<int:product_id>")
def product_detail(product_id):
    product = get_product_by_id(product_id)
    if product is None:
        return "Product not found", 404
    return render_template("product_detail.html", product=product)

@app.route("/cart/add/<int:product_id>")
def add_to_cart(product_id):
    product = get_product_by_id(product_id)
    if product is None:
        return "Product not found", 404

    cart = session.get("cart", {})
    product_id_str = str(product_id)
    cart[product_id_str] = cart.get(product_id_str, 0) + 1
    session["cart"] = cart

    return redirect(url_for("view_cart"))

@app.route("/cart")
def view_cart():
    cart = session.get("cart", {})
    items = []
    total = 0.0

    for product_id_str, quantity in cart.items():
        product = get_product_by_id(int(product_id_str))
        if product:
            subtotal = product["price"] * quantity
            total += subtotal
            items.append({
                "product": product,
                "quantity": quantity,
                "subtotal": subtotal,
            })

    return render_template("cart.html", items=items, total=total)

@app.route("/checkout")
def checkout():
    session.pop("cart", None)
    return render_template("checkout.html")

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)