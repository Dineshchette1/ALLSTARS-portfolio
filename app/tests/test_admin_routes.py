import pytest

def test_create_category(client):
    response = client.post("/categories/", json={"name": "Electronics", "image": "electronics.png"})
    assert response.status_code == 200
    data = response.json()
    assert data["name"] == "Electronics"
    assert data["image"] == "electronics.png"
    assert "id" in data

def test_read_categories(client):
    response = client.get("/categories/")
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)
    assert any(cat["name"] == "Electronics" for cat in data)

def test_update_category(client):
    # First, create a category
    create_resp = client.post("/categories/", json={"name": "Books", "image": "books.png"})
    category_id = create_resp.json()["id"]
    # Update
    response = client.put(f"/categories/{category_id}", json={"name": "Books Updated", "image": "books_updated.png"})
    assert response.status_code == 200
    data = response.json()
    assert data["name"] == "Books Updated"

def test_delete_category(client):
    create_resp = client.post("/categories/", json={"name": "Toys", "image": "toys.png"})
    category_id = create_resp.json()["id"]
    response = client.delete(f"/categories/{category_id}")
    assert response.status_code == 204
    # Verify deletion
    get_resp = client.get(f"/categories/{category_id}")
    assert get_resp.status_code == 404

def test_create_subcategory(client):
    # Ensure category exists
    cat_resp = client.post("/categories/", json={"name": "Clothing", "image": "clothing.png"})
    category_id = cat_resp.json()["id"]
    response = client.post("/subcategories/", json={
        "name": "Men", "image": "men.png", "category_id": category_id
    })
    assert response.status_code == 200
    data = response.json()
    assert data["name"] == "Men"
    assert data["category_id"] == category_id

def test_read_subcategories(client):
    response = client.get("/subcategories/")
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)

def test_update_subcategory(client):
    cat_resp = client.post("/categories/", json={"name": "Accessories", "image": "acc.png"})
    category_id = cat_resp.json()["id"]
    subcat_resp = client.post("/subcategories/", json={"name": "Watches", "image": "watch.png", "category_id": category_id})
    subcat_id = subcat_resp.json()["id"]
    response = client.put(f"/subcategories/{subcat_id}", json={"name": "Watches Updated", "image": "watch_updated.png", "category_id": category_id})
    assert response.status_code == 200
    data = response.json()
    assert data["name"] == "Watches Updated"

def test_delete_subcategory(client):
    cat_resp = client.post("/categories/", json={"name": "Footwear", "image": "footwear.png"})
    category_id = cat_resp.json()["id"]
    subcat_resp = client.post("/subcategories/", json={"name": "Sneakers", "image": "sneakers.png", "category_id": category_id})
    subcat_id = subcat_resp.json()["id"]
    response = client.delete(f"/subcategories/{subcat_id}")
    assert response.status_code == 204
    get_resp = client.get(f"/subcategories/{subcat_id}")
    assert get_resp.status_code == 404

def test_create_product(client):
    cat_resp = client.post("/categories/", json={"name": "Gadgets", "image": "gadgets.png"})
    category_id = cat_resp.json()["id"]
    subcat_resp = client.post("/subcategories/", json={"name": "Smartphones", "image": "smartphones.png", "category_id": category_id})
    subcat_id = subcat_resp.json()["id"]
    response = client.post("/products/", json={
        "name": "iPhone 13",
        "image": "iphone13.png",
        "category_id": category_id,
        "subcategory_id": subcat_id,
        "price": 999.99,
        "discount": 50.0,
        "final_price": 949.99
    })
    assert response.status_code == 200
    data = response.json()
    assert data["name"] == "iPhone 13"
    assert data["category_id"] == category_id
    assert data["subcategory_id"] == subcat_id

def test_read_products(client):
    response = client.get("/products/")
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)

def test_update_product(client):
    cat_resp = client.post("/categories/", json={"name": "Books", "image": "books.png"})
    category_id = cat_resp.json()["id"]
    subcat_resp = client.post("/subcategories/", json={"name": "Fiction", "image": "fiction.png", "category_id": category_id})
    subcat_id = subcat_resp.json()["id"]
    prod_resp = client.post("/products/", json={
        "name": "The Hobbit",
        "image": "hobbit.png",
        "category_id": category_id,
        "subcategory_id": subcat_id,
        "price": 15.0,
        "discount": 2.0,
        "final_price": 13.0
    })
    product_id = prod_resp.json()["id"]
    response = client.put(f"/products/{product_id}", json={
        "name": "The Hobbit Updated",
        "image": "hobbit_updated.png",
        "category_id": category_id,
        "subcategory_id": subcat_id,
        "price": 17.0,
        "discount": 1.0,
        "final_price": 16.0
    })
    assert response.status_code == 200
    data = response.json()
    assert data["name"] == "The Hobbit Updated"

def test_delete_product(client):
    cat_resp = client.post("/categories/", json={"name": "Stationery", "image": "stationery.png"})
    category_id = cat_resp.json()["id"]
    subcat_resp = client.post("/subcategories/", json={"name": "Pens", "image": "pens.png", "category_id": category_id})
    subcat_id = subcat_resp.json()["id"]
    prod_resp = client.post("/products/", json={
        "name": "Ballpoint Pen",
        "image": "pen.png",
        "category_id": category_id,
        "subcategory_id": subcat_id,
        "price": 1.5,
        "discount": 0.0,
        "final_price": 1.5
    })
    product_id = prod_resp.json()["id"]
    response = client.delete(f"/products/{product_id}")
    assert response.status_code == 204
    get_resp = client.get(f"/products/{product_id}")
    assert get_resp.status_code == 404
