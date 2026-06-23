<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="com.mycompany.mavenproject2.DBConnection" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>LuxeGlow | Premium Luxury Beauty</title>
    <!-- Core Luxury Styling -->
    <link rel="stylesheet" href="index.css">
    <!-- FontAwesome Icons -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
</head>
<body>
<!-- Dynamic Glassmorphic Navbar -->
    <%@ include file="navbar.jsp" %>
    <%
        // Fetch user wishlist IDs to highlight liked items
        java.util.Set<Integer> wishlistedIds = new java.util.HashSet<>();
        if (navUserId != null) {
            Connection conWish = null;
            PreparedStatement psWish = null;
            ResultSet rsWish = null;
            try {
                conWish = DBConnection.getConnection();
                psWish = conWish.prepareStatement("SELECT product_id FROM wishlist WHERE user_id = ?");
                psWish.setInt(1, navUserId);
                rsWish = psWish.executeQuery();
                while (rsWish.next()) {
                    wishlistedIds.add(rsWish.getInt("product_id"));
                }
            } catch (Exception e) {
                e.printStackTrace();
            } finally {
                if (rsWish != null) try { rsWish.close(); } catch (Exception e) {}
                if (psWish != null) try { psWish.close(); } catch (Exception e) {}
                if (conWish != null) try { conWish.close(); } catch (Exception e) {}
            }
        } else {
            Object rawWish = session.getAttribute("guest_wishlist");
            if (rawWish instanceof java.util.Set) {
                for (Object idObj : (java.util.Set<?>) rawWish) {
                    if (idObj instanceof Number) {
                        wishlistedIds.add(((Number) idObj).intValue());
                    } else {
                        try {
                            wishlistedIds.add(Integer.parseInt(idObj.toString()));
                        } catch (Exception e) {}
                    }
                }
            }
        }
    %>

    <!-- Hero Banner -->
    <%
        String customHeroImage = "image/bc2.jpg"; // Default fallback
        try {
            String configPath = application.getRealPath("/WEB-INF/hero_config.txt");
            if (configPath != null) {
                java.io.File cf = new java.io.File(configPath);
                if (cf.exists()) {
                    try (java.io.BufferedReader br = new java.io.BufferedReader(new java.io.FileReader(cf))) {
                        String line = br.readLine();
                        if (line != null && !line.trim().isEmpty()) {
                            customHeroImage = line.trim();
                        }
                    }
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    %>
    <section class="hero" style="background: linear-gradient(rgba(250, 248, 245, 0.82), rgba(250, 248, 245, 0.88)), url('<%= customHeroImage %>') no-repeat center center/cover;">
        <div class="hero-content">
            <h1>Glow Like Never Before</h1>
            <p>Indulge in our dermatologist-tested, cruelty-free cosmetic formulations designed to make you feel radiant, confident, and beautiful every single day.</p>
            <a href="product.jsp" class="btn-gold">Explore The Collection</a>
        </div>
    </section>

    <!-- Promotional Section -->
    <section class="offers-section">
        <h2>Exclusive Offers</h2>
        <div class="offers-container">
            <a href="offers.jsp" class="offer-card bundle-deal">
                <div class="offer-overlay">
                    <span class="badge">Best Value</span>
                    <h3>The Glow Bundle</h3>
                    <p>Buy 1 Get 1 50% Off on all skincare sets.</p>
                    <span class="shop-offer-link">Claim Offer &rarr;</span>
                </div>
            </a>

            <a href="offers.jsp" class="offer-card seasonal-sale">
                <div class="offer-overlay">
                    <span class="badge">30% OFF</span>
                    <h3>Summer Clearance</h3>
                    <p>Take up to 30% off selected luxury lipsticks and cosmetics.</p>
                    <span class="shop-offer-link">Shop Sale &rarr;</span>
                </div>
            </a>

            <a href="offers.jsp" class="offer-card gift-deal">
                <div class="offer-overlay">
                    <span class="badge">Free Gift</span>
                    <h3>Deluxe Minis</h3>
                    <p>Receive a free luxury travel serum with any purchase over $60.</p>
                    <span class="shop-offer-link">View Details &rarr;</span>
                </div>
            </a>
        </div>
    </section>

    <!-- Categories Section -->
    <section class="categories-section">
        <h2>Shop By Category</h2>
        <div class="category-grid" style="display: grid; grid-template-columns: repeat(auto-fit, minmax(130px, 1fr)); gap: 20px; margin-top: 30px;">
            <%
                Connection conCat = null;
                Statement stCat = null;
                ResultSet rsCat = null;
                try {
                    conCat = DBConnection.getConnection();
                    stCat = conCat.createStatement();
                    rsCat = stCat.executeQuery("SELECT name FROM categories ORDER BY name ASC");
                    while (rsCat.next()) {
                        String catName = rsCat.getString("name");
                        String iconClass = "fa-gem"; // default
                        if ("Skincare".equalsIgnoreCase(catName)) iconClass = "fa-spa";
                        else if ("Makeup".equalsIgnoreCase(catName)) iconClass = "fa-wand-magic-sparkles";
                        else if ("Haircare".equalsIgnoreCase(catName)) iconClass = "fa-wind";
                        else if ("Bodycare".equalsIgnoreCase(catName)) iconClass = "fa-soap";
                        else if ("Fragrances".equalsIgnoreCase(catName)) iconClass = "fa-spray-can";
                        else if ("Accessories".equalsIgnoreCase(catName)) iconClass = "fa-paint-brush";
            %>
            <div class="category-card" onclick="location.href='product.jsp?category=<%= java.net.URLEncoder.encode(catName, "UTF-8") %>'">
                <i class="fas <%= iconClass %>" style="display:block; font-size:1.5rem; margin-bottom:10px; color:var(--gold);"></i>
                <%= catName %>
            </div>
            <%
                    }
                } catch (Exception e) {
                    out.println("<p style='color:var(--danger);'>Failed to load categories: " + e.getMessage() + "</p>");
                } finally {
                    if (rsCat != null) try { rsCat.close(); } catch (Exception e) {}
                    if (stCat != null) try { stCat.close(); } catch (Exception e) {}
                    if (conCat != null) try { conCat.close(); } catch (Exception e) {}
                }
            %>
        </div>
    </section>


    <!-- Dynamic Featured Products Section -->
    <section class="products-section">
        <h2>Featured Masterpieces</h2>
        <div class="products-grid">
            <%
                Connection con = null;
                PreparedStatement ps = null;
                ResultSet rs = null;
                int count = 0;
                try {
                    con = DBConnection.getConnection();
                    // Fetch top 4 featured products (ACTIVE only)
                    String sql = "SELECT id, name, description, price, category, rating FROM products WHERE status = 'ACTIVE' LIMIT 4";
                    ps = con.prepareStatement(sql);
                    rs = ps.executeQuery();
                    while (rs.next()) {
                        count++;
                        int id = rs.getInt("id");
                        String name = rs.getString("name");
                        double price = rs.getDouble("price");
                        String category = rs.getString("category");
                        String imageUrl = com.mycompany.mavenproject2.ProductImageHelper.getProductImage(id);
                        int rating = rs.getInt("rating");
            %>
            <div class="card">
                <div class="card-image-wrapper">
                    <button class="wishlist-heart-btn <%= wishlistedIds.contains(id) ? "liked" : "" %>" 
                            data-product-id="<%= id %>" 
                            onclick="toggleWishlist(event, <%= id %>)" 
                            title="<%= wishlistedIds.contains(id) ? "Remove from Wishlist" : "Add to Wishlist" %>">
                        <i class="<%= wishlistedIds.contains(id) ? "fas" : "far" %> fa-heart"></i>
                    </button>
                    <a href="product-details.jsp?id=<%= id %>">
                        <img src="<%= imageUrl %>" alt="<%= name %>">
                    </a>
                </div>
                <div class="card-content">
                    <div class="card-category"><%= category %></div>
                    <a href="product-details.jsp?id=<%= id %>">
                        <h3><%= name %></h3>
                    </a>
                    <div class="card-rating">
                        <% for (int i = 0; i < 5; i++) { %>
                            <i class="<%= (i < rating) ? "fas" : "far" %> fa-star"></i>
                        <% } %>
                    </div>
                    <div class="card-footer">
                        <div class="price"><%= com.mycompany.mavenproject2.CurrencyHelper.formatPrice(price, currentCountry) %></div>
                        <button class="add-to-cart-btn" onclick="ajaxAddToCart(<%= id %>)" title="Add to Cart">
                            <i class="fas fa-shopping-bag"></i>
                        </button>
                    </div>
                </div>
            </div>
            <%
                    }
                } catch (Exception e) {
                    out.println("<p style='color:var(--danger); grid-column: 1/-1;'>Failed to load featured products: " + e.getMessage() + "</p>");
                } finally {
                    if (rs != null) rs.close();
                    if (ps != null) ps.close();
                    if (con != null) con.close();
                }
                
                if (count == 0) {
                    out.println("<p style='color:var(--text-secondary); grid-column: 1/-1;'>No products available yet. Import luxeglow.sql to initialize database catalog.</p>");
                }
            %>
        </div>
    </section>

    <!-- Why Choose Us Features Section -->
    <section class="features">
        <h2>Why Choose LuxeGlow?</h2>
        <div class="features-container">
            <div class="feature">
                <i class="fas fa-leaf"></i>
                <h3>Natural Ingredients</h3>
                <p>Made with skin-loving, premium botanical extracts and organic ingredients.</p>
            </div>
            <div class="feature">
                <i class="fas fa-paw"></i>
                <h3>Cruelty Free</h3>
                <p>100% certified vegan and never tested on animals.</p>
            </div>
            <div class="feature">
                <i class="fas fa-check-double"></i>
                <h3>Premium Quality</h3>
                <p>Dermatologist-tested luxury formulations made for every skin type.</p>
            </div>
        </div>
    </section>

    <!-- Curated Collection Links -->
    <section class="offers-section" style="padding: 60px 8%; background: #FFFFFF; border-top: 1px solid var(--border-light);">
        <h2>Curated Masterpieces</h2>
        <div class="offers-container" style="margin-top: 40px;">
            <a href="new-arrivals.jsp" class="offer-card" style="height: 200px; background: linear-gradient(rgba(0,0,0,0.05), rgba(92, 13, 30, 0.85)), url('image/silkfoundation.jpg') no-repeat center center/cover;">
                <div class="offer-overlay" style="padding: 25px;">
                    <span class="badge">Fresh Selections</span>
                    <h3 style="font-size: 1.4rem;">New Arrivals</h3>
                    <p style="font-size: 0.85rem; margin-bottom: 0;">Be the first to experience our latest clinical formulas &rarr;</p>
                </div>
            </a>

            <a href="best-sellers.jsp" class="offer-card" style="height: 200px; background: linear-gradient(rgba(0,0,0,0.05), rgba(92, 13, 30, 0.85)), url('image/velvetLipstick.jpg') no-repeat center center/cover;">
                <div class="offer-overlay" style="padding: 25px;">
                    <span class="badge">Dermatologist Choice</span>
                    <h3 style="font-size: 1.4rem;">Best Sellers</h3>
                    <p style="font-size: 0.85rem; margin-bottom: 0;">Explore our community's favorite beauty essentials &rarr;</p>
                </div>
            </a>
        </div>
    </section>

    <!-- Testimonials Section -->
    <section class="features" style="background: var(--bg-dark); border-top: 1px solid var(--border-light); padding: 80px 8%;">
        <h2>What Our Clients Say</h2>
        <div class="features-container">
            <div class="feature" style="background: var(--bg-card); text-align: left; padding: 35px; width: 320px;">
                <div style="color: var(--gold); margin-bottom: 15px; font-size: 0.85rem;">
                    <i class="fas fa-star"></i><i class="fas fa-star"></i><i class="fas fa-star"></i><i class="fas fa-star"></i><i class="fas fa-star"></i>
                </div>
                <p style="font-style: italic; color: var(--text-secondary); margin-bottom: 20px; font-size: 0.9rem;">
                    "The Glow Serum is an absolute game-changer. My skin has never looked this radiant and hydrated. Truly luxury in a bottle!"
                </p>
                <div style="font-weight: 600; color: var(--burgundy); font-size: 0.85rem;">— Elena R., New York</div>
            </div>

            <div class="feature" style="background: var(--bg-card); text-align: left; padding: 35px; width: 320px;">
                <div style="color: var(--gold); margin-bottom: 15px; font-size: 0.85rem;">
                    <i class="fas fa-star"></i><i class="fas fa-star"></i><i class="fas fa-star"></i><i class="fas fa-star"></i><i class="fas fa-star"></i>
                </div>
                <p style="font-style: italic; color: var(--text-secondary); margin-bottom: 20px; font-size: 0.9rem;">
                    "I love the Velvet Lipstick. The pigmentation is incredibly rich, and it doesn't dry out my lips at all. Worth every single penny."
                </p>
                <div style="font-weight: 600; color: var(--burgundy); font-size: 0.85rem;">— Sophia T., Los Angeles</div>
            </div>

            <div class="feature" style="background: var(--bg-card); text-align: left; padding: 35px; width: 320px;">
                <div style="color: var(--gold); margin-bottom: 15px; font-size: 0.85rem;">
                    <i class="fas fa-star"></i><i class="fas fa-star"></i><i class="fas fa-star"></i><i class="fas fa-star"></i><i class="fas fa-star"></i>
                </div>
                <p style="font-style: italic; color: var(--text-secondary); margin-bottom: 20px; font-size: 0.9rem;">
                    "Customer service is outstanding, and standard shipping was fast and free. LuxeGlow has won a customer for life."
                </p>
                <div style="font-weight: 600; color: var(--burgundy); font-size: 0.85rem;">— Clara M., Chicago</div>
            </div>
        </div>
    </section>

    <!-- Footer -->
    <%@ include file="footer.jsp" %>

    <script>


        // AJAX Handler to add products to cart
        function ajaxAddToCart(productId) {
            const params = new URLSearchParams();
            params.append('action', 'add');
            params.append('productId', productId);
            params.append('quantity', 1);

            fetch('CartServlet', {
                method: 'POST',
                body: params,
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded'
                }
            })
            .then(res => res.json())
            .then(data => {
                if (data.success) {
                    // Update header badge count
                    const el = document.getElementById('cartCount');
                    if (el) el.innerText = data.count;
                    
                    // Show custom premium toast success alert
                    showToast("Product added to your shopping bag.");
                } else {
                    showToast("Error adding product: " + data.error, "danger");
                }
            })
            .catch(err => {
                console.error(err);
                showToast("Please log in or try again.", "warning");
            });
        }
    </script>
</body>
</html>

