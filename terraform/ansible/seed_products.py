#!/usr/bin/env python3
"""Seed sample categories and products through the product-service API.
Runs on the server. Does nothing if products already exist. Usage: seed_products.py [base_url]"""
import json
import sys
import urllib.request

BASE = sys.argv[1] if len(sys.argv) > 1 else "http://127.0.0.1:3002"


def call(method, path, body=None):
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(BASE + path, data=data, method=method,
                                 headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=20) as resp:
        return json.loads(resp.read().decode() or "null")


def img(seed):
    return [{"url": f"https://picsum.photos/seed/{seed}/600/400", "alt": seed}]


existing = call("GET", "/api/products")
if existing.get("total", 0) > 0:
    print("SKIPPED: catalogue already has products")
    sys.exit(0)

# --- categories (reuse any that already exist) -------------------------------
cat_ids = {}
current = call("GET", "/api/categories")
if isinstance(current, dict):
    current = current.get("categories", [])
for c in current or []:
    cat_ids[c["name"]] = c["_id"]

categories = [
    ("Electronics", "Phones, audio and gadgets"),
    ("Clothing", "Everyday wear and shoes"),
    ("Home & Kitchen", "Useful things for the home"),
]
for name, desc in categories:
    if name not in cat_ids:
        slug = "".join(ch if ch.isalnum() else "-" for ch in name.lower())
        res = call("POST", "/api/categories",
                   {"name": name, "description": desc, "slug": slug})
        cat_ids[name] = res["category"]["_id"]

# --- products -----------------------------------------------------------------
products = [
    ("Wireless Headphones", "Over-ear Bluetooth headphones with 30h battery", 4999, "Electronics", "SoundWave", "EL-HP-001", 40, True),
    ("Smart Watch", "Fitness tracker with heart-rate monitor", 7999, "Electronics", "FitTime", "EL-SW-002", 25, True),
    ("Bluetooth Speaker", "Portable waterproof speaker", 2499, "Electronics", "SoundWave", "EL-SP-003", 60, False),
    ("Cotton T-Shirt", "Soft 100% cotton crew-neck tee", 599, "Clothing", "UrbanWear", "CL-TS-001", 120, False),
    ("Running Shoes", "Lightweight shoes with breathable mesh", 3499, "Clothing", "StrideX", "CL-RS-002", 50, True),
    ("Denim Jacket", "Classic fit denim jacket", 2799, "Clothing", "UrbanWear", "CL-DJ-003", 30, False),
    ("Non-stick Pan", "28 cm non-stick frying pan", 1299, "Home & Kitchen", "CookPro", "HK-NP-001", 70, False),
    ("Electric Kettle", "1.5 L stainless steel kettle", 1599, "Home & Kitchen", "CookPro", "HK-EK-002", 45, True),
]
for name, desc, price, cat, brand, sku, stock, featured in products:
    call("POST", "/api/products", {
        "name": name, "description": desc, "price": price,
        "category": cat_ids[cat], "brand": brand,
        "images": img(sku.lower()),
        "inventory": {"stock": stock, "sku": sku},
        "tags": [cat.lower(), brand.lower()],
        "featured": featured,
    })

print(f"SEEDED: {len(categories)} categories, {len(products)} products")
