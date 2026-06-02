# Glovo Delivery Integration - Backend API Documentation

## Overview
This document describes the Laravel backend API endpoints and data structures for Glovo delivery integration in the Flutter POS application.

---

## Database Schema Changes

### New Columns Added

#### `orders` table
| Column | Type | Default | Description |
|--------|------|---------|-------------|
| `is_glovo_delivery` | BOOLEAN | FALSE | Flag to identify Glovo delivery orders |

#### `order_details` table
| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `price_type` | VARCHAR(50) | YES | Price type used: 'glovo', 'restaurant', 'retail', etc. |

#### `product_prices` table (already exists)
| Column | Type | Description |
|--------|------|-------------|
| `id` | BIGINT | Primary key |
| `product_id` | BIGINT | Foreign key to products |
| `type` | VARCHAR | Price type: 'glovo', 'restaurant', 'retail', 'wholesale', etc. |
| `price` | DECIMAL(10,2) | Price value |

---

## API Endpoints

### 1. GET /api/products

Returns all products with their multiple price types.

**Authentication:** Not required (public)

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "Burger Classic",
      "description": "Delicious burger with cheese",
      "price": 10.00,
      "image": "http://example.com/images/burger.jpg",
      "is_available": true,
      "category": {
        "id": 1,
        "name": "Burgers"
      },
      "prices": [
        {
          "id": 1,
          "product_id": 1,
          "type": "retail",
          "price": 10.00
        },
        {
          "id": 2,
          "product_id": 1,
          "type": "restaurant",
          "price": 12.00
        },
        {
          "id": 3,
          "product_id": 1,
          "type": "glovo",
          "price": 15.00
        }
      ]
    }
  ]
}
```

---

### 2. POST /api/orders

Creates a new order with support for Glovo delivery pricing.

**Authentication:** Required (Bearer Token via Laravel Sanctum)

**Request Body:**
```json
{
  "user_id": 5,
  "restaurant_id": 1,
  "channel": "pos",
  "fulfillment_type": "delivery",
  "is_glovo_delivery": true,
  "status": "pending",
  "total_price": 38.00,
  "payment_method": "cod",
  "payment_status": "pending",
  "customer_name": "John Doe",
  "customer_phone": "+212600000000",
  "delivery_address": "123 Rue Mohammed V, Casablanca",
  "table_number": null,
  "note": "Sans oignons",
  "items": [
    {
      "product_id": 1,
      "quantity": 2,
      "unit_price": 15.00,
      "price_type": "glovo"
    },
    {
      "product_id": 2,
      "quantity": 1,
      "unit_price": 8.00,
      "price_type": null
    }
  ]
}
```

**Request Fields:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `channel` | STRING | YES | 'pos', 'web', 'api', 'kiosk' |
| `fulfillment_type` | STRING | YES | 'delivery', 'pickup', 'on_site', 'kiosk' |
| `is_glovo_delivery` | BOOLEAN | NO | true if Glovo delivery (uses glovo prices) |
| `total_price` | DECIMAL | YES | Order total |
| `items` | ARRAY | YES | Order items |
| `items[].product_id` | INTEGER | YES | Product ID |
| `items[].quantity` | INTEGER | YES | Quantity |
| `items[].unit_price` | DECIMAL | YES | Unit price (glovo price if applicable) |
| `items[].price_type` | STRING | NO | 'glovo', 'restaurant', 'retail', or null |

**Response (Success - 201):**
```json
{
  "success": true,
  "message": "Commande créée avec succès",
  "order": {
    "id": 123,
    "user_id": 5,
    "restaurant_id": 1,
    "channel": "pos",
    "fulfillment_type": "delivery",
    "is_glovo_delivery": true,
    "status": "pending",
    "total_price": 38.00,
    "created_at": "2026-03-24T10:30:00.000000Z",
    "order_details": [
      {
        "id": 1,
        "order_id": 123,
        "product_id": 1,
        "quantity": 2,
        "unit_price": 15.00,
        "price_type": "glovo",
        "total_price": 30.00,
        "product": {
          "id": 1,
          "name": "Burger Classic"
        }
      }
    ]
  }
}
```

**Response (Error - 401/422/500):**
```json
{
  "success": false,
  "message": "Error message here",
  "errors": {
    "field": ["Validation error"]
  }
}
```

---

### 3. GET /api/orders

Retrieve orders with optional filters.

**Authentication:** Required

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| `restaurant_id` | INTEGER | Filter by restaurant |
| `channel` | STRING | Filter by channel: 'pos', 'web', 'api' |
| `fulfillment_type` | STRING | Filter: 'delivery', 'pickup', 'on_site' |
| `status` | STRING | Filter: 'pending', 'confirmed', 'preparing', etc. |
| `is_glovo_delivery` | BOOLEAN | Filter Glovo orders only |
| `per_page` | INTEGER | Pagination (max 200) |
| `order_by` | STRING | Sort field: 'id', 'created_at' |
| `sort` | STRING | Sort direction: 'asc', 'desc' or '-created_at' |

**Response:**
```json
{
  "success": true,
  "orders": [
    {
      "id": 123,
      "fulfillment_type": "delivery",
      "is_glovo_delivery": true,
      "total_price": 38.00,
      "status": "pending",
      "order_details": [
        {
          "product_id": 1,
          "quantity": 2,
          "unit_price": 15.00,
          "price_type": "glovo"
        }
      ]
    }
  ]
}
```

---

### 4. GET /api/orders/{id}

Get single order details.

**Authentication:** Required

**Response:**
```json
{
  "success": true,
  "order": {
    "id": 123,
    "fulfillment_type": "delivery",
    "is_glovo_delivery": true,
    "total_price": 38.00,
    "order_details": [
      {
        "product_id": 1,
        "quantity": 2,
        "unit_price": 15.00,
        "price_type": "glovo",
        "product": {
          "id": 1,
          "name": "Burger Classic"
        }
      }
    ]
  }
}
```

---

### 5. POST /api/products/{product}/prices

Add a new price type to a product.

**Authentication:** Required (Sanctum)

**Request:**
```json
{
  "type": "glovo",
  "price": 15.00
}
```

**Response:**
```json
{
  "success": true,
  "message": "Price added successfully",
  "data": {
    "id": 3,
    "product_id": 1,
    "type": "glovo",
    "price": 15.00
  }
}
```

---

### 6. PUT /api/prices/{id}

Update an existing product price.

**Authentication:** Required

**Request:**
```json
{
  "type": "glovo",
  "price": 16.00
}
```

---

### 7. DELETE /api/prices/{id}

Delete a product price.

**Authentication:** Required

---

## Eloquent Models

### Product Model
```php
// app/Models/Product.php

class Product extends Model
{
    // Relationships
    public function category() {
        return $this->belongsTo(Category::class);
    }
    
    public function prices() {
        return $this->hasMany(ProductPrice::class);
    }
}
```

### ProductPrice Model
```php
// app/Models/ProductPrice.php

class ProductPrice extends Model
{
    protected $fillable = ['product_id', 'type', 'price'];
    
    public function product() {
        return $this->belongsTo(Product::class);
    }
}
```

### Order Model
```php
// app/Models/Order.php

class Order extends Model
{
    protected $fillable = [
        'user_id',
        'restaurant_id',
        'channel',
        'fulfillment_type',
        'is_glovo_delivery',  // NEW
        'status',
        'total_price',
        // ...
    ];
    
    protected $casts = [
        'is_glovo_delivery' => 'boolean',
        'total_price' => 'decimal:2',
    ];
    
    public function orderDetails() {
        return $this->hasMany(OrderDetail::class);
    }
}
```

### OrderDetail Model
```php
// app/Models/OrderDetail.php

class OrderDetail extends Model
{
    protected $fillable = [
        'order_id',
        'product_id',
        'quantity',
        'unit_price',
        'price_type',  // NEW
        'total_price',
    ];
    
    public function order() {
        return $this->belongsTo(Order::class);
    }
    
    public function product() {
        return $this->belongsTo(Product::class);
    }
}
```

---

## Workflow: Creating a Glovo Delivery Order

### Step 1: Fetch Products with Prices
```dart
// Flutter: Get products
final response = await api.get('/api/products');
final products = response.data['data'];

// Each product has:
// - product.price (base price)
// - product.prices[] (multiple price types)
```

### Step 2: Select Delivery Type
```dart
// User selects "Glovo Delivery"
// Set flag: isGlovoDelivery = true
```

### Step 3: Add to Cart with Glovo Price
```dart
// Find glovo price for product
final glovoPrice = product.prices.firstWhere(
  (p) => p.type == 'glovo',
  orElse: () => ProductPrice(price: product.price),
);

// Add to cart with glovo price
cart.addItem(product, price: glovoPrice.price, priceType: 'glovo');
```

### Step 4: Create Order
```dart
final orderPayload = {
  'channel': 'pos',
  'fulfillment_type': 'delivery',
  'is_glovo_delivery': true,  // ← IMPORTANT
  'items': cart.items.map((item) => {
    'product_id': item.product.id,
    'quantity': item.quantity,
    'unit_price': item.price,  // Glovo price
    'price_type': 'glovo',     // ← IMPORTANT
  }).toList(),
  'total_price': cart.total,
};

final response = await api.post('/api/orders', orderPayload);
```

---

## Reporting Queries (SQL)

### Get all Glovo orders
```sql
SELECT * FROM orders WHERE is_glovo_delivery = TRUE;
```

### Get Glovo revenue for a period
```sql
SELECT 
    DATE(created_at) as date,
    COUNT(*) as order_count,
    SUM(total_price) as total_revenue
FROM orders 
WHERE is_glovo_delivery = TRUE 
  AND created_at BETWEEN '2026-03-01' AND '2026-03-31'
GROUP BY DATE(created_at);
```

### Get items sold with Glovo pricing
```sql
SELECT 
    p.name,
    od.price_type,
    SUM(od.quantity) as total_qty,
    SUM(od.total_price) as total_amount
FROM order_details od
JOIN products p ON od.product_id = p.id
JOIN orders o ON od.order_id = o.id
WHERE o.is_glovo_delivery = TRUE
GROUP BY p.name, od.price_type;
```

---

## Error Handling

### Validation Errors (422)
```json
{
  "success": false,
  "message": "The given data was invalid.",
  "errors": {
    "fulfillment_type": ["The fulfillment type field is required."],
    "items": ["The items field must contain at least 1 item."],
    "items.0.product_id": ["The selected product id is invalid."]
  }
}
```

### Authentication Error (401)
```json
{
  "success": false,
  "message": "Unauthenticated."
}
```

### Server Error (500)
```json
{
  "success": false,
  "message": "Erreur lors de la création de la commande",
  "error": "Detailed error message"
}
```

---

## Testing with cURL

### Test: Create Glovo Order
```bash
curl -X POST http://your-api.com/api/orders \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "channel": "pos",
    "fulfillment_type": "delivery",
    "is_glovo_delivery": true,
    "total_price": 30.00,
    "items": [
      {
        "product_id": 1,
        "quantity": 2,
        "unit_price": 15.00,
        "price_type": "glovo"
      }
    ]
  }'
```

### Test: Get Products
```bash
curl -X GET http://your-api.com/api/products
```

---

## Summary

| Feature | Status |
|---------|--------|
| Product multiple prices | ✅ Implemented |
| Glovo price type support | ✅ Implemented |
| Order glovo_delivery flag | ✅ Implemented |
| Order detail price_type | ✅ Implemented |
| API: GET products with prices | ✅ Available |
| API: POST order with price_type | ✅ Available |
| Database migrations | ✅ Executed |
| Eloquent relationships | ✅ Configured |

---

## Contact

For questions or issues, refer to the Laravel backend codebase:
- Models: `app/Models/`
- Controllers: `app/Http/Controllers/Api/`
- Routes: `routes/api.php`
- Migrations: `database/migrations/`
