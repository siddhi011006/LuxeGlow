<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="com.mycompany.mavenproject2.DBConnection" %>
<%
    // Handle AJAX search suggestions request
    String actionParam = request.getParameter("action");
    if ("suggest".equals(actionParam)) {
        String q = request.getParameter("q");
        if (q == null) q = "";
        response.setContentType("application/json");
        Connection con = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            con = DBConnection.getConnection();
            ps = con.prepareStatement("SELECT name FROM products WHERE name LIKE ? LIMIT 5");
            ps.setString(1, "%" + q.trim() + "%");
            rs = ps.executeQuery();
            StringBuilder sb = new StringBuilder("[");
            boolean first = true;
            while (rs.next()) {
                if (!first) sb.append(",");
                sb.append("\"").append(rs.getString("name").replace("\"", "\\\"")).append("\"");
                first = false;
            }
            sb.append("]");
            out.print(sb.toString());
        } catch (Exception e) {
            out.print("[]");
        } finally {
            if (rs != null) rs.close();
            if (ps != null) ps.close();
            if (con != null) con.close();
        }
        return;
    }

    // Read search, filter, and sort parameters
    String paramCategory = request.getParameter("category");
    String paramSearch = request.getParameter("search");
    String paramSort = request.getParameter("sort");

    // Clean inputs
    if (paramCategory == null || paramCategory.trim().isEmpty()) {
        paramCategory = "all";
    }
    if (paramSearch == null) {
        paramSearch = "";
    }
    if (paramSort == null || paramSort.trim().isEmpty()) {
        paramSort = "default";
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Luxury Cosmetics Catalog | LuxeGlow</title>
    <!-- Core & Specific Styling -->
    <link rel="stylesheet" href="index.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    <style>
        .filter-categories-tabs {
            display: flex;
            justify-content: center;
            gap: 12px;
            flex-wrap: wrap;
            margin: 30px 0;
        }
        .cat-tab {
            background: var(--bg-card);
            border: 1px solid var(--border-color);
            color: var(--text-secondary);
            padding: 10px 24px;
            border-radius: 30px;
            font-size: 0.85rem;
            font-weight: 500;
            cursor: pointer;
            transition: var(--transition);
        }
        .cat-tab.active, .cat-tab:hover {
            background: var(--burgundy);
            color: white;
            border-color: var(--burgundy);
            box-shadow: var(--shadow-lux);
        }
        .search-input-wrapper {
            position: relative;
            max-width: 500px;
            width: 100%;
            margin: 0 auto;
        }
        .pagination-container {
            display: flex;
            justify-content: center;
            align-items: center;
            gap: 8px;
            margin-top: 50px;
            flex-wrap: wrap;
        }
        .page-btn {
            display: flex;
            align-items: center;
            justify-content: center;
            min-width: 40px;
            height: 40px;
            padding: 0 14px;
            border-radius: 20px;
            border: 1px solid var(--border-color);
            background: var(--bg-card);
            color: var(--text-secondary);
            font-size: 0.85rem;
            font-weight: 600;
            cursor: pointer;
            transition: var(--transition);
            text-decoration: none;
        }
        .page-btn:hover:not(.disabled) {
            background: var(--burgundy);
            color: white !important;
            border-color: var(--burgundy);
            box-shadow: var(--shadow-lux);
            transform: translateY(-2px);
        }
        .page-btn.active {
            background: var(--burgundy);
            color: white !important;
            border-color: var(--burgundy);
        }
        .page-btn.disabled {
            opacity: 0.4;
            cursor: not-allowed;
            pointer-events: none;
        }
        #productGrid {
            display: grid;
            grid-template-columns: 1fr;
            gap: 30px;
            margin-top: 40px;
        }
        @media (min-width: 576px) {
            #productGrid {
                grid-template-columns: repeat(2, 1fr);
            }
        }
        @media (min-width: 768px) {
            #productGrid {
                grid-template-columns: repeat(3, 1fr);
            }
        }
        @media (min-width: 1024px) {
            #productGrid {
                grid-template-columns: repeat(4, 1fr);
            }
        }
    </style>
</head>
<body>
<!-- Include Glassmorphic Header -->
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

    <!-- Hero Header -->
    <section class="hero" style="height: 35vh; min-height: 250px; background: linear-gradient(rgba(0,0,0,0.1), rgba(92,13,30,0.3)), url('image/silkfoundation.jpg') no-repeat center center/cover; display:flex; align-items:center; justify-content:center; text-align:center;">
        <div class="hero-content">
            <h1 style="font-size: 2.8rem; color: #FFFFFF; font-family:'Playfair Display', serif;">Luxury Beauty Collection</h1>
            <p style="color: #FAF6F4; font-size: 1rem; margin-top:10px;">Editorial elegance. Modern science. Soft luxury.</p>
        </div>
    </section>

    <div class="page-container" style="padding: 60px 8%;">
        
        <!-- Controls: Search & Sort -->
        <section class="controls" style="display: flex; justify-content: space-between; align-items: center; gap: 20px; flex-wrap: wrap; margin-bottom: 40px;">
            <div class="search-input-wrapper">
                <i class="fas fa-search" style="position: absolute; left: 16px; top: 50%; transform: translateY(-50%); color: var(--gold);"></i>
                <input type="text" id="searchInput" placeholder="Search products (press Enter)..." 
                       value="<%= paramSearch.replace("\"", "&quot;") %>" onkeydown="handleSearchKey(event)" oninput="showSuggestions(this.value)"
                       style="width: 100%; padding: 12px 18px 12px 45px; border-radius: 30px; border: 1px solid var(--border-color); background: var(--bg-card); outline: none; font-size: 0.9rem; transition: var(--transition);">
                <div id="suggestionsBox" style="position: absolute; top: 100%; left: 0; right: 0; background: var(--bg-card); border: 1px solid var(--border-color); border-radius: 12px; box-shadow: var(--shadow-lux); display: none; z-index: 1000; max-height: 220px; overflow-y: auto; margin-top: 5px;"></div>
            </div>

            <select id="sortSelect" onchange="applyFilters()" style="padding: 12px 20px; border-radius: 30px; border: 1px solid var(--border-color); background: var(--bg-card); color: var(--text-secondary); font-size: 0.85rem; outline: none; cursor: pointer;">
                <option value="default" <%= "default".equals(paramSort) ? "selected" : "" %>>Sort by: Feature</option>
                <option value="low" <%= "low".equals(paramSort) ? "selected" : "" %>>Price: Low to High</option>
                <option value="high" <%= "high".equals(paramSort) ? "selected" : "" %>>Price: High to Low</option>
            </select>
        </section>

        <!-- Category Tabs Navigation -->
        <div class="filter-categories-tabs">
            <button class="cat-tab <%= "all".equals(paramCategory) ? "active" : "" %>" onclick="setCategory('all')">All Products</button>
            <%
                Connection conTab = null;
                Statement stTab = null;
                ResultSet rsTab = null;
                try {
                    conTab = DBConnection.getConnection();
                    stTab = conTab.createStatement();
                    rsTab = stTab.executeQuery("SELECT name FROM categories ORDER BY name ASC");
                    while (rsTab.next()) {
                        String catName = rsTab.getString("name");
            %>
            <button class="cat-tab <%= catName.equalsIgnoreCase(paramCategory) ? "active" : "" %>" onclick="setCategory('<%= catName.replace("'", "\\'") %>')"><%= catName %></button>
            <%
                    }
                } catch (Exception e) {
                    e.printStackTrace();
                } finally {
                    if (rsTab != null) try { rsTab.close(); } catch (Exception e) {}
                    if (stTab != null) try { stTab.close(); } catch (Exception e) {}
                    if (conTab != null) try { conTab.close(); } catch (Exception e) {}
                }
            %>
        </div>

        <!-- Catalog Product Grid -->
        <section class="products-grid" id="productGrid">
            <%
                Connection con = null;
                PreparedStatement ps = null;
                ResultSet rs = null;
                int count = 0;
                int currentPage = 1;
                int totalPages = 1;
                
                try {
                    con = DBConnection.getConnection();
                    
                    // Count total matching products for pagination
                    int totalProducts = 0;
                    PreparedStatement psCount = null;
                    ResultSet rsCount = null;
                    try {
                        StringBuilder countQueryBuilder = new StringBuilder("SELECT COUNT(*) FROM products WHERE status = 'ACTIVE'");
                        if (!"all".equals(paramCategory)) {
                            countQueryBuilder.append(" AND category = ?");
                        }
                        if (!paramSearch.isEmpty()) {
                            countQueryBuilder.append(" AND name LIKE ?");
                        }
                        psCount = con.prepareStatement(countQueryBuilder.toString());
                        int idx = 1;
                        if (!"all".equals(paramCategory)) {
                            psCount.setString(idx++, paramCategory);
                        }
                        if (!paramSearch.isEmpty()) {
                            psCount.setString(idx++, "%" + paramSearch.trim() + "%");
                        }
                        rsCount = psCount.executeQuery();
                        if (rsCount.next()) {
                            totalProducts = rsCount.getInt(1);
                        }
                    } catch (Exception e) {
                        e.printStackTrace();
                    } finally {
                        if (rsCount != null) rsCount.close();
                        if (psCount != null) psCount.close();
                    }

                    // Parse page parameter
                    String paramPage = request.getParameter("page");
                    if (paramPage != null && !paramPage.trim().isEmpty()) {
                        try {
                            currentPage = Integer.parseInt(paramPage);
                            if (currentPage < 1) currentPage = 1;
                        } catch (NumberFormatException e) {
                            currentPage = 1;
                        }
                    }
                    int productsPerPage = 12;
                    totalPages = (int) Math.ceil((double) totalProducts / productsPerPage);
                    if (totalPages < 1) totalPages = 1;
                    if (currentPage > totalPages) currentPage = totalPages;
                    int offset = (currentPage - 1) * productsPerPage;
                    
                    // Build dynamic SQL
                    StringBuilder queryBuilder = new StringBuilder("SELECT id, name, description, price, category, image_url, rating FROM products WHERE status = 'ACTIVE'");
                    
                    if (!"all".equals(paramCategory)) {
                        queryBuilder.append(" AND category = ?");
                    }
                    if (!paramSearch.isEmpty()) {
                        queryBuilder.append(" AND name LIKE ?");
                    }
                    
                    if ("low".equals(paramSort)) {
                        queryBuilder.append(" ORDER BY price ASC");
                    } else if ("high".equals(paramSort)) {
                        queryBuilder.append(" ORDER BY price DESC");
                    }
                    
                    queryBuilder.append(" LIMIT ? OFFSET ?");
                    
                    ps = con.prepareStatement(queryBuilder.toString());
                    
                    int placeholderIdx = 1;
                    if (!"all".equals(paramCategory)) {
                        ps.setString(placeholderIdx++, paramCategory);
                    }
                    if (!paramSearch.isEmpty()) {
                        ps.setString(placeholderIdx++, "%" + paramSearch.trim() + "%");
                    }
                    ps.setInt(placeholderIdx++, productsPerPage);
                    ps.setInt(placeholderIdx++, offset);
                    
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
            <div class="card" style="background: var(--bg-card); border-radius: 16px; border: 1px solid var(--border-light); overflow: hidden; box-shadow: var(--shadow-lux); transition: var(--transition);">
                <div class="card-image-wrapper" style="position: relative; height: 260px; overflow: hidden;">
                    <button class="wishlist-heart-btn <%= wishlistedIds.contains(id) ? "liked" : "" %>" 
                            data-product-id="<%= id %>" 
                            onclick="toggleWishlist(event, <%= id %>)" 
                            title="<%= wishlistedIds.contains(id) ? "Remove from Wishlist" : "Add to Wishlist" %>">
                        <i class="<%= wishlistedIds.contains(id) ? "fas" : "far" %> fa-heart"></i>
                    </button>
                    <% if ("ADMIN".equalsIgnoreCase(navRole)) { %>
                        <div class="admin-quick-actions" style="position: absolute; bottom: 10px; left: 10px; display: flex; gap: 8px; z-index: 10;">
                            <a href="admin?tab=product-details&id=<%= id %>" title="Quick Edit Specs" style="background: var(--burgundy); color: white; width: 32px; height: 32px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 0.8rem; box-shadow: var(--shadow-lux);"><i class="fas fa-edit"></i></a>
                        </div>
                    <% } %>
                    <a href="product-details.jsp?id=<%= id %>">
                        <img src="<%= imageUrl %>" alt="<%= name %>" style="width: 100%; height: 100%; object-fit: cover; transition: var(--transition);">
                    </a>
                </div>
                <div class="card-content" style="padding: 20px; text-align: left;">
                    <div class="card-category" style="font-size: 0.7rem; font-weight: 600; color: var(--gold); text-transform: uppercase; letter-spacing: 1px; margin-bottom: 8px;"><%= category %></div>
                    <a href="product-details.jsp?id=<%= id %>" style="text-decoration: none;">
                        <h3 style="font-size: 1.15rem; color: var(--burgundy); font-family: 'Playfair Display', serif; font-weight: 600; margin-bottom: 8px; line-height: 1.3;"><%= name %></h3>
                    </a>
                    <div class="card-rating" style="color: var(--gold); font-size: 0.8rem; margin-bottom: 15px;">
                        <% for (int i = 0; i < 5; i++) { %>
                            <i class="<%= (i < rating) ? "fas" : "far" %> fa-star"></i>
                        <% } %>
                    </div>
                    <div class="card-footer" style="display: flex; justify-content: space-between; align-items: center;">
                        <div class="price" style="font-weight: 700; color: var(--text-primary); font-size: 1.1rem;"><%= com.mycompany.mavenproject2.CurrencyHelper.formatPrice(price, currentCountry) %></div>
                        <button class="add-to-cart-btn" onclick="ajaxAddToCart(<%= id %>)" title="Add to Cart" style="background: var(--burgundy); border: none; color: white; width: 38px; height: 38px; border-radius: 50%; display: flex; align-items: center; justify-content: center; cursor: pointer; transition: var(--transition);">
                            <i class="fas fa-shopping-bag" style="font-size: 0.9rem;"></i>
                        </button>
                    </div>
                </div>
            </div>
            <%
                    }
                } catch (Exception e) {
                    out.println("<p style='color:var(--danger); grid-column: 1/-1;'>Database Error: " + e.getMessage() + "</p>");
                    e.printStackTrace();
                } finally {
                    if (rs != null) rs.close();
                    if (ps != null) ps.close();
                    if (con != null) con.close();
                }
                
                if (count == 0) {
                    out.println("<div style='text-align:center; padding:50px 0; color:var(--text-muted); grid-column: 1/-1;'>");
                    out.println("<i class='fas fa-search' style='font-size:3rem; margin-bottom:15px; color:var(--gold);'></i>");
                    out.println("<p>No beauty products matched your selection.</p>");
                    out.println("<a href='product.jsp' style='display:inline-block; margin-top:15px; font-weight:600; text-decoration:underline;'>View All Products</a>");
                    out.println("</div>");
                }
            %>
        </section>

        <!-- Pagination Navigation controls -->
        <% if (totalPages > 1) { %>
            <div class="pagination-container">
                <!-- Previous Button -->
                <% if (currentPage > 1) { %>
                    <a href="product.jsp?category=<%= java.net.URLEncoder.encode(paramCategory, "UTF-8") %>&search=<%= java.net.URLEncoder.encode(paramSearch, "UTF-8") %>&sort=<%= java.net.URLEncoder.encode(paramSort, "UTF-8") %>&page=<%= currentPage - 1 %>" class="page-btn" title="Previous Page">&laquo; Prev</a>
                <% } else { %>
                    <span class="page-btn disabled" title="Previous Page">&laquo; Prev</span>
                <% } %>

                <!-- Page Numbers -->
                <% for (int i = 1; i <= totalPages; i++) { %>
                    <% if (i == currentPage) { %>
                        <span class="page-btn active"><%= i %></span>
                    <% } else { %>
                        <a href="product.jsp?category=<%= java.net.URLEncoder.encode(paramCategory, "UTF-8") %>&search=<%= java.net.URLEncoder.encode(paramSearch, "UTF-8") %>&sort=<%= java.net.URLEncoder.encode(paramSort, "UTF-8") %>&page=<%= i %>" class="page-btn"><%= i %></a>
                    <% } %>
                <% } %>

                <!-- Next Button -->
                <% if (currentPage < totalPages) { %>
                    <a href="product.jsp?category=<%= java.net.URLEncoder.encode(paramCategory, "UTF-8") %>&search=<%= java.net.URLEncoder.encode(paramSearch, "UTF-8") %>&sort=<%= java.net.URLEncoder.encode(paramSort, "UTF-8") %>&page=<%= currentPage + 1 %>" class="page-btn" title="Next Page">Next &raquo;</a>
                <% } else { %>
                    <span class="page-btn disabled" title="Next Page">Next &raquo;</span>
                <% } %>
            </div>
        <% } %>

    </div>

    <!-- Include Reusable Footer -->
    <%@ include file="footer.jsp" %>

    <script>
        // JS Filters and Search Handlers
        function applyFilters() {
            const searchVal = document.getElementById('searchInput').value.trim();
            const sortVal = document.getElementById('sortSelect').value;
            const urlParams = new URLSearchParams(window.location.search);
            
            if (searchVal) {
                urlParams.set('search', searchVal);
            } else {
                urlParams.delete('search');
            }
            
            if (sortVal && sortVal !== 'default') {
                urlParams.set('sort', sortVal);
            } else {
                urlParams.delete('sort');
            }
            
            // Reset to page 1 on filter change
            urlParams.delete('page');
            
            window.location.search = urlParams.toString();
        }

        function handleSearchKey(event) {
            if (event.key === 'Enter') {
                applyFilters();
            }
        }

        function setCategory(category) {
            const urlParams = new URLSearchParams(window.location.search);
            if (category && category !== 'all') {
                urlParams.set('category', category);
            } else {
                urlParams.delete('category');
            }
            // Reset to page 1 on category change
            urlParams.delete('page');
            window.location.search = urlParams.toString();
        }

        // Suggestions Autocomplete
        function showSuggestions(q) {
            const box = document.getElementById('suggestionsBox');
            if (!q || q.trim().length < 2) {
                box.style.display = 'none';
                return;
            }
            fetch('product.jsp?action=suggest&q=' + encodeURIComponent(q.trim()))
                .then(res => res.json())
                .then(data => {
                    if (data.length === 0) {
                        box.style.display = 'none';
                        return;
                    }
                    box.innerHTML = '';
                    data.forEach(item => {
                        const div = document.createElement('div');
                        div.innerText = item;
                        div.style.padding = '12px 18px';
                        div.style.cursor = 'pointer';
                        div.style.fontSize = '0.85rem';
                        div.style.color = 'var(--text-secondary)';
                        div.style.borderBottom = '1px solid var(--border-light)';
                        div.addEventListener('click', () => {
                            document.getElementById('searchInput').value = item;
                            box.style.display = 'none';
                            applyFilters();
                        });
                        div.addEventListener('mouseover', () => {
                            div.style.background = 'rgba(92, 13, 30, 0.04)';
                            div.style.color = 'var(--burgundy)';
                        });
                        div.addEventListener('mouseout', () => {
                            div.style.background = 'transparent';
                            div.style.color = 'var(--text-secondary)';
                        });
                        box.appendChild(div);
                    });
                    box.style.display = 'block';
                })
                .catch(err => {
                    console.error(err);
                    box.style.display = 'none';
                });
        }

        document.addEventListener('click', function(e) {
            const box = document.getElementById('suggestionsBox');
            if (box && e.target.id !== 'searchInput') {
                box.style.display = 'none';
            }
        });

        // AJAX Cart Submission
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
                    const el = document.getElementById('cartCount');
                    if (el) el.innerText = data.count;
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
