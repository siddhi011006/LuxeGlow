<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="com.mycompany.mavenproject2.DBConnection" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.util.ArrayList" %>
<%
    // Ensure authentication & admin privileges
    HttpSession s = request.getSession(false);
    if (s == null || !"ADMIN".equalsIgnoreCase((String) s.getAttribute("role"))) {
        response.sendRedirect(request.getContextPath() + "/");
        return;
    }

    String activeTab = request.getParameter("tab");
    if (activeTab == null || activeTab.trim().isEmpty()) {
        activeTab = "dashboard";
    }

    // Retrieve variables from request attributes set by AdminDashboardServlet
    Double totalRevenueAttr = (Double) request.getAttribute("totalRevenue");
    Integer totalOrdersAttr = (Integer) request.getAttribute("totalOrdersCount");
    Integer totalUsersAttr = (Integer) request.getAttribute("totalUsersCount");
    Integer totalProductsAttr = (Integer) request.getAttribute("totalProductsCount");
    Integer newUsersThisMonthAttr = (Integer) request.getAttribute("newUsersThisMonth");

    double totalRevenue = totalRevenueAttr != null ? totalRevenueAttr : 0.0;
    int totalOrdersCount = totalOrdersAttr != null ? totalOrdersAttr : 0;
    int totalUsersCount = totalUsersAttr != null ? totalUsersAttr : 0;
    int totalProductsCount = totalProductsAttr != null ? totalProductsAttr : 0;
    int newUsersThisMonth = newUsersThisMonthAttr != null ? newUsersThisMonthAttr : 0;

    List<String> categoriesList = (List<String>) request.getAttribute("categoriesList");
    if (categoriesList == null) {
        categoriesList = new ArrayList<>();
    }
    List<Map<String, Object>> recentOrdersList = (List<Map<String, Object>>) request.getAttribute("recentOrdersList");
    if (recentOrdersList == null) {
        recentOrdersList = new ArrayList<>();
    }
    List<Map<String, Object>> monthlySalesList = (List<Map<String, Object>>) request.getAttribute("monthlySalesList");
    List<Map<String, Object>> bestSellersList = (List<Map<String, Object>>) request.getAttribute("bestSellersList");

    // Retrieve and parse selected product ID null-safely at page scope
    String prodIdParam = request.getParameter("id");
    int prodId = 0;
    if (prodIdParam != null && !prodIdParam.trim().isEmpty()) {
        try {
            prodId = Integer.parseInt(prodIdParam.trim());
        } catch (NumberFormatException e) {
            prodId = 0;
        }
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Operations Control Panel | LuxeGlow Admin</title>
    <!-- Core Styling -->
    <link rel="stylesheet" href="index.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    <!-- Chart.js for High-End Interactive Widgets -->
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        .admin-sidebar button {
            cursor: pointer;
        }
        .variants-sub-table th, .variants-sub-table td {
            padding: 8px 12px;
            font-size: 0.8rem;
        }
        .variants-sub-table th {
            border-bottom: 1px solid var(--border-light);
            color: var(--text-muted);
            font-weight: 600;
        }
        .variant-color-indicator {
            display: inline-block;
            width: 12px;
            height: 12px;
            border-radius: 50%;
            border: 1px solid rgba(0,0,0,0.15);
            margin-right: 6px;
            vertical-align: middle;
        }
        @keyframes fadeInRight {
            from { opacity: 0; transform: translateX(50px); }
            to { opacity: 1; transform: translateX(0); }
        }
        @keyframes fadeOutRight {
            from { opacity: 1; transform: translateX(0); }
            to { opacity: 0; transform: translateX(50px); }
        }
    </style>
</head>
<body>

    <div class="announcement-bar">
        <p>LuxeGlow Operations Center — Secure Administrator Area</p>
    </div>

    <!-- Include Glassmorphic Header -->
    <%@ include file="../navbar.jsp" %>

    <div class="page-container" style="max-width:1350px;">
        
        <!-- Alerts for Operation Messages -->
        <%
            String errorMsg = request.getParameter("error");
            String successMsg = request.getParameter("success");
            if (errorMsg != null) {
        %>
            <div class="alert alert-danger" style="margin-bottom:30px;">
                <i class="fas fa-exclamation-circle"></i>
                <span><%= errorMsg %></span>
            </div>
        <%
            }
            if (successMsg != null) {
        %>
            <div class="alert alert-success" style="margin-bottom:30px;">
                <i class="fas fa-check-circle"></i>
                <span><%= successMsg %></span>
            </div>
        <%
            }
        %>

        <h1 style="font-size:2.2rem; font-family:'Playfair Display', serif; margin-bottom:45px; border-bottom:1px solid var(--border-light); padding-bottom:15px; text-align:left;">
            <i class="fas fa-sliders-h" style="color:var(--gold); margin-right:12px;"></i> Operations Control Panel
        </h1>

        <!-- Sidebar + View Layout -->
        <div class="admin-grid">
            
            <!-- Side Navigation Menu -->
            <aside class="admin-sidebar">
                <ul>
                    <li>
                        <button class="<%= "dashboard".equals(activeTab) ? "active" : "" %>" onclick="location.href='admin?tab=dashboard'">
                            <i class="fas fa-chart-line"></i> Dashboard
                        </button>
                    </li>
                    <li>
                        <button class="<%= "products".equals(activeTab) ? "active" : "" %>" onclick="location.href='admin?tab=products'">
                            <i class="fas fa-box"></i> Catalog Manager
                        </button>
                    </li>
                    <li>
                        <button class="<%= "orders".equals(activeTab) ? "active" : "" %>" onclick="location.href='admin?tab=orders'">
                            <i class="fas fa-receipt"></i> Order Fulfillment
                        </button>
                    </li>
                    <li>
                        <button class="<%= "users".equals(activeTab) ? "active" : "" %>" onclick="location.href='admin?tab=users'">
                            <i class="fas fa-users-cog"></i> User Management
                        </button>
                    </li>
                    <li>
                        <button class="<%= "reports".equals(activeTab) ? "active" : "" %>" onclick="location.href='admin?tab=reports'">
                            <i class="fas fa-file-invoice-dollar"></i> Sales Reports
                        </button>
                    </li>
                    <li>
                        <button class="<%= "promotions".equals(activeTab) ? "active" : "" %>" onclick="location.href='admin?tab=promotions'">
                            <i class="fas fa-percentage"></i> Promotions
                        </button>
                    </li>
                    <li>
                        <button class="<%= "coupons".equals(activeTab) ? "active" : "" %>" onclick="location.href='admin?tab=coupons'">
                            <i class="fas fa-ticket-alt"></i> Coupons
                        </button>
                    </li>
                    <li>
                        <button class="<%= "reviews".equals(activeTab) ? "active" : "" %>" onclick="location.href='admin?tab=reviews'">
                            <i class="fas fa-star"></i> Reviews
                        </button>
                    </li>
                    <li>
                        <button class="<%= "settings".equals(activeTab) ? "active" : "" %>" onclick="location.href='admin?tab=settings'">
                            <i class="fas fa-cogs"></i> System Settings
                        </button>
                    </li>
                    <li style="margin-top:20px; border-top:1px solid var(--border-light); padding-top:15px;">
                        <button style="color:var(--danger);" onclick="if(confirm('Sign out of Admin Session?')) location.href='admin-logout';">
                            <i class="fas fa-sign-out-alt" style="color:var(--danger);"></i> Log Out
                        </button>
                    </li>
                </ul>
            </aside>

            <!-- Main Panel View -->
            <main>
                
                <% if ("dashboard".equalsIgnoreCase(activeTab)) { %>
                    <!-- ==========================================
                         DASHBOARD SUMMARY TAB
                         ========================================== -->
                    <!-- Stats Counter Cards Row -->
                    <section class="admin-stats-row">
                        <div class="stat-card">
                            <i class="fas fa-wallet"></i>
                            <div class="num">₹<%= String.format("%.2f", totalRevenue) %></div>
                            <div class="label">Total Revenue</div>
                        </div>
                        <div class="stat-card">
                            <i class="fas fa-shopping-bag"></i>
                            <div class="num"><%= totalOrdersCount %></div>
                            <div class="label">Total Orders</div>
                        </div>
                        <div class="stat-card">
                            <i class="fas fa-users"></i>
                            <div class="num"><%= totalUsersCount %></div>
                            <div class="label">Registered Users</div>
                        </div>
                        <div class="stat-card">
                            <i class="fas fa-box"></i>
                            <div class="num"><%= totalProductsCount %></div>
                            <div class="label">Total Products</div>
                        </div>
                    </section>

                    <div style="display:grid; grid-template-columns:1.5fr 1fr; gap:30px; margin-top:20px; text-align:left;">
                        <!-- Recent Orders Column -->
                        <div>
                            <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:15px;">
                                <h3 style="font-size:1.3rem; border-bottom:none; margin:0;">Recent Client Transactions</h3>
                                <a href="admin?tab=orders" style="font-size:0.8rem; font-weight:600; text-transform:uppercase; color:var(--gold);">View All Orders</a>
                            </div>

                            <table class="admin-table" style="margin-top:0;">
                                <thead>
                                    <tr>
                                        <th>Ref</th>
                                        <th>Customer</th>
                                        <th>Date</th>
                                        <th>Total</th>
                                        <th>Status</th>
                                        <th style="text-align:right;">Action</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <%
                                        if (recentOrdersList.isEmpty()) {
                                    %>
                                    <tr>
                                        <td colspan="6" style="text-align:center; padding:30px; color:var(--text-muted);">No recent orders recorded.</td>
                                    </tr>
                                    <%
                                        } else {
                                            for (Map<String, Object> order : recentOrdersList) {
                                                int id = (Integer) order.get("id");
                                                java.util.Date date = (java.util.Date) order.get("date");
                                                double amt = (Double) order.get("total");
                                                String status = (String) order.get("status");
                                                String customer = (String) order.get("customer");
                                                String address = (String) order.get("address");

                                                String badgeClass = "status-pending";
                                                if ("PROCESSING".equalsIgnoreCase(status)) badgeClass = "status-processing";
                                                else if ("SHIPPED".equalsIgnoreCase(status)) badgeClass = "status-shipped";
                                                else if ("DELIVERED".equalsIgnoreCase(status)) badgeClass = "status-completed";
                                                else if ("CANCELLED".equalsIgnoreCase(status)) badgeClass = "status-cancelled";
                                    %>
                                    <tr>
                                        <td style="font-weight:600; color:var(--gold);">#LXG-<%= id %></td>
                                        <td><%= customer %></td>
                                        <td style="font-size:0.75rem;"><%= date %></td>
                                        <td style="font-weight:600;">₹<%= String.format("%.2f", amt) %></td>
                                        <td><span class="status-badge <%= badgeClass %>"><%= status %></span></td>
                                        <td style="text-align:right;">
                                            <button class="btn-outline" style="border-radius:6px; padding:6px 12px; font-size:0.75rem; text-transform:none;" onclick="showOrderDetails(<%= id %>)">
                                                View Items
                                            </button>

                                            <!-- Render Hidden Container for JavaScript Modal Extraction -->
                                            <div id="orderDetails-<%= id %>" style="display:none;">
                                                <div style="margin-bottom:15px; font-size: 0.85rem; line-height: 1.5;">
                                                    <strong>Order Ref:</strong> #LXG-<%= id %><br>
                                                    <strong>Customer:</strong> <%= customer %><br>
                                                    <strong>Order Date:</strong> <%= date %><br>
                                                    <strong>Shipping Address:</strong> <%= address %>
                                                </div>
                                                <h4 style="font-family:'Playfair Display', serif; border-bottom:1px solid var(--border-light); padding-bottom:8px; margin-bottom:12px; font-size:1.1rem; color:var(--burgundy);">Purchased Cosmetics</h4>
                                                <div style="max-height:220px; overflow-y:auto; margin-bottom:15px;">
                                                <%
                                                    try (Connection con = DBConnection.getConnection();
                                                         PreparedStatement ps = con.prepareStatement(
                                                             "SELECT oi.quantity, oi.price, p.name, p.image_url, pv.variant_name FROM order_items oi " +
                                                             "JOIN products p ON oi.product_id = p.id " +
                                                             "LEFT JOIN product_variants pv ON oi.variant_id = pv.id " +
                                                             "WHERE oi.order_id = ?")) {
                                                        ps.setInt(1, id);
                                                        try (ResultSet rs = ps.executeQuery()) {
                                                            while (rs.next()) {
                                                                String vName = rs.getString("variant_name");
                                                %>
                                                    <div style="display:flex; justify-content:space-between; align-items:center; padding:8px 0; border-bottom:1px solid rgba(0,0,0,0.03);">
                                                        <div style="display:flex; align-items:center; gap:10px;">
                                                            <img src="<%= rs.getString("image_url") %>" style="width:40px; height:40px; border-radius:6px; object-fit:cover; border:1px solid var(--border-light);">
                                                            <div>
                                                                <div style="font-weight:600; font-size:0.85rem;">
                                                                    <%= rs.getString("name") %>
                                                                    <% if (vName != null && !vName.isEmpty()) { %>
                                                                        <span style="font-size:0.7rem; color:var(--gold); font-weight:600;">(Shade: <%= vName %>)</span>
                                                                    <% } %>
                                                                </div>
                                                                <div style="font-size:0.75rem; color:var(--text-muted);">Qty: <%= rs.getInt("quantity") %> &times; ₹<%= String.format("%.2f", rs.getDouble("price")) %></div>
                                                            </div>
                                                        </div>
                                                        <div style="font-weight:600; font-size:0.85rem;">₹<%= String.format("%.2f", rs.getDouble("price") * rs.getInt("quantity")) %></div>
                                                    </div>
                                                <%
                                                            }
                                                        }
                                                    } catch (Exception ex) {
                                                        out.println("<p style='color:var(--danger);'>Error loading details: " + ex.getMessage() + "</p>");
                                                    }
                                                %>
                                                </div>
                                                <div style="display:flex; justify-content:space-between; font-weight:700; font-size:1.05rem; padding-top:12px; border-top:1px solid var(--border-color); color:var(--burgundy);">
                                                    <span>Total Charges:</span>
                                                    <span>₹<%= String.format("%.2f", amt) %></span>
                                                </div>
                                            </div>
                                        </td>
                                    </tr>
                                    <%
                                            }
                                        }
                                    %>
                                </tbody>
                            </table>
                        </div>

                        <!-- Mini Charts Widget Column -->
                        <div style="background:var(--bg-card); border:1px solid var(--border-color); border-radius:24px; padding:30px; box-shadow:var(--shadow-lux);">
                            <h3 style="font-size:1.3rem; margin-bottom:20px; border:none;">Sales Distributions</h3>
                            
                            <div style="position:relative; height:240px; margin-bottom:30px;">
                                <canvas id="miniSalesChart"></canvas>
                            </div>
                            <div style="font-size:0.8rem; color:var(--text-secondary); text-align:center; border-top:1px solid var(--border-light); padding-top:15px;">
                                <i class="fas fa-info-circle" style="color:var(--gold); margin-right:5px;"></i> Visualized monthly revenue trajectories.
                            </div>
                        </div>
                    </div>

                <% } else if ("products".equalsIgnoreCase(activeTab)) { %>
                    <!-- ==========================================
                         CATALOG MANAGER TAB (REDESIGNED)
                         ========================================== -->
                    <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:25px; text-align:left;">
                        <div>
                            <h2 style="font-size:1.6rem; border-bottom:none; margin:0; padding-bottom:0; font-family:'Playfair Display', serif; color:var(--burgundy);">Beauty Inventory</h2>
                            <p style="color:var(--text-muted); font-size:0.85rem; margin-top:5px;">Configure catalog entries, stocks, variants, and cosmetic imaging.</p>
                        </div>
                        <button class="btn-gold" style="border-radius:12px; padding:10px 24px;" onclick="openAddModal()">
                            <i class="fas fa-plus" style="margin-right:8px;"></i> Add Product
                        </button>
                    </div>

                    <!-- Advanced Filters & Sorting Bar -->
                    <div style="display:grid; grid-template-columns: 2fr 1fr 1fr 1fr 1fr 1fr; gap:12px; margin-bottom:20px; align-items:center;">
                        <div class="search-input-wrapper" style="margin-bottom:0; text-align:left; width:100%;">
                            <i class="fas fa-search"></i>
                            <input type="text" id="catalogSearch" onkeyup="filterCatalog()" placeholder="Search by name, SKU, brand...">
                        </div>
                        <div>
                            <select id="categoryFilter" onchange="filterCatalog()" style="padding:10px 12px; border-radius:8px; background:var(--bg-card); font-size:0.85rem; width:100%; border:1px solid var(--border-color); color:var(--text-primary);">
                                <option value="all">All Categories</option>
                                <% for (String catName : categoriesList) { %>
                                    <option value="<%= catName %>"><%= catName %></option>
                                <% } %>
                            </select>
                        </div>
                        <div>
                            <select id="statusFilter" onchange="filterCatalog()" style="padding:10px 12px; border-radius:8px; background:var(--bg-card); font-size:0.85rem; width:100%; border:1px solid var(--border-color); color:var(--text-primary);">
                                <option value="ALL">All Statuses</option>
                                <option value="ACTIVE">Active</option>
                                <option value="DRAFT">Draft</option>
                            </select>
                        </div>
                        <div>
                            <select id="stockFilter" onchange="filterCatalog()" style="padding:10px 12px; border-radius:8px; background:var(--bg-card); font-size:0.85rem; width:100%; border:1px solid var(--border-color); color:var(--text-primary);">
                                <option value="ALL">All Stock Levels</option>
                                <option value="LOW">Low Stock (&lt; 10)</option>
                                <option value="OUT">Out of Stock</option>
                            </select>
                        </div>
                        <div>
                            <select id="onSaleFilter" onchange="filterCatalog()" style="padding:10px 12px; border-radius:8px; background:var(--bg-card); font-size:0.85rem; width:100%; border:1px solid var(--border-color); color:var(--text-primary);">
                                <option value="ALL">All Prices</option>
                                <option value="SALE">On Sale</option>
                                <option value="NORMAL">Normal Price</option>
                            </select>
                        </div>
                        <div>
                            <select id="sortSelector" onchange="filterCatalog()" style="padding:10px 12px; border-radius:8px; background:var(--bg-card); font-size:0.85rem; width:100%; border:1px solid var(--border-color); color:var(--text-primary);">
                                <option value="id_desc">Sort: Newest</option>
                                <option value="name_asc">Sort: Name A-Z</option>
                                <option value="name_desc">Sort: Name Z-A</option>
                                <option value="price_asc">Sort: Price Low-High</option>
                                <option value="price_desc">Sort: Price High-Low</option>
                                <option value="stock_asc">Sort: Stock Low-High</option>
                                <option value="stock_desc">Sort: Stock High-Low</option>
                                <option value="rating_desc">Sort: Rating High-Low</option>
                            </select>
                        </div>
                    </div>

                    <!-- Bulk Actions Toolbar -->
                    <div id="bulkActionsToolbar" style="display:none; background:var(--bg-surface); border:1px solid var(--gold); padding:12px 20px; border-radius:12px; margin-bottom:20px; text-align:left; align-items:center; justify-content:space-between; gap:15px; box-shadow:var(--shadow-lux);">
                        <div style="display:flex; align-items:center; gap:10px;">
                            <span id="selectedCountLabel" style="font-weight:600; color:var(--gold); font-size:0.9rem;">0 items selected</span>
                        </div>
                        <div style="display:flex; gap:10px;">
                            <button type="button" class="btn-outline" onclick="performBulkAction('activate')" style="border-radius:6px; padding:6px 12px; font-size:0.75rem; text-transform:none;">
                                <i class="fas fa-check" style="margin-right:4px; color:var(--success);"></i> Make Active
                            </button>
                            <button type="button" class="btn-outline" onclick="performBulkAction('draft')" style="border-radius:6px; padding:6px 12px; font-size:0.75rem; text-transform:none;">
                                <i class="fas fa-eye-slash" style="margin-right:4px; color:var(--text-muted);"></i> Make Draft
                            </button>
                            <button type="button" class="btn-outline" onclick="performBulkAction('delete')" style="border-radius:6px; padding:6px 12px; font-size:0.75rem; color:var(--danger); border-color:var(--danger); background:transparent; text-transform:none;">
                                <i class="fas fa-trash" style="margin-right:4px;"></i> Delete Selected
                            </button>
                        </div>
                    </div>

                    <!-- Catalogue Table Layout -->
                    <div style="background:var(--bg-card); border:1px solid var(--border-color); border-radius:18px; padding:15px; box-shadow:var(--shadow-lux); overflow-x:auto;">
                        <table class="admin-table" style="width:100%; margin-top:0; border-collapse:collapse;" id="catalogTable">
                            <thead>
                                <tr>
                                    <th style="width:40px; text-align:center; padding:12px 8px;">
                                        <input type="checkbox" id="selectAllCheckbox" onchange="toggleSelectAll(this)" style="cursor:pointer; width:16px; height:16px;">
                                    </th>
                                    <th style="width:80px;">ID & Image</th>
                                    <th>Product Details</th>
                                    <th style="width:100px;">Base Price</th>
                                    <th style="width:160px;">Inventory (Main)</th>
                                    <th style="width:90px; text-align:center;">Rating</th>
                                    <th style="width:100px; text-align:center;">Status</th>
                                    <th style="width:120px; text-align:right; padding-right:15px;">Actions</th>
                                </tr>
                            </thead>
                            <tbody id="catalogTableBody">
                                <%
                                    try {
                                        Connection con = DBConnection.getConnection();
                                        Statement st = con.createStatement();
                                        ResultSet rs = st.executeQuery("SELECT id, name, description, price, category, image_url, stock, rating, brand, sku, status FROM products ORDER BY id DESC");
                                        while (rs.next()) {
                                            int id = rs.getInt("id");
                                            String name = rs.getString("name");
                                            String desc = rs.getString("description").replace("'", "\\'").replace("\n", " ").replace("\r", " ");
                                            double price = rs.getDouble("price");
                                            String cat = rs.getString("category");
                                            String img = rs.getString("image_url");
                                            int stock = rs.getInt("stock");
                                            int rating = rs.getInt("rating");
                                            String brand = rs.getString("brand");
                                            String sku = rs.getString("sku");
                                            String status = rs.getString("status");
                                            boolean onSale = com.mycompany.mavenproject2.PromotionHelper.hasPromotion(id, cat, brand);
                                %>
                                <tr class="product-row" 
                                    data-id="<%= id %>"
                                    data-name="<%= name.toLowerCase().replace("\"", "&quot;") %>"
                                    data-sku="<%= (sku != null ? sku.toLowerCase().replace("\"", "&quot;") : "") %>"
                                    data-brand="<%= (brand != null ? brand.toLowerCase().replace("\"", "&quot;") : "") %>"
                                    data-category="<%= cat.toLowerCase().replace("\"", "&quot;") %>"
                                    data-status="<%= (status != null ? status.toUpperCase() : "ACTIVE") %>"
                                    data-stock="<%= stock %>"
                                    data-price="<%= price %>"
                                    data-rating="<%= rating %>"
                                    data-onsale="<%= onSale ? "true" : "false" %>"
                                    style="border-bottom:1px solid var(--border-light); vertical-align:middle; transition: background 0.2s ease;">
                                    
                                    <td style="text-align:center; padding:12px 8px; vertical-align:middle;">
                                        <input type="checkbox" class="product-select-checkbox" data-id="<%= id %>" onchange="updateSelectionState()" style="cursor:pointer; width:16px; height:16px;">
                                    </td>
                                    
                                    <td style="vertical-align:middle;">
                                        <div style="position:relative; width:50px; height:50px; border-radius:8px; overflow:hidden; border:1px solid var(--border-color); background:var(--bg-dark);">
                                            <img src="<%= img %>" alt="<%= name %>" style="width:100%; height:100%; object-fit:cover;">
                                        </div>
                                        <div style="font-size:0.65rem; color:var(--text-muted); font-weight:700; margin-top:4px; text-align:center;">#<%= id %></div>
                                    </td>
                                    
                                    <td style="text-align:left; vertical-align:middle;">
                                        <div style="font-size:0.7rem; font-weight:700; color:var(--gold); letter-spacing:1px; text-transform:uppercase;"><%= cat %></div>
                                        <div style="font-weight:600; font-size:0.95rem; color:var(--burgundy); font-family:'Playfair Display', serif;"><%= name %></div>
                                        <div style="font-size:0.75rem; color:var(--text-muted); margin-top:2px;">
                                            <span>SKU: <%= sku != null ? sku : "N/A" %></span>
                                            <% if (brand != null && !brand.trim().isEmpty()) { %>
                                                <span style="margin-left:8px; border-left:1px solid var(--border-light); padding-left:8px;">Brand: <%= brand %></span>
                                            <% } %>
                                        </div>
                                    </td>
                                    
                                    <td style="vertical-align:middle; font-weight:700; font-size:0.95rem; color:var(--text-primary); text-align:left;">
                                        ₹<%= String.format("%.2f", price) %>
                                        <% if (onSale) { %>
                                            <div style="font-size:0.65rem; color:var(--gold); font-weight:700; margin-top:2px;"><i class="fas fa-tags"></i> Promo Active</div>
                                        <% } %>
                                    </td>
                                    
                                    <td style="vertical-align:middle;">
                                        <div style="display:flex; align-items:center; gap:6px;">
                                            <input type="number" id="inline-stock-<%= id %>" value="<%= stock %>" min="0" 
                                                   style="width: 55px; padding: 6px; border-radius: 8px; border: 1px solid var(--border-color); background: var(--bg-dark); color: var(--text-primary); text-align: center; font-size: 0.8rem; outline: none;">
                                            <button type="button" class="btn-gold" onclick="updateStockAsync(<%= id %>)" style="border-radius:8px; padding:6px 10px; font-size:0.7rem; margin:0; line-height:1; letter-spacing:0; text-transform:none;">
                                                Save
                                            </button>
                                        </div>
                                        <div style="font-size:0.7rem; margin-top:4px; font-weight:600; text-align:left; color: <%= (stock == 0) ? "var(--danger)" : ((stock < 10) ? "var(--gold)" : "var(--success)") %>">
                                            <i class="fas <%= (stock == 0) ? "fa-times-circle" : ((stock < 10) ? "fa-exclamation-triangle" : "fa-check-circle") %>" style="margin-right:2px;"></i>
                                            <%= stock == 0 ? "Out of Stock" : (stock < 10 ? "Low Stock: " + stock : "In Stock") %>
                                        </div>
                                    </td>
                                    
                                    <td style="vertical-align:middle; text-align:center; font-size:0.8rem; color:var(--gold); white-space:nowrap;">
                                        <% for (int i = 0; i < rating; i++) { %><i class="fas fa-star" style="font-size:0.7rem;"></i><% } %>
                                        <div style="font-size:0.65rem; color:var(--text-muted); margin-top:2px;"><%= rating %>/5</div>
                                    </td>
                                    
                                    <td style="vertical-align:middle; text-align:center;">
                                        <button type="button" onclick="toggleStatusAsync(<%= id %>)" style="background:none; border:none; cursor:pointer; padding:0;">
                                            <span id="status-badge-<%= id %>" class="status-badge <%= "ACTIVE".equalsIgnoreCase(status) ? "status-completed" : "status-cancelled" %>" style="font-size:0.7rem; padding: 4px 10px; border-radius: 20px; display: inline-block;">
                                                <%= "ACTIVE".equalsIgnoreCase(status) ? "Active" : "Draft" %>
                                            </span>
                                        </button>
                                    </td>
                                    
                                    <td style="vertical-align:middle; text-align:right; padding-right:15px;">
                                        <div style="display:flex; justify-content:flex-end; gap:6px; align-items:center;">
                                            <a href="admin?tab=product-details&id=<%= id %>" class="btn-outline" style="border-radius:6px; padding:6px 10px; font-size:0.75rem; text-transform:none; display:inline-flex; align-items:center; gap:4px;">
                                                <i class="fas fa-edit"></i> Edit
                                            </a>
                                            <button type="button" onclick="deleteProductAsync(<%= id %>, '<%= name.replace("'", "\\'") %>')" style="background:transparent; border:none; color:var(--danger); cursor:pointer; font-size:1rem; padding:6px; display:inline-flex; align-items:center;">
                                                <i class="fas fa-trash-alt"></i>
                                            </button>
                                        </div>
                                    </td>
                                    
                                </tr>
                                <%
                                        }
                                        rs.close();
                                        st.close();
                                        con.close();
                                    } catch (Exception e) {
                                        out.println("<tr><td colspan='8' style='color:var(--danger); padding:20px;'>Error: " + e.getMessage() + "</td></tr>");
                                    }
                                %>
                            </tbody>
                        </table>
                    </div>

                    <!-- Categories Section inside Products tab -->
                    <div style="margin-top:50px; background:var(--bg-card); border:1px solid var(--border-color); border-radius:24px; padding:35px; box-shadow:var(--shadow-lux); text-align:left;">
                        <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:20px; flex-wrap:wrap; gap:15px;">
                            <div>
                                <h3 style="font-size:1.3rem; margin:0; border:none;">Cosmetic Categories</h3>
                                <p style="color:var(--text-muted); font-size:0.8rem; margin-top:5px;">Add or delete catalog category divisions.</p>
                            </div>
                            
                            <form action="AdminServlet" method="POST" style="display:flex; align-items:center; gap:10px;">
                                <input type="hidden" name="action" value="addCategory">
                                <input type="text" name="name" placeholder="Category Name" required style="padding:8px 12px; font-size:0.85rem; border-radius:8px; background:var(--bg-dark); border:1px solid var(--border-color); color:var(--text-primary); width:200px;">
                                <button type="submit" class="btn-gold" style="border-radius:8px; padding:8px 16px; font-size:0.85rem; white-space:nowrap;">
                                    <i class="fas fa-plus" style="margin-right:5px;"></i> Add Category
                                </button>
                            </form>
                        </div>

                        <div style="display:flex; gap:10px; flex-wrap:wrap;">
                            <%
                                try {
                                    Connection con = DBConnection.getConnection();
                                    Statement st = con.createStatement();
                                    ResultSet rs = st.executeQuery("SELECT id, name FROM categories ORDER BY name ASC");
                                    while (rs.next()) {
                                        int catId = rs.getInt("id");
                                        String catName = rs.getString("name");
                            %>
                            <div style="display:inline-flex; align-items:center; gap:10px; background:var(--bg-surface); padding:8px 16px; border-radius:30px; border:1px solid var(--border-color); font-size:0.8rem; font-weight:600; color:var(--text-primary);">
                                <span><%= catName %></span>
                                <form action="AdminServlet" method="POST" style="display:inline-block;" onsubmit="return confirm('Delete category <%= catName %>? All products referencing it will remain but won\'t match search filters.');">
                                    <input type="hidden" name="action" value="deleteCategory">
                                    <input type="hidden" name="id" value="<%= catId %>">
                                    <button type="submit" style="background:transparent; border:none; cursor:pointer; color:var(--danger); font-size:0.85rem; display:inline-flex; align-items:center;"><i class="fas fa-times-circle"></i></button>
                                </form>
                            </div>
                            <%
                                    }
                                    rs.close();
                                    st.close();
                                    con.close();
                                } catch (Exception e) {
                                    out.println("<p style='color:var(--danger);'>Error: " + e.getMessage() + "</p>");
                                }
                            %>
                        </div>
                    </div>

                <% } else if ("orders".equalsIgnoreCase(activeTab)) { %>
                    <!-- ==========================================
                         ORDER FULFILLMENT TAB
                         ========================================== -->
                    <div style="text-align:left; margin-bottom:25px;">
                        <h2 style="font-size:1.6rem; border-bottom:none; margin:0; padding-bottom:0;">Order Fulfillment</h2>
                        <p style="color:var(--text-muted); font-size:0.85rem; margin-top:5px;">Examine transaction histories, delivery details, and alter order progress status.</p>
                    </div>

                    <!-- Search and Filter Row -->
                    <div style="display:flex; justify-content:space-between; align-items:center; gap:20px; margin-bottom:25px; flex-wrap:wrap;">
                        <div class="search-input-wrapper" style="max-width:350px; text-align:left;">
                            <i class="fas fa-search"></i>
                            <input type="text" id="orderSearch" onkeyup="searchOrders()" placeholder="Search by customer name or reference...">
                        </div>
                        <div>
                            <select id="statusFilter" onchange="filterOrders()" style="padding:10px 20px; border-radius:12px; background:var(--bg-card); font-size:0.85rem; min-width:180px;">
                                <option value="ALL">All Statuses</option>
                                <option value="PENDING">Pending</option>
                                <option value="PROCESSING">Processing</option>
                                <option value="SHIPPED">Shipped</option>
                                <option value="DELIVERED">Delivered</option>
                                <option value="CANCELLED">Cancelled</option>
                            </select>
                        </div>
                    </div>

                    <table class="admin-table" id="ordersTable">
                        <thead>
                            <tr>
                                <th>Order Ref</th>
                                <th>Customer</th>
                                <th>Date</th>
                                <th>Address</th>
                                <th>Total Cost</th>
                                <th>Status Badge</th>
                                <th>Update Fulfillment Status</th>
                                <th style="text-align:right;">Fulfillment Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            <%
                                try {
                                    Connection con = DBConnection.getConnection();
                                    Statement st = con.createStatement();
                                    ResultSet rs = st.executeQuery(
                                        "SELECT o.id, o.order_date, o.total_amount, o.status, o.shipping_address, o.cancellation_reason, o.cancellation_date, o.cancelled_by, u.fullname FROM orders o " +
                                        "JOIN users u ON o.user_id = u.id ORDER BY o.order_date DESC"
                                    );
                                    while (rs.next()) {
                                        int id = rs.getInt("id");
                                        Timestamp date = rs.getTimestamp("order_date");
                                        double amt = rs.getDouble("total_amount");
                                        String status = rs.getString("status");
                                        String addr = rs.getString("shipping_address");
                                        String cust = rs.getString("fullname");
                                        
                                        String cancelReason = rs.getString("cancellation_reason");
                                        Timestamp cancelDate = rs.getTimestamp("cancellation_date");
                                        String cancelledBy = rs.getString("cancelled_by");

                                        String badgeClass = "status-pending";
                                        if ("PROCESSING".equalsIgnoreCase(status)) badgeClass = "status-processing";
                                        else if ("SHIPPED".equalsIgnoreCase(status)) badgeClass = "status-shipped";
                                        else if ("DELIVERED".equalsIgnoreCase(status)) badgeClass = "status-completed";
                                        else if ("CANCELLED".equalsIgnoreCase(status)) badgeClass = "status-cancelled";
                            %>
                            <tr class="order-row" data-status="<%= status %>">
                                <td style="font-weight:600; color:var(--gold);" class="order-ref">#LXG-<%= id %></td>
                                <td class="order-customer" style="font-weight:600;"><%= cust %></td>
                                <td style="font-size:0.75rem;"><%= date %></td>
                                <td style="font-size:0.8rem; max-width:180px; white-space:nowrap; overflow:hidden; text-overflow:ellipsis;"><%= addr %></td>
                                <td style="font-weight:600; color:var(--text-primary);">₹<%= String.format("%.2f", amt) %></td>
                                <td><span class="status-badge <%= badgeClass %>"><%= status %></span></td>
                                <td>
                                    <!-- Status Update Dropdown Form -->
                                    <form action="AdminServlet" method="POST" style="display:inline-flex; align-items:center; gap:5px;">
                                        <input type="hidden" name="action" value="updateOrder">
                                        <input type="hidden" name="orderId" value="<%= id %>">
                                        <select name="status" style="padding:6px 12px; font-size:0.75rem; border-radius:8px; min-width:110px; background:var(--bg-dark); border:1px solid var(--border-color); color:var(--text-primary); height:auto;">
                                            <option value="PENDING" <%= "PENDING".equals(status) ? "selected" : "" %>>Pending</option>
                                            <option value="PROCESSING" <%= "PROCESSING".equals(status) ? "selected" : "" %>>Processing</option>
                                            <option value="SHIPPED" <%= "SHIPPED".equals(status) ? "selected" : "" %>>Shipped</option>
                                            <option value="DELIVERED" <%= "DELIVERED".equals(status) ? "selected" : "" %>>Delivered</option>
                                            <option value="CANCELLED" <%= "CANCELLED".equals(status) ? "selected" : "" %>>Cancelled</option>
                                        </select>
                                        <button type="submit" class="btn-gold" style="border-radius:8px; padding:6px 10px; font-size:0.75rem;">
                                            <i class="fas fa-check"></i>
                                        </button>
                                    </form>
                                </td>
                                <td style="text-align:right;">
                                    <div style="display:flex; align-items:center; justify-content:flex-end; gap:5px;">
                                        <button class="btn-outline" style="border-radius:6px; padding:6px 12px; font-size:0.75rem; text-transform:none;" onclick="showOrderDetails(<%= id %>)">
                                            Items
                                        </button>
                                        <% if (!"DELIVERED".equalsIgnoreCase(status) && !"CANCELLED".equalsIgnoreCase(status)) { %>
                                            <form action="AdminServlet" method="POST" style="display:inline-block;" onsubmit="return confirm('Cancel order #LXG-<%= id %>?');">
                                                <input type="hidden" name="action" value="cancelOrder">
                                                <input type="hidden" name="orderId" value="<%= id %>">
                                                <button type="submit" class="btn-outline" style="border-radius:6px; padding:6px 12px; font-size:0.75rem; color:var(--danger); border-color:var(--danger); background:transparent; text-transform:none;">
                                                    Cancel
                                                </button>
                                            </form>
                                        <% } %>
                                    </div>

                                    <!-- Render Hidden Details Block -->
                                    <div id="orderDetails-<%= id %>" style="display:none;">
                                        <div style="margin-bottom:15px; font-size:0.85rem; line-height:1.5;">
                                            <strong>Order Reference:</strong> #LXG-<%= id %><br>
                                            <strong>Customer Name:</strong> <%= cust %><br>
                                            <strong>Fulfillment Status:</strong> <span class="status-badge <%= badgeClass %>" style="font-size:0.65rem; padding:3px 8px;"><%= status %></span><br>
                                            <strong>Order Date:</strong> <%= date %><br>
                                            <strong>Shipping Address:</strong> <%= addr %>
                                        </div>
                                        
                                        <% if ("CANCELLED".equalsIgnoreCase(status) && cancelReason != null) { %>
                                            <div style="margin-bottom:15px; padding:12px; background:rgba(245,108,108,0.1); border:1px solid rgba(245,108,108,0.2); border-radius:10px; font-size:0.8rem; text-align:left; color:#f56c6c; line-height:1.4;">
                                                <i class="fas fa-info-circle"></i> <strong>Cancellation Details:</strong><br>
                                                <strong>Initiated By:</strong> <%= cancelledBy != null ? cancelledBy.toUpperCase() : "UNKNOWN" %><br>
                                                <strong>Date:</strong> <%= cancelDate %><br>
                                                <strong>Reason:</strong> <%= cancelReason %>
                                            </div>
                                        <% } %>

                                        <h4 style="font-family:'Playfair Display', serif; border-bottom:1px solid var(--border-light); padding-bottom:8px; margin-bottom:12px; font-size:1.1rem; color:var(--burgundy);">Purchased Cosmetics</h4>
                                        <div style="max-height:220px; overflow-y:auto; margin-bottom:15px;">
                                        <%
                                            try (Connection innerCon = DBConnection.getConnection();
                                                 PreparedStatement innerPs = innerCon.prepareStatement(
                                                     "SELECT oi.quantity, oi.price, p.name, p.image_url, pv.variant_name FROM order_items oi " +
                                                     "JOIN products p ON oi.product_id = p.id " +
                                                     "LEFT JOIN product_variants pv ON oi.variant_id = pv.id " +
                                                     "WHERE oi.order_id = ?")) {
                                                innerPs.setInt(1, id);
                                                try (ResultSet innerRs = innerPs.executeQuery()) {
                                                    while (innerRs.next()) {
                                                        String vName = innerRs.getString("variant_name");
                                        %>
                                            <div style="display:flex; justify-content:space-between; align-items:center; padding:8px 0; border-bottom:1px solid rgba(0,0,0,0.03);">
                                                <div style="display:flex; align-items:center; gap:10px;">
                                                    <img src="<%= innerRs.getString("image_url") %>" style="width:40px; height:40px; border-radius:6px; object-fit:cover; border:1px solid var(--border-light);">
                                                    <div>
                                                        <div style="font-weight:600; font-size:0.85rem;">
                                                            <%= innerRs.getString("name") %>
                                                            <% if (vName != null && !vName.isEmpty()) { %>
                                                                <span style="font-size:0.7rem; color:var(--gold); font-weight:600;">(Shade: <%= vName %>)</span>
                                                            <% } %>
                                                        </div>
                                                        <div style="font-size:0.75rem; color:var(--text-muted);">Qty: <%= innerRs.getInt("quantity") %> &times; ₹<%= String.format("%.2f", innerRs.getDouble("price")) %></div>
                                                    </div>
                                                </div>
                                                <div style="font-weight:600; font-size:0.85rem;">₹<%= String.format("%.2f", innerRs.getDouble("price") * innerRs.getInt("quantity")) %></div>
                                            </div>
                                        <%
                                                    }
                                                }
                                            } catch (Exception innerEx) {
                                                out.println("<p style='color:var(--danger);'>Error details: " + innerEx.getMessage() + "</p>");
                                            }
                                        %>
                                        </div>
                                        <div style="display:flex; justify-content:space-between; font-weight:700; font-size:1.05rem; padding-top:12px; border-top:1px solid var(--border-color); color:var(--burgundy);">
                                            <span>Amount Paid:</span>
                                            <span>₹<%= String.format("%.2f", amt) %></span>
                                        </div>
                                    </div>
                                </td>
                            </tr>
                            <%
                                    }
                                    rs.close();
                                    st.close();
                                    con.close();
                                } catch (Exception e) {
                                    out.println("<tr><td colspan='8' style='color:var(--danger);'>Error: " + e.getMessage() + "</td></tr>");
                                }
                            %>
                        </tbody>
                    </table>

                <% } else if ("users".equalsIgnoreCase(activeTab)) { %>
                    <!-- ==========================================
                         USER MANAGEMENT TAB
                         ========================================== -->
                    <div style="text-align:left; margin-bottom:25px;">
                        <h2 style="font-size:1.6rem; border-bottom:none; margin:0; padding-bottom:0;">User Management</h2>
                        <p style="color:var(--text-muted); font-size:0.85rem; margin-top:5px;">Track registered customer details, alter status toggles, or grant administrative roles.</p>
                    </div>

                    <!-- Search Bar for Users -->
                    <div class="search-input-wrapper" style="margin-bottom:25px; text-align:left;">
                        <i class="fas fa-search"></i>
                        <input type="text" id="userSearch" onkeyup="searchUsersList()" placeholder="Search users by name, username, email, or country...">
                    </div>

                    <table class="admin-table" id="usersTable">
                        <thead>
                            <tr>
                                <th>ID</th>
                                <th>Full Name</th>
                                <th>Username</th>
                                <th>Email</th>
                                <th>Phone</th>
                                <th>Country</th>
                                <th>Role</th>
                                <th>Status</th>
                                <th style="text-align:right;">Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            <%
                                try {
                                    int currentAdminId = (Integer) s.getAttribute("user_id");
                                    Connection con = DBConnection.getConnection();
                                    Statement st = con.createStatement();
                                    ResultSet rs = st.executeQuery("SELECT id, fullname, username, email, phone, country_name, role, enabled FROM users ORDER BY id DESC");
                                    while (rs.next()) {
                                        int id = rs.getInt("id");
                                        String name = rs.getString("fullname");
                                        String username = rs.getString("username");
                                        String email = rs.getString("email");
                                        String phone = rs.getString("phone");
                                        String country = rs.getString("country_name");
                                        String role = rs.getString("role");
                                        int enabled = rs.getInt("enabled");
                            %>
                            <tr class="user-row">
                                <td style="font-weight:600; color:var(--gold);">#<%= id %></td>
                                <td style="font-weight:600;" class="user-fullname"><%= name %></td>
                                <td class="user-username"><%= username %></td>
                                <td class="user-email"><%= email %></td>
                                <td><%= (phone != null) ? phone : "-" %></td>
                                <td class="user-country"><%= (country != null) ? country : "-" %></td>
                                <td>
                                    <span style="font-size:0.75rem; font-weight:700; color: <%= "ADMIN".equalsIgnoreCase(role) ? "var(--gold)" : "var(--text-secondary)" %>; background: <%= "ADMIN".equalsIgnoreCase(role) ? "var(--burgundy-glow)" : "rgba(0,0,0,0.03)" %>; padding: 4px 10px; border-radius:10px; border: 1px solid <%= "ADMIN".equalsIgnoreCase(role) ? "var(--border-color)" : "rgba(0,0,0,0.05)" %>">
                                        <%= role %>
                                    </span>
                                </td>
                                <td>
                                    <span class="status-badge <%= enabled == 1 ? "status-completed" : "status-cancelled" %>">
                                        <%= enabled == 1 ? "Active" : "Disabled" %>
                                    </span>
                                </td>
                                <td style="text-align:right;">
                                    <% if (id != currentAdminId) { %>
                                        <form action="AdminServlet" method="POST" style="display:inline-block;" onsubmit="return confirm('Toggle status for <%= name %>?');">
                                            <input type="hidden" name="action" value="toggleUser">
                                            <input type="hidden" name="userId" value="<%= id %>">
                                            <button type="submit" class="btn-outline" style="border-radius:6px; padding:6px 12px; font-size:0.75rem; text-transform:none;">
                                                Toggle Status
                                            </button>
                                        </form>
                                        <form action="AdminServlet" method="POST" style="display:inline-block;" onsubmit="return confirm('Toggle administrator privileges for <%= name %>?');">
                                            <input type="hidden" name="action" value="toggleRole">
                                            <input type="hidden" name="userId" value="<%= id %>">
                                            <button type="submit" class="btn-outline" style="border-radius:6px; padding:6px 12px; font-size:0.75rem; color:var(--gold); border-color:var(--gold); background:transparent; text-transform:none; margin-left:4px;">
                                                Toggle Admin Privilege
                                            </button>
                                        </form>
                                    <% } else { %>
                                        <span style="font-size:0.75rem; color:var(--text-muted); font-style:italic; padding-right:15px;">Self Account</span>
                                    <% } %>
                                </td>
                            </tr>
                            <%
                                    }
                                    rs.close();
                                    st.close();
                                    con.close();
                                } catch (Exception e) {
                                    out.println("<tr><td colspan='9' style='color:var(--danger);'>Error: " + e.getMessage() + "</td></tr>");
                                }
                            %>
                        </tbody>
                    </table>

                <% } else if ("reports".equalsIgnoreCase(activeTab)) { %>
                    <!-- ==========================================
                         SALES REPORTS TAB
                         ========================================== -->
                    <div style="text-align:left; margin-bottom:25px;">
                        <h2 style="font-size:1.6rem; border-bottom:none; margin:0; padding-bottom:0;">Revenue Analytics Report</h2>
                        <p style="color:var(--text-muted); font-size:0.85rem; margin-top:5px;">Detailed metrics on revenue channels and sales performance.</p>
                    </div>

                    <div style="display:grid; grid-template-columns:1.5fr 1fr; gap:30px; margin-top:20px; text-align:left;">
                        
                        <!-- Monthly trends charts -->
                        <div style="background:var(--bg-card); border:1px solid var(--border-color); border-radius:24px; padding:30px; box-shadow:var(--shadow-lux);">
                            <h3 style="font-size:1.3rem; margin-bottom:20px; border:none;">Sales Revenue Trajectories</h3>
                            <div style="position:relative; height:320px;">
                                <canvas id="monthlySalesChart"></canvas>
                            </div>
                        </div>

                        <!-- Best selling products chart -->
                        <div style="background:var(--bg-card); border:1px solid var(--border-color); border-radius:24px; padding:30px; box-shadow:var(--shadow-lux);">
                            <h3 style="font-size:1.3rem; margin-bottom:20px; border:none;">Top-Selling Beauty Formulas</h3>
                            <div style="position:relative; height:320px;">
                                <canvas id="bestSellersChart"></canvas>
                            </div>
                        </div>

                    </div>

                    <!-- Detailed monthly sales table breakdown -->
                    <div style="margin-top:40px; text-align:left;">
                        <h3 style="font-size:1.3rem; margin-bottom:15px; border:none;">Historical Revenue Matrix</h3>
                        <table class="admin-table" style="margin-top:0;">
                            <thead>
                                <tr>
                                    <th>Reporting Month</th>
                                    <th>Transaction Orders</th>
                                    <th>Total Gross Sales (₹)</th>
                                    <th>Average Order Value</th>
                                </tr>
                            </thead>
                            <tbody>
                                <%
                                    if (monthlySalesList != null && !monthlySalesList.isEmpty()) {
                                        for (Map<String, Object> stat : monthlySalesList) {
                                            String month = (String) stat.get("month");
                                            int count = (Integer) stat.get("orders");
                                            double sales = (Double) stat.get("sales");
                                            double aov = count > 0 ? sales / count : 0.0;
                                %>
                                <tr>
                                    <td style="font-weight:600; color:var(--burgundy);"><%= month %></td>
                                    <td><%= count %> orders</td>
                                    <td style="font-weight:600;">₹<%= String.format("%.2f", sales) %></td>
                                    <td>₹<%= String.format("%.2f", aov) %></td>
                                </tr>
                                <%
                                        }
                                    } else {
                                %>
                                <tr>
                                    <td colspan="4" style="text-align:center; padding:20px; color:var(--text-muted);">No monthly data registered yet.</td>
                                </tr>
                                <%
                                    }
                                %>
                            </tbody>
                        </table>
                    </div>

                <% } else if ("settings".equalsIgnoreCase(activeTab)) { %>
                    <!-- ==========================================
                         SYSTEM SETTINGS TAB
                         ========================================== -->
                    <div style="text-align:left; margin-bottom:25px;">
                        <h2 style="font-size:1.6rem; border-bottom:none; margin:0; padding-bottom:0;">System Settings</h2>
                        <p style="color:var(--text-muted); font-size:0.85rem; margin-top:5px;">Configure variables, database credentials, and review user inquiries.</p>
                    </div>

                    <div style="display:grid; grid-template-columns:1.5fr 1fr; gap:30px; text-align:left;">
                        
                        <!-- Client Communications Log -->
                        <div>
                            <h3 style="font-size:1.3rem; margin-bottom:15px; border:none;">Client Communications Log</h3>
                            <table class="admin-table" style="margin-top:0;">
                                <thead>
                                    <tr>
                                        <th>Sender</th>
                                        <th>Email</th>
                                        <th>Subject</th>
                                        <th>Date Submitted</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <%
                                        try (Connection con = DBConnection.getConnection();
                                             Statement st = con.createStatement();
                                             ResultSet rs = st.executeQuery("SELECT name, email, subject, message, created_at FROM contact_messages ORDER BY created_at DESC LIMIT 6")) {
                                            
                                            boolean hasMsgs = false;
                                            while (rs.next()) {
                                                hasMsgs = true;
                                                String name = rs.getString("name");
                                                String email = rs.getString("email");
                                                String subject = rs.getString("subject");
                                                String message = rs.getString("message");
                                                Timestamp date = rs.getTimestamp("created_at");
                                    %>
                                    <tr>
                                        <td style="font-weight:600;"><%= name %></td>
                                        <td><a href="mailto:<%= email %>" style="text-decoration:underline; color:var(--burgundy);"><%= email %></a></td>
                                        <td style="color:var(--gold); font-weight:600; cursor:pointer;" onclick="alert('Message details:\n\n<%= message.replace("'", "\\'") %>')"><%= subject %> <i class="far fa-eye" style="margin-left:5px; font-size:0.8rem;"></i></td>
                                        <td style="font-size:0.75rem;"><%= date %></td>
                                    </tr>
                                    <%
                                             }
                                             if (!hasMsgs) {
                                    %>
                                    <tr>
                                        <td colspan="4" style="text-align:center; padding:30px; color:var(--text-muted);">No concierge inquiries in mailbox.</td>
                                    </tr>
                                    <%
                                             }
                                        } catch (Exception e) {
                                            out.println("<tr><td colspan='4' style='color:var(--danger);'>Error: " + e.getMessage() + "</td></tr>");
                                        }
                                    %>
                                </tbody>
                            </table>
                        </div>

                        <!-- System Parameters -->
                        <div style="background:var(--bg-card); border:1px solid var(--border-color); border-radius:24px; padding:30px; box-shadow:var(--shadow-lux); height:fit-content;">
                            <h3 style="font-size:1.3rem; margin-bottom:20px; border:none;">Portal Configurations</h3>
                            
                            <div style="font-size:0.85rem; display:flex; flex-direction:column; gap:15px; color:var(--text-secondary);">
                                <div>
                                    <strong>E-commerce Brand:</strong> LuxeGlow Premium
                                </div>
                                <div style="border-top:1px solid var(--border-light); padding-top:10px;">
                                    <strong>Active Database:</strong> MySQL (luxeglow)
                                </div>
                                <div style="border-top:1px solid var(--border-light); padding-top:10px;">
                                    <strong>Connection Host:</strong> localhost:3306
                                </div>
                                <div style="border-top:1px solid var(--border-light); padding-top:10px;">
                                    <strong>Application Version:</strong> 1.0.0-SNAPSHOT
                                </div>
                                <div style="border-top:1px solid var(--border-light); padding-top:10px;">
                                    <strong>Server Gateway:</strong> Tomcat 10.1
                                </div>
                                <div style="border-top:1px solid var(--border-light); padding-top:10px;">
                                    <strong>Logged Security ID:</strong> #<%= s.getAttribute("user_id") %>
                                </div>
                                <div style="border-top:1px solid var(--border-light); padding-top:15px; display:flex; gap:10px;">
                                    <a href="email-diagnostics.jsp" class="btn-gold" style="border-radius:8px; padding:8px 16px; font-size:0.75rem; text-decoration:none; flex-grow:1;">
                                        <i class="fas fa-toolbox"></i> Email Diagnostics
                                    </a>
                                </div>
                            </div>
                        </div>

                        <!-- Announcement Banner Card -->
                        <div style="background:var(--bg-card); border:1px solid var(--border-color); border-radius:24px; padding:30px; box-shadow:var(--shadow-lux); height:fit-content;">
                            <h3 style="font-size:1.3rem; margin-bottom:20px; border:none; color:var(--burgundy); font-family:'Playfair Display', serif;">Announcement Notice Banner</h3>
                            <%
                                String annText = "";
                                int annActive = 0;
                                String annStart = "";
                                String annEnd = "";
                                try (Connection innerCon = DBConnection.getConnection();
                                     Statement innerSt = innerCon.createStatement();
                                     ResultSet rsAnn = innerSt.executeQuery("SELECT text, is_active, start_date, end_date FROM announcements LIMIT 1")) {
                                    if (rsAnn.next()) {
                                        annText = rsAnn.getString("text");
                                        annActive = rsAnn.getInt("is_active");
                                        Timestamp startTs = rsAnn.getTimestamp("start_date");
                                        if (startTs != null) annStart = startTs.toString().replace(" ", "T").substring(0, 16);
                                        Timestamp endTs = rsAnn.getTimestamp("end_date");
                                        if (endTs != null) annEnd = endTs.toString().replace(" ", "T").substring(0, 16);
                                    }
                                } catch (Exception e) {
                                    e.printStackTrace();
                                }
                            %>
                            <form action="AdminServlet" method="POST">
                                <input type="hidden" name="action" value="updateAnnouncement">
                                
                                <div class="form-group" style="text-align:left; margin-bottom:15px;">
                                    <label style="font-size:0.8rem; font-weight:600; display:block; margin-bottom:5px;">Banner Text Notice</label>
                                    <input type="text" name="text" value="<%= annText %>" placeholder="E.g. Free shipping on orders over ₹2000!" required style="width:100%; padding:8px 12px; border-radius:8px; border:1px solid var(--border-color); background:var(--bg-dark); color:var(--text-primary);">
                                </div>
                                
                                <div style="display:grid; grid-template-columns: 1fr 1fr; gap:15px; margin-bottom:15px;">
                                    <div class="form-group" style="text-align:left; margin-bottom:0;">
                                        <label style="font-size:0.8rem; font-weight:600; display:block; margin-bottom:5px;">Start Date</label>
                                        <input type="datetime-local" name="startDate" value="<%= annStart %>" style="width:100%; padding:8px 12px; border-radius:8px; border:1px solid var(--border-color); background:var(--bg-dark); color:var(--text-primary);">
                                    </div>
                                    <div class="form-group" style="text-align:left; margin-bottom:0;">
                                        <label style="font-size:0.8rem; font-weight:600; display:block; margin-bottom:5px;">End Date</label>
                                        <input type="datetime-local" name="endDate" value="<%= annEnd %>" style="width:100%; padding:8px 12px; border-radius:8px; border:1px solid var(--border-color); background:var(--bg-dark); color:var(--text-primary);">
                                    </div>
                                </div>

                                <div class="form-group" style="text-align:left; margin-bottom:15px;">
                                    <label style="font-size:0.8rem; font-weight:600; display:block; margin-bottom:5px;">Banner Status</label>
                                    <select name="isActive" required style="width:100%; padding:8px 12px; border-radius:8px; border:1px solid var(--border-color); background:var(--bg-dark); color:var(--text-primary);">
                                        <option value="1" <%= annActive == 1 ? "selected" : "" %>>Active (Show Banner)</option>
                                        <option value="0" <%= annActive == 0 ? "selected" : "" %>>Inactive (Hide Banner)</option>
                                    </select>
                                </div>

                                <button type="submit" class="btn-gold" style="width:100%; border-radius:8px; padding:10px; font-size:0.85rem; font-weight:600;">
                                    Apply Notice Banner Update
                                </button>
                            </form>
                        </div>

                    </div>
                <% } else if ("product-details".equalsIgnoreCase(activeTab)) { %>
                    <!-- ==========================================
                         PRODUCT DETAILS WORKSPACE TAB (REDESIGNED)
                         ========================================== -->
                    <%
                        String pName = "", pDesc = "", pCat = "", pImg = "", pBrand = "", pSku = "", pStatus = "", pMetaTitle = "", pMetaDesc = "", pMetaKeywords = "";
                        double pPrice = 0.0;
                        int pStock = 0, pRating = 5;
                        if (prodId > 0) {
                            try (Connection con = DBConnection.getConnection();
                                 PreparedStatement ps = con.prepareStatement("SELECT * FROM products WHERE id = ?")) {
                                ps.setInt(1, prodId);
                                try (ResultSet rs = ps.executeQuery()) {
                                    if (rs.next()) {
                                        pName = rs.getString("name");
                                        pDesc = rs.getString("description");
                                        pPrice = rs.getDouble("price");
                                        pCat = rs.getString("category");
                                        pImg = rs.getString("image_url");
                                        pStock = rs.getInt("stock");
                                        pRating = rs.getInt("rating");
                                        pBrand = rs.getString("brand");
                                        pSku = rs.getString("sku");
                                        pStatus = rs.getString("status");
                                        pMetaTitle = rs.getString("meta_title");
                                        pMetaDesc = rs.getString("meta_description");
                                        pMetaKeywords = rs.getString("meta_keywords");
                                    }
                                }
                            } catch (Exception e) {
                                e.printStackTrace();
                            }
                        }
                    %>
                    <div style="text-align:left; margin-bottom:25px;">
                        <a href="admin?tab=products" class="btn-outline" style="padding:8px 16px; border-radius:8px; text-decoration:none; font-size:0.85rem; display:inline-block;">
                            <i class="fas fa-arrow-left" style="margin-right:8px;"></i> Back to Catalog
                        </a>
                        <h2 style="font-size:1.8rem; border-bottom:none; margin:15px 0 0 0; padding-bottom:0; font-family:'Playfair Display', serif;">
                            Manage Product: <span style="color:var(--gold);" id="detailsProductNameHeader"><%= pName %></span>
                        </h2>
                    </div>

                    <div style="display:grid; grid-template-columns: 1.2fr 1fr; gap:30px; text-align:left; margin-top:20px;">
                        <!-- Left Column: Master Form (Specifications & SEO) -->
                        <div style="display:flex; flex-direction:column; gap:25px;">
                            <!-- Card 1: Specifications & SEO -->
                            <div style="background:var(--bg-card); border:1px solid var(--border-color); border-radius:24px; padding:30px; box-shadow:var(--shadow-lux);">
                                <h3 style="font-size:1.2rem; border:none; margin-top:0; margin-bottom:20px; color:var(--burgundy); font-family:'Playfair Display', serif;">Product Specifications & SEO</h3>
                                
                                <form onsubmit="saveSpecifications(event)" enctype="multipart/form-data">
                                    <input type="hidden" name="action" value="edit">
                                    <input type="hidden" name="id" value="<%= prodId %>">
                                    <input type="hidden" name="redirectTab" value="product-details">
                                    
                                    <div class="form-group">
                                        <label>Product Name</label>
                                        <input type="text" name="name" value="<%= pName %>" required style="width:100%;">
                                    </div>
                                    
                                    <div class="form-group">
                                        <label>Description</label>
                                        <textarea name="description" rows="4" required style="width:100%; resize:vertical;"><%= pDesc %></textarea>
                                    </div>

                                    <div style="display:grid; grid-template-columns:1fr 1fr; gap:15px;">
                                        <div class="form-group">
                                            <label>Price (₹)</label>
                                            <input type="number" step="0.01" name="price" value="<%= pPrice %>" required>
                                        </div>
                                        <div class="form-group">
                                            <label>Category</label>
                                            <select name="category" required>
                                                <% for (String catName : categoriesList) { %>
                                                    <option value="<%= catName %>" <%= catName.equals(pCat) ? "selected" : "" %>><%= catName %></option>
                                                <% } %>
                                            </select>
                                        </div>
                                    </div>

                                    <div style="display:grid; grid-template-columns:1fr 1fr; gap:15px;">
                                        <div class="form-group">
                                            <label>Brand</label>
                                            <input type="text" name="brand" value="<%= pBrand != null ? pBrand : "LuxeGlow" %>" required>
                                        </div>
                                        <div class="form-group">
                                            <label>SKU Code</label>
                                            <input type="text" name="sku" value="<%= pSku != null ? pSku : "" %>" placeholder="e.g. LG-PRD-001">
                                        </div>
                                    </div>

                                    <div style="display:grid; grid-template-columns:1fr 1fr; gap:15px;">
                                        <div class="form-group">
                                            <label>Stock Qty (Main)</label>
                                            <input type="number" name="stock" value="<%= pStock %>" required min="0">
                                        </div>
                                        <div class="form-group">
                                            <label>Star Rating</label>
                                            <input type="number" name="rating" min="1" max="5" value="<%= pRating %>" required>
                                        </div>
                                    </div>

                                    <div class="form-group">
                                        <label>Status</label>
                                        <select name="status" required>
                                            <option value="ACTIVE" <%= "ACTIVE".equalsIgnoreCase(pStatus) ? "selected" : "" %>>Active (Visible Storefront)</option>
                                            <option value="DRAFT" <%= "DRAFT".equalsIgnoreCase(pStatus) ? "selected" : "" %>>Draft (Hidden / Inactive)</option>
                                        </select>
                                    </div>

                                    <div class="form-group">
                                        <label>Upload Main Product Photo</label>
                                        <input type="file" name="imageFile" accept="image/*" style="padding:8px 12px; background:transparent; border:1px dashed var(--border-color); cursor:pointer; width:100%;">
                                        <div style="font-size:0.7rem; color:var(--text-muted); margin-top:2px;">Optional. Overrides the text path field below.</div>
                                    </div>

                                    <div class="form-group">
                                        <label>Image Resource Path</label>
                                        <input type="text" name="imageUrl" value="<%= pImg %>" required style="width:100%;">
                                    </div>

                                    <!-- SEO Sub-section -->
                                    <h4 style="font-size:1.05rem; color:var(--gold); border-bottom:1px solid var(--border-light); padding-bottom:5px; margin-top:30px; margin-bottom:15px; font-family:'Playfair Display', serif;">Search Engine Optimization (SEO)</h4>
                                    
                                    <div class="form-group">
                                        <label>Meta Title</label>
                                        <input type="text" name="meta_title" value="<%= pMetaTitle != null ? pMetaTitle : "" %>" placeholder="LuxeGlow Glow Moisturizer - Premium Hydration" style="width:100%;">
                                    </div>

                                    <div class="form-group">
                                        <label>Meta Description</label>
                                        <textarea name="meta_description" rows="2" placeholder="Describe this page for search results..." style="width:100%; resize:vertical;"><%= pMetaDesc != null ? pMetaDesc : "" %></textarea>
                                    </div>

                                    <div class="form-group">
                                        <label>Meta Keywords</label>
                                        <input type="text" name="meta_keywords" value="<%= pMetaKeywords != null ? pMetaKeywords : "" %>" placeholder="moisturizer, hydration, clean beauty" style="width:100%;">
                                    </div>

                                    <button type="submit" class="btn-gold" style="width:100%; border-radius:12px; padding:12px; margin-top:20px; font-weight:600;">
                                        Save All Specifications
                                    </button>
                                </form>
                            </div>
                        </div>

                        <!-- Right Column: Gallery, Variants, Promotions, Reviews -->
                        <div style="display:flex; flex-direction:column; gap:25px;">
                            
                            <!-- Card 2: Variants Configuration & Variant Image Editor -->
                            <div style="background:var(--bg-card); border:1px solid var(--border-color); border-radius:24px; padding:30px; box-shadow:var(--shadow-lux);">
                                <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:15px;">
                                    <h3 style="font-size:1.2rem; border:none; margin:0; color:var(--burgundy); font-family:'Playfair Display', serif;">Product Variants</h3>
                                    <button class="btn-gold" style="padding:6px 12px; font-size:0.75rem; border-radius:6px; text-transform:none;" onclick="openAddVariantModal(<%= prodId %>, '<%= pName.replace("'", "\\'") %>')">
                                        <i class="fas fa-plus-circle"></i> Add Shade / Size
                                    </button>
                                </div>

                                <div id="variantsContainer">
                                    <!-- Loaded dynamically via fetchVariantsList -->
                                </div>
                            </div>

                            <!-- Card 4: Gallery Management Card -->
                            <div style="background:var(--bg-card); border:1px solid var(--border-color); border-radius:24px; padding:30px; box-shadow:var(--shadow-lux);">
                                <h3 style="font-size:1.2rem; border:none; margin-top:0; margin-bottom:10px; color:var(--burgundy); font-family:'Playfair Display', serif;">Cosmetic Gallery Assets</h3>
                                <p style="color:var(--text-muted); font-size:0.75rem; margin-bottom:15px;">Drag & drop to sort. Use "Set Main" to choose the default thumbnail.</p>
                                
                                <form onsubmit="uploadGeneralImages(event)" enctype="multipart/form-data" style="background:rgba(0,0,0,0.01); border:1px solid var(--border-light); padding:15px; border-radius:12px; margin-bottom:20px;">
                                    <input type="hidden" name="action" value="uploadProductImages">
                                    <input type="hidden" name="productId" value="<%= prodId %>">
                                    <input type="hidden" name="redirectTab" value="product-details">
                                    
                                    <div class="form-group" style="margin-bottom:10px;">
                                        <label style="font-size:0.75rem; font-weight:600;">Upload New Photos</label>
                                        <input type="file" name="productImages" accept="image/*" multiple required style="padding:5px; border:1px dashed var(--border-color); width:100%;">
                                    </div>

                                    <button type="submit" class="btn-gold" style="width:100%; padding:8px; font-size:0.8rem; border-radius:8px;">
                                        <i class="fas fa-upload" style="margin-right:5px;"></i> Upload to Gallery
                                    </button>
                                </form>

                                <div id="detailGalleryImagesList" style="max-height: 300px; overflow-y: auto; display:flex; flex-direction:column; gap:10px;">
                                    <!-- Populated dynamically via script on load -->
                                </div>
                            </div>

                            <!-- Associated Discounts Card -->
                            <div style="background:var(--bg-card); border:1px solid var(--border-color); border-radius:24px; padding:30px; box-shadow:var(--shadow-lux);">
                                <h3 style="font-size:1.2rem; border:none; margin-top:0; margin-bottom:15px; color:var(--burgundy); font-family:'Playfair Display', serif;">Associated Discounts</h3>
                                <div style="display:flex; flex-direction:column; gap:10px;">
                                    <%
                                        try (Connection con = DBConnection.getConnection();
                                             PreparedStatement psProms = con.prepareStatement(
                                                 "SELECT * FROM promotions WHERE is_active = 1 " +
                                                 "AND (target_type = 'SITEWIDE' " +
                                                 "OR (target_type = 'PRODUCT' AND target_value = ?) " +
                                                 "OR (target_type = 'CATEGORY' AND target_value = ?) " +
                                                 "OR (target_type = 'BRAND' AND target_value = ?))")) {
                                            psProms.setString(1, String.valueOf(prodId));
                                            psProms.setString(2, pCat);
                                            psProms.setString(3, pBrand);
                                            try (ResultSet rsProms = psProms.executeQuery()) {
                                                boolean hasProms = false;
                                                while (rsProms.next()) {
                                                    hasProms = true;
                                                    String name = rsProms.getString("name");
                                                    String discType = rsProms.getString("discount_type");
                                                    double discAmt = rsProms.getDouble("discount_amount");
                                                    String target = rsProms.getString("target_type");
                                                    String val = rsProms.getString("target_value");
                                    %>
                                    <div style="display:flex; justify-content:space-between; align-items:center; background:rgba(197,171,87,0.03); border:1px solid var(--border-light); padding:10px 15px; border-radius:12px;">
                                        <div>
                                            <div style="font-weight:600; font-size:0.85rem;"><%= name %></div>
                                            <div style="font-size:0.7rem; color:var(--text-muted);">
                                                Target: <%= target %><%= (val != null && !val.isEmpty()) ? " (" + val + ")" : "" %>
                                            </div>
                                        </div>
                                        <div style="font-weight:700; color:var(--burgundy); font-size:0.9rem;">
                                            <%= "PERCENTAGE".equalsIgnoreCase(discType) ? (int)discAmt + "% OFF" : "₹" + String.format("%.2f", discAmt) + " OFF" %>
                                        </div>
                                    </div>
                                    <%
                                                }
                                                if (!hasProms) {
                                    %>
                                    <div style="font-size:0.75rem; color:var(--text-muted); text-align:center; padding:10px;">No promotions active for this item.</div>
                                    <%
                                                }
                                            }
                                        } catch (Exception ex) {
                                            out.println("<p style='color:var(--danger);'>Error: " + ex.getMessage() + "</p>");
                                        }
                                    %>
                                </div>
                            </div>

                            <!-- Product Reviews Card -->
                            <div style="background:var(--bg-card); border:1px solid var(--border-color); border-radius:24px; padding:30px; box-shadow:var(--shadow-lux);">
                                <h3 style="font-size:1.2rem; border:none; margin-top:0; margin-bottom:15px; color:var(--burgundy); font-family:'Playfair Display', serif;">Product Reviews Moderation</h3>
                                <div style="display:flex; flex-direction:column; gap:12px; max-height:350px; overflow-y:auto; padding-right:5px;">
                                    <%
                                        try (Connection con = DBConnection.getConnection();
                                             PreparedStatement psRev = con.prepareStatement(
                                                 "SELECT r.id, u.fullname, r.rating, r.review_text AS comment, r.created_at, r.is_hidden " +
                                                 "FROM reviews r JOIN users u ON r.user_id = u.id WHERE r.product_id = ? ORDER BY r.created_at DESC")) {
                                            psRev.setInt(1, prodId);
                                            try (ResultSet rsRev = psRev.executeQuery()) {
                                                boolean hasReviews = false;
                                                while (rsRev.next()) {
                                                    hasReviews = true;
                                                    int rId = rsRev.getInt("id");
                                                    String rName = rsRev.getString("fullname");
                                                    int rRating = rsRev.getInt("rating");
                                                    String rComment = rsRev.getString("comment");
                                                    Timestamp rDate = rsRev.getTimestamp("created_at");
                                                    int isHidden = rsRev.getInt("is_hidden");
                                    %>
                                    <div style="background:var(--bg-surface); border:1px solid var(--border-light); padding:12px; border-radius:12px; display:flex; flex-direction:column; gap:6px;">
                                        <div style="display:flex; justify-content:space-between; align-items:center;">
                                            <div>
                                                <span style="font-weight:600; font-size:0.8rem;"><%= rName %></span>
                                                <span style="font-size:0.7rem; color:var(--text-muted); margin-left:8px;"><%= rDate %></span>
                                            </div>
                                            <div style="color:var(--gold); font-size:0.75rem;">
                                                <% for (int i = 0; i < rRating; i++) { %><i class="fas fa-star"></i><% } %>
                                            </div>
                                        </div>
                                        <p style="font-size:0.75rem; margin:0; line-height:1.4; color:var(--text-secondary);"><%= rComment %></p>
                                        <div style="display:flex; justify-content:flex-end; gap:6px; margin-top:5px; border-top:1px solid rgba(0,0,0,0.03); padding-top:5px;">
                                            <form action="AdminServlet" method="POST" style="margin:0;">
                                                <input type="hidden" name="action" value="toggleReviewVisibility">
                                                <input type="hidden" name="reviewId" value="<%= rId %>">
                                                <input type="hidden" name="productId" value="<%= prodId %>">
                                                <input type="hidden" name="redirectTab" value="product-details">
                                                <button type="submit" class="btn-outline" style="padding:4px 8px; font-size:0.65rem; border-radius:4px; text-transform:none;">
                                                    <%= isHidden == 1 ? "Unhide" : "Hide" %>
                                                </button>
                                            </form>
                                            <form action="AdminServlet" method="POST" style="margin:0;" onsubmit="return confirm('Permanently delete review by <%= rName %>?');">
                                                <input type="hidden" name="action" value="deleteReviewAdmin">
                                                <input type="hidden" name="reviewId" value="<%= rId %>">
                                                <input type="hidden" name="productId" value="<%= prodId %>">
                                                <input type="hidden" name="redirectTab" value="product-details">
                                                <button type="submit" class="btn-outline" style="padding:4px 8px; font-size:0.65rem; border-radius:4px; color:var(--danger); border-color:var(--danger); background:transparent; text-transform:none;">
                                                    Delete
                                                </button>
                                            </form>
                                        </div>
                                    </div>
                                    <%
                                                }
                                                if (!hasReviews) {
                                    %>
                                    <div style="font-size:0.75rem; color:var(--text-muted); text-align:center; padding:10px;">No reviews found for this cosmetic masterpiece.</div>
                                    <%
                                                }
                                            }
                                        } catch (Exception ex) {
                                            out.println("<p style='color:var(--danger);'>Error: " + ex.getMessage() + "</p>");
                                        }
                                    %>
                                </div>
                            </div>

                        </div>
                    </div>

                 <% } else if ("promotions".equalsIgnoreCase(activeTab)) { %>
                    <!-- ==========================================
                         PROMOTIONS TAB
                         ========================================== -->
                    <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:25px; text-align:left;">
                        <div>
                            <h2 style="font-size:1.6rem; border-bottom:none; margin:0; padding-bottom:0; font-family:'Playfair Display', serif;">Store Promotions</h2>
                            <p style="color:var(--text-muted); font-size:0.85rem; margin-top:5px;">Configure sitewide, brand, category, or product-specific discounts.</p>
                        </div>
                        <button class="btn-gold" style="border-radius:12px; padding:10px 24px;" onclick="openAddPromoModal()">
                            <i class="fas fa-plus" style="margin-right:8px;"></i> Create Promotion
                        </button>
                    </div>

                    <table class="admin-table">
                        <thead>
                            <tr>
                                <th>ID</th>
                                <th>Promo Name</th>
                                <th>Type</th>
                                <th>Discount</th>
                                <th>Target</th>
                                <th>Start Date</th>
                                <th>End Date</th>
                                <th>Status</th>
                                <th style="text-align:right;">Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            <%
                                try {
                                    Connection con = DBConnection.getConnection();
                                    Statement st = con.createStatement();
                                    ResultSet rs = st.executeQuery("SELECT * FROM promotions ORDER BY id DESC");
                                    boolean hasPromos = false;
                                    while (rs.next()) {
                                        hasPromos = true;
                                        int id = rs.getInt("id");
                                        String name = rs.getString("name");
                                        String type = rs.getString("discount_type");
                                        double amt = rs.getDouble("discount_amount");
                                        String target = rs.getString("target_type");
                                        String val = rs.getString("target_value");
                                        Timestamp start = rs.getTimestamp("start_date");
                                        Timestamp end = rs.getTimestamp("end_date");
                                        int active = rs.getInt("is_active");
                            %>
                            <tr>
                                <td style="font-weight:600; color:var(--gold);">#<%= id %></td>
                                <td style="font-weight:600;"><%= name %></td>
                                <td><span style="font-size:0.75rem; text-transform:uppercase;"><%= type %></span></td>
                                <td style="font-weight:600; color:var(--burgundy);"><%= "PERCENTAGE".equalsIgnoreCase(type) ? (int)amt + "%" : "₹" + String.format("%.2f", amt) %></td>
                                <td>
                                    <span style="font-size:0.75rem; font-weight:600; background:rgba(0,0,0,0.03); padding:4px 8px; border-radius:8px;">
                                        <%= target %><%= (val != null && !val.isEmpty()) ? ": " + val : "" %>
                                    </span>
                                </td>
                                <td style="font-size:0.75rem;"><%= start != null ? start.toString().substring(0, 16) : "Immediate" %></td>
                                <td style="font-size:0.75rem;"><%= end != null ? end.toString().substring(0, 16) : "Never Expires" %></td>
                                <td>
                                    <span class="status-badge <%= active == 1 ? "status-completed" : "status-cancelled" %>">
                                        <%= active == 1 ? "Active" : "Inactive" %>
                                    </span>
                                </td>
                                <td style="text-align:right;">
                                    <form action="AdminServlet" method="POST" style="display:inline-block;" onsubmit="return confirm('Delete promotion <%= name %>?');">
                                        <input type="hidden" name="action" value="deletePromotion">
                                        <input type="hidden" name="promotionId" value="<%= id %>">
                                        <button type="submit" class="btn-outline" style="border-radius:6px; padding:6px 12px; font-size:0.75rem; color:var(--danger); border-color:var(--danger); background:transparent; text-transform:none;">
                                            Delete
                                        </button>
                                    </form>
                                </td>
                            </tr>
                            <%
                                    }
                                    if (!hasPromos) {
                            %>
                            <tr>
                                <td colspan="9" style="text-align:center; padding:30px; color:var(--text-muted);">No promotions created yet.</td>
                            </tr>
                            <%
                                    }
                                    rs.close();
                                    st.close();
                                    con.close();
                                } catch (Exception e) {
                                    out.println("<tr><td colspan='9' style='color:var(--danger);'>Error: " + e.getMessage() + "</td></tr>");
                                }
                            %>
                        </tbody>
                    </table>

                 <% } else if ("coupons".equalsIgnoreCase(activeTab)) { %>
                    <!-- ==========================================
                         COUPONS TAB
                         ========================================== -->
                    <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:25px; text-align:left;">
                        <div>
                            <h2 style="font-size:1.6rem; border-bottom:none; margin:0; padding-bottom:0; font-family:'Playfair Display', serif;">Store Coupons</h2>
                            <p style="color:var(--text-muted); font-size:0.85rem; margin-top:5px;">Manage client discount codes, usage limits, and expiration controls.</p>
                        </div>
                        <button class="btn-gold" style="border-radius:12px; padding:10px 24px;" onclick="openAddCouponModal()">
                            <i class="fas fa-plus" style="margin-right:8px;"></i> Create Coupon
                        </button>
                    </div>

                    <table class="admin-table">
                        <thead>
                            <tr>
                                <th>ID</th>
                                <th>Coupon Code</th>
                                <th>Type</th>
                                <th>Discount</th>
                                <th>Min Purchase</th>
                                <th>Usage Limit</th>
                                <th>Times Used</th>
                                <th>Expiry Date</th>
                                <th>Status</th>
                                <th style="text-align:right;">Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            <%
                                try {
                                    Connection con = DBConnection.getConnection();
                                    Statement st = con.createStatement();
                                    ResultSet rs = st.executeQuery("SELECT * FROM coupons ORDER BY id DESC");
                                    boolean hasCoupons = false;
                                    while (rs.next()) {
                                        hasCoupons = true;
                                        int id = rs.getInt("id");
                                        String code = rs.getString("code");
                                        String type = rs.getString("discount_type");
                                        double amt = rs.getDouble("discount_amount");
                                        double min = rs.getDouble("minimum_purchase_amount");
                                        int limit = rs.getInt("usage_limit");
                                        boolean hasLimit = !rs.wasNull();
                                        int count = rs.getInt("usage_count");
                                        Timestamp expiry = rs.getTimestamp("expiry_date");
                                        int active = rs.getInt("is_active");
                            %>
                            <tr>
                                <td style="font-weight:600; color:var(--gold);">#<%= id %></td>
                                <td style="font-weight:700; color:var(--burgundy); font-size:0.95rem; font-family:monospace;"><%= code %></td>
                                <td><span style="font-size:0.75rem; text-transform:uppercase;"><%= type %></span></td>
                                <td style="font-weight:600; color:var(--gold);"><%= "PERCENTAGE".equalsIgnoreCase(type) ? (int)amt + "%" : "₹" + String.format("%.2f", amt) %></td>
                                <td>₹<%= String.format("%.2f", min) %></td>
                                <td><%= hasLimit ? limit : "Unlimited" %></td>
                                <td><%= count %> times</td>
                                <td style="font-size:0.75rem;"><%= expiry != null ? expiry.toString().substring(0, 16) : "Never Expires" %></td>
                                <td>
                                    <form action="AdminServlet" method="POST" style="margin:0; display:inline-block;">
                                        <input type="hidden" name="action" value="toggleCouponStatus">
                                        <input type="hidden" name="couponId" value="<%= id %>">
                                        <button type="submit" class="status-badge <%= active == 1 ? "status-completed" : "status-cancelled" %>" style="border:none; cursor:pointer; font-family:inherit;">
                                            <%= active == 1 ? "Active" : "Inactive" %>
                                        </button>
                                    </form>
                                </td>
                                <td style="text-align:right;">
                                    <form action="AdminServlet" method="POST" style="display:inline-block;" onsubmit="return confirm('Delete coupon <%= code %>?');">
                                        <input type="hidden" name="action" value="deleteCoupon">
                                        <input type="hidden" name="couponId" value="<%= id %>">
                                        <button type="submit" class="btn-outline" style="border-radius:6px; padding:6px 12px; font-size:0.75rem; color:var(--danger); border-color:var(--danger); background:transparent; text-transform:none;">
                                            Delete
                                        </button>
                                    </form>
                                </td>
                            </tr>
                            <%
                                    }
                                    if (!hasCoupons) {
                            %>
                            <tr>
                                <td colspan="10" style="text-align:center; padding:30px; color:var(--text-muted);">No coupon codes registered yet.</td>
                            </tr>
                            <%
                                    }
                                    rs.close();
                                    st.close();
                                    con.close();
                                } catch (Exception e) {
                                    out.println("<tr><td colspan='10' style='color:var(--danger);'>Error: " + e.getMessage() + "</td></tr>");
                                }
                            %>
                        </tbody>
                    </table>

                 <% } else if ("reviews".equalsIgnoreCase(activeTab)) { %>
                    <!-- ==========================================
                         REVIEWS TAB
                         ========================================== -->
                    <div style="text-align:left; margin-bottom:25px;">
                        <h2 style="font-size:1.6rem; border-bottom:none; margin:0; padding-bottom:0; font-family:'Playfair Display', serif;">Reviews Moderation</h2>
                        <p style="color:var(--text-muted); font-size:0.85rem; margin-top:5px;">Audit client product experiences, filter feedback, or moderate visibility.</p>
                    </div>

                    <!-- Search Bar for Reviews -->
                    <div style="display:flex; justify-content:space-between; align-items:center; gap:20px; margin-bottom:25px; flex-wrap:wrap;">
                        <div class="search-input-wrapper" style="max-width:350px; text-align:left; margin-bottom:0; width:100%;">
                            <i class="fas fa-search"></i>
                            <input type="text" id="reviewSearch" onkeyup="searchReviews()" placeholder="Search reviews by customer name, product, or comment...">
                        </div>
                        <div>
                            <select id="reviewFilter" onchange="filterReviews()" style="padding:10px 20px; border-radius:12px; background:var(--bg-card); font-size:0.85rem; min-width:180px; border:1px solid var(--border-color); color:var(--text-primary);">
                                <option value="ALL">All Visibility</option>
                                <option value="VISIBLE">Visible Reviews Only</option>
                                <option value="HIDDEN">Hidden Reviews Only</option>
                            </select>
                        </div>
                    </div>

                    <table class="admin-table" id="reviewsTable">
                        <thead>
                            <tr>
                                <th>ID</th>
                                <th>Product</th>
                                <th>Customer</th>
                                <th>Stars</th>
                                <th style="width:35%;">Comment</th>
                                <th>Submitted</th>
                                <th>Visibility</th>
                                <th style="text-align:right;">Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            <%
                                try {
                                    Connection con = DBConnection.getConnection();
                                    Statement st = con.createStatement();
                                    ResultSet rs = st.executeQuery(
                                        "SELECT r.id, r.product_id, u.fullname, r.rating, r.review_text AS comment, r.created_at, r.is_hidden, p.name AS product_name " +
                                        "FROM reviews r JOIN products p ON r.product_id = p.id JOIN users u ON r.user_id = u.id ORDER BY r.created_at DESC"
                                    );
                                    boolean hasReviews = false;
                                    while (rs.next()) {
                                        hasReviews = true;
                                        int id = rs.getInt("id");
                                        int pId = rs.getInt("product_id");
                                        String pName2 = rs.getString("product_name");
                                        String rName = rs.getString("fullname");
                                        int rRating = rs.getInt("rating");
                                        String rComment = rs.getString("comment");
                                        Timestamp rDate = rs.getTimestamp("created_at");
                                        int isHidden = rs.getInt("is_hidden");
                            %>
                            <tr class="review-row" data-hidden="<%= isHidden %>">
                                <td style="font-weight:600; color:var(--gold);">#<%= id %></td>
                                <td style="font-weight:600;"><a href="admin?tab=product-details&id=<%= pId %>" style="color:inherit;"><%= pName2 %></a></td>
                                <td class="rev-customer" style="font-weight:600;"><%= rName %></td>
                                <td style="color:var(--gold); font-size:0.8rem; white-space:nowrap;">
                                    <% for (int i = 0; i < rRating; i++) { %><i class="fas fa-star"></i><% } %>
                                </td>
                                <td class="rev-comment" style="font-size:0.8rem; line-height:1.4;"><%= rComment %></td>
                                <td style="font-size:0.75rem;"><%= rDate %></td>
                                <td>
                                    <span class="status-badge <%= isHidden == 1 ? "status-cancelled" : "status-completed" %>">
                                        <%= isHidden == 1 ? "Hidden" : "Visible" %>
                                    </span>
                                </td>
                                <td style="text-align:right;">
                                    <div style="display:flex; justify-content:flex-end; gap:6px;">
                                        <form action="AdminServlet" method="POST" style="margin:0;">
                                            <input type="hidden" name="action" value="toggleReviewVisibility">
                                            <input type="hidden" name="reviewId" value="<%= id %>">
                                            <button type="submit" class="btn-outline" style="border-radius:6px; padding:6px 12px; font-size:0.75rem; text-transform:none;">
                                                <%= isHidden == 1 ? "Unhide" : "Hide" %>
                                            </button>
                                        </form>
                                        <form action="AdminServlet" method="POST" style="margin:0;" onsubmit="return confirm('Permanently delete review by <%= rName %>?');">
                                            <input type="hidden" name="action" value="deleteReviewAdmin">
                                            <input type="hidden" name="reviewId" value="<%= id %>">
                                            <button type="submit" class="btn-outline" style="border-radius:6px; padding:6px 12px; font-size:0.75rem; color:var(--danger); border-color:var(--danger); background:transparent; text-transform:none;">
                                                Delete
                                            </button>
                                        </form>
                                    </div>
                                </td>
                            </tr>
                            <%
                                    }
                                    if (!hasReviews) {
                            %>
                            <tr>
                                <td colspan="8" style="text-align:center; padding:30px; color:var(--text-muted);">No reviews written yet.</td>
                            </tr>
                            <%
                                    }
                                    rs.close();
                                    st.close();
                                    con.close();
                                } catch (Exception e) {
                                    out.println("<tr><td colspan='8' style='color:var(--danger);'>Error: " + e.getMessage() + "</td></tr>");
                                }
                            %>
                        </tbody>
                    </table>

                 <% } %>

            </main>
        </div>
    </div>


    <!-- ==========================================
         MODAL 1: ADD PRODUCT
         ========================================== -->
    <div id="addModal" class="modal">
        <div class="modal-content">
            <span class="modal-close" onclick="closeAddModal()">&times;</span>
            <h3 style="font-family:'Playfair Display', serif; font-size:1.5rem; color:var(--gold); border-bottom:1px solid var(--border-light); padding-bottom:8px; margin-bottom:25px; text-align:left;">
                Add Cosmetic Masterpiece
            </h3>
            
            <form action="AdminServlet" method="POST" enctype="multipart/form-data">
                <input type="hidden" name="action" value="add">
                
                <div class="form-group">
                    <label>Product Name</label>
                    <input type="text" name="name" placeholder="Glow Moisturizer" required>
                </div>
                
                <div class="form-group">
                    <label>Description</label>
                    <textarea name="description" rows="3" placeholder="Describe the luxury beauty formula..." required style="resize:vertical;"></textarea>
                </div>

                <div style="display:grid; grid-template-columns:1fr 1fr; gap:15px;">
                    <div class="form-group">
                        <label>Price (₹)</label>
                        <input type="number" step="0.01" name="price" placeholder="1500.00" required>
                    </div>
                    <div class="form-group">
                        <label>Category</label>
                        <select name="category" required>
                            <% for (String catName : categoriesList) { %>
                                <option value="<%= catName %>"><%= catName %></option>
                            <% } %>
                        </select>
                    </div>
                </div>

                <div class="form-group">
                    <label>Upload Product Photo</label>
                    <input type="file" name="imageFile" accept="image/*" style="padding:8px 12px; background:transparent; border:1px dashed var(--border-color); cursor:pointer;">
                    <div style="font-size:0.7rem; color:var(--text-muted); margin-top:2px;">Optional. Overrides the text path field below if selected.</div>
                </div>

                <div class="form-group">
                    <label>Image Resource Path (Fallback)</label>
                    <input type="text" name="imageUrl" placeholder="image/glowserum.jpg" value="image/glowserum.jpg" required>
                </div>

                <div style="display:grid; grid-template-columns:1fr 1fr; gap:15px;">
                    <div class="form-group">
                        <label>Initial Stock Qty</label>
                        <input type="number" name="stock" placeholder="50" required min="0">
                    </div>
                    <div class="form-group">
                        <label>Default Star Rating</label>
                        <input type="number" name="rating" min="1" max="5" value="5" required>
                    </div>
                </div>

                <button type="submit" class="btn-gold" style="width:100%; border-radius:12px; padding:12px; margin-top:10px;">
                    Create Inventory Item
                </button>
            </form>
        </div>
    </div>

    <!-- ==========================================
         MODAL 2: EDIT PRODUCT
         ========================================== -->
    <div id="editModal" class="modal">
        <div class="modal-content">
            <span class="modal-close" onclick="closeEditModal()">&times;</span>
            <h3 style="font-family:'Playfair Display', serif; font-size:1.5rem; color:var(--gold); border-bottom:1px solid var(--border-light); padding-bottom:8px; margin-bottom:25px; text-align:left;">
                Update Cosmetic Specifications
            </h3>
            
            <form action="AdminServlet" method="POST" enctype="multipart/form-data">
                <input type="hidden" name="action" value="edit">
                <input type="hidden" name="id" id="editId">
                
                <div class="form-group">
                    <label>Product Name</label>
                    <input type="text" name="name" id="editName" required>
                </div>
                
                <div class="form-group">
                    <label>Description</label>
                    <textarea name="description" id="editDescription" rows="3" required style="resize:vertical;"></textarea>
                </div>

                <div style="display:grid; grid-template-columns:1fr 1fr; gap:15px;">
                    <div class="form-group">
                        <label>Price (₹)</label>
                        <input type="number" step="0.01" name="price" id="editPrice" required>
                    </div>
                    <div class="form-group">
                        <label>Category</label>
                        <select name="category" id="editCategory" required>
                            <% for (String catName : categoriesList) { %>
                                <option value="<%= catName %>"><%= catName %></option>
                            <% } %>
                        </select>
                    </div>
                </div>

                <div class="form-group">
                    <label>Upload New Product Photo</label>
                    <input type="file" name="imageFile" accept="image/*" style="padding:8px 12px; background:transparent; border:1px dashed var(--border-color); cursor:pointer;">
                    <div style="font-size:0.7rem; color:var(--text-muted); margin-top:2px;">Optional. Leave empty to retain current photo path.</div>
                </div>

                <div class="form-group">
                    <label>Image Resource Path</label>
                    <input type="text" name="imageUrl" id="editImageUrl" required>
                </div>

                <div style="display:grid; grid-template-columns:1fr 1fr; gap:15px;">
                    <div class="form-group">
                        <label>Stock Qty</label>
                        <input type="number" name="stock" id="editStock" required min="0">
                    </div>
                    <div class="form-group">
                        <label>Star Rating</label>
                        <input type="number" name="rating" id="editRating" min="1" max="5" required>
                    </div>
                </div>

                <button type="submit" class="btn-gold" style="width:100%; border-radius:12px; padding:12px; margin-top:10px;">
                    Apply Spec Updates
                </button>
            </form>
        </div>
    </div>

    <!-- ==========================================
         MODAL 3: VIEW ORDER DETAILS
         ========================================== -->
    <div id="orderDetailsModal" class="modal">
        <div class="modal-content" style="max-width:550px;">
            <span class="modal-close" onclick="closeOrderDetailsModal()">&times;</span>
            <h3 style="font-family:'Playfair Display', serif; font-size:1.5rem; color:var(--gold); border-bottom:1px solid var(--border-light); padding-bottom:8px; margin-bottom:20px; text-align:left;">
                Transaction Invoice Details
            </h3>
            <div id="orderDetailsModalBody" style="text-align:left;">
                <!-- Dynamically loaded content -->
            </div>
            <button class="btn-gold" style="width:100%; border-radius:12px; padding:12px; margin-top:20px; text-transform:none;" onclick="closeOrderDetailsModal()">
                Close Invoice
            </button>
        </div>
    </div>

    <!-- ==================================================
         MODAL 4: ADD VARIANT (NEW)
         ================================================== -->
    <div id="addVariantModal" class="modal">
        <div class="modal-content" style="max-width: 480px;">
            <span class="modal-close" onclick="closeAddVariantModal()">&times;</span>
            <h3 style="font-family:'Playfair Display', serif; font-size:1.4rem; color:var(--gold); border-bottom:1px solid var(--border-light); padding-bottom:8px; margin-bottom:20px; text-align:left;">
                Add Product Variant
            </h3>
            <form action="AdminServlet" method="POST" enctype="multipart/form-data">
                <input type="hidden" name="action" value="addVariant">
                <input type="hidden" name="productId" id="addVarProductId">
                <input type="hidden" name="redirectTab" id="addVarRedirectTab">
                
                <div class="form-group">
                    <label>Variant / Shade Name</label>
                    <input type="text" name="name" placeholder="e.g. Ruby Red or 50ml" required>
                </div>

                <div class="form-group">
                    <label>Color Code / Custom Label</label>
                    <input type="text" name="colorCode" placeholder="e.g. #E0115F or Standard" required>
                    <div style="font-size:0.7rem; color:var(--text-muted); margin-top:2px;">Use standard hex code starting with # for color swatch, or any text label for pills.</div>
                </div>

                <div style="display:grid; grid-template-columns: 1fr 1fr; gap:15px;">
                    <div class="form-group">
                        <label>Stock Quantity</label>
                        <input type="number" name="stock" placeholder="50" min="0" required>
                    </div>
                    <div class="form-group">
                        <label>Price Override (Optional)</label>
                        <input type="number" step="0.01" name="price" placeholder="Leave blank to use default">
                    </div>
                </div>

                <div class="form-group">
                    <label>Upload Variant-Specific Photos</label>
                    <input type="file" name="variantImages" accept="image/*" multiple style="padding:8px; border: 1px dashed var(--border-color); width: 100%;">
                    <div style="font-size:0.7rem; color:var(--text-muted); margin-top:2px;">Select one or multiple photos for this shade/variant.</div>
                </div>

                <button type="submit" class="btn-gold" style="width:100%; border-radius:12px; padding:12px; margin-top:10px;">
                    Save Product Variant
                </button>
            </form>
        </div>
    </div>

    <!-- ==================================================
         MODAL 5: EDIT VARIANT (NEW)
         ================================================== -->
    <div id="editVariantModal" class="modal">
        <div class="modal-content" style="max-width: 480px;">
            <span class="modal-close" onclick="closeEditVariantModal()">&times;</span>
            <h3 style="font-family:'Playfair Display', serif; font-size:1.4rem; color:var(--gold); border-bottom:1px solid var(--border-light); padding-bottom:8px; margin-bottom:20px; text-align:left;">
                Edit Product Variant
            </h3>
            <form action="AdminServlet" method="POST" enctype="multipart/form-data">
                <input type="hidden" name="action" value="editVariant">
                <input type="hidden" name="variantId" id="editVarVariantId">
                <input type="hidden" name="productId" id="editVarProductId">
                <input type="hidden" name="redirectTab" id="editVarRedirectTab">
                
                <div class="form-group">
                    <label>Variant / Shade Name</label>
                    <input type="text" name="name" id="editVarName" required>
                </div>

                <div class="form-group">
                    <label>Color Code / Custom Label</label>
                    <input type="text" name="colorCode" id="editVarColor" required>
                    <div style="font-size:0.7rem; color:var(--text-muted); margin-top:2px;">E.g. #E0115F or Standard.</div>
                </div>

                <div style="display:grid; grid-template-columns: 1fr 1fr; gap:15px;">
                    <div class="form-group">
                        <label>Stock Quantity</label>
                        <input type="number" name="stock" id="editVarStock" min="0" required>
                    </div>
                    <div class="form-group">
                        <label>Price Override (Optional)</label>
                        <input type="number" step="0.01" name="price" id="editVarPrice" placeholder="Default price">
                    </div>
                </div>

                <div class="form-group">
                    <label>Upload More Variant-Specific Photos</label>
                    <input type="file" name="variantImages" accept="image/*" multiple style="padding:8px; border: 1px dashed var(--border-color); width: 100%;">
                    <div style="font-size:0.7rem; color:var(--text-muted); margin-top:2px;">Add more variant-specific images.</div>
                </div>

                <button type="submit" class="btn-gold" style="width:100%; border-radius:12px; padding:12px; margin-top:10px;">
                    Apply Variant Updates
                </button>
            </form>
        </div>
    </div>

    <!-- ==================================================
         MODAL 6: MANAGE GALLERY (NEW)
         ================================================== -->
    <div id="manageGalleryModal" class="modal">
        <div class="modal-content" style="max-width: 650px;">
            <span class="modal-close" onclick="closeManageGalleryModal()">&times;</span>
            <h3 style="font-family:'Playfair Display', serif; font-size:1.4rem; color:var(--gold); border-bottom:1px solid var(--border-light); padding-bottom:8px; margin-bottom:20px; text-align:left;">
                Image Gallery: <span id="galleryProductName" style="color:var(--burgundy);"></span>
            </h3>
            
            <div style="display:grid; grid-template-columns: 1fr 1fr; gap:20px; text-align:left;">
                <!-- Left: Upload Form -->
                <div>
                    <h4 style="margin-top:0; border:none; font-size:1rem; margin-bottom:10px; color:var(--text-primary);">Upload New Images</h4>
                    <form action="AdminServlet" method="POST" enctype="multipart/form-data" style="background:rgba(0,0,0,0.01); border:1px solid var(--border-light); padding:15px; border-radius:12px;">
                        <input type="hidden" name="action" value="uploadProductImages">
                        <input type="hidden" name="productId" id="galleryProductId">
                        
                        <div class="form-group">
                            <label style="font-size:0.8rem; font-weight:600; display:block; margin-bottom:5px;">Select Photos</label>
                            <input type="file" name="productImages" accept="image/*" multiple required style="padding:5px; border:1px dashed var(--border-color); width:100%;">
                            <div style="font-size:0.65rem; color:var(--text-muted); margin-top:2px;">Select one or multiple images to add to the general product gallery.</div>
                        </div>

                        <button type="submit" class="btn-gold" style="width:100%; padding:10px; font-size:0.8rem; border-radius:8px; margin-top:10px;">
                            Upload to Gallery
                        </button>
                    </form>
                </div>
                
                <!-- Right: Active Images List -->
                <div>
                    <h4 style="margin-top:0; border:none; font-size:1rem; margin-bottom:10px; color:var(--text-primary);">Gallery Image Assets</h4>
                    <div id="galleryImagesList" style="max-height: 280px; overflow-y: auto; display:flex; flex-direction:column; gap:10px; padding-right:5px;">
                        <!-- Populate dynamically via Ajax or rendered content -->
                    </div>
                </div>
            </div>
            
            <button class="btn-gold" style="width:100%; border-radius:12px; padding:12px; margin-top:25px;" onclick="closeManageGalleryModal()">
                Close Gallery
            </button>
        </div>
    </div>

    <!-- ==================================================
         MODAL 7: ADD PROMOTION (NEW)
         ================================================== -->
    <div id="addPromotionModal" class="modal">
        <div class="modal-content" style="max-width: 480px;">
            <span class="modal-close" onclick="closeAddPromoModal()">&times;</span>
            <h3 style="font-family:'Playfair Display', serif; font-size:1.4rem; color:var(--gold); border-bottom:1px solid var(--border-light); padding-bottom:8px; margin-bottom:20px; text-align:left;">
                Create New Promotion
            </h3>
            <form action="AdminServlet" method="POST">
                <input type="hidden" name="action" value="addPromotion">
                
                <div class="form-group" style="text-align:left; margin-bottom:15px;">
                    <label style="font-size:0.8rem; font-weight:600; display:block; margin-bottom:5px;">Promotion Campaign Name</label>
                    <input type="text" name="name" placeholder="E.g. Summer Glow Fest" required style="width:100%; padding:8px 12px; border-radius:8px; border:1px solid var(--border-color); background:var(--bg-dark); color:var(--text-primary);">
                </div>

                <div style="display:grid; grid-template-columns: 1fr 1fr; gap:15px; margin-bottom:15px;">
                    <div class="form-group" style="text-align:left; margin-bottom:0;">
                        <label style="font-size:0.8rem; font-weight:600; display:block; margin-bottom:5px;">Discount Type</label>
                        <select name="discountType" required style="width:100%; padding:8px 12px; border-radius:8px; border:1px solid var(--border-color); background:var(--bg-dark); color:var(--text-primary);">
                            <option value="PERCENTAGE">Percentage (%)</option>
                            <option value="FIXED">Fixed Amount (₹)</option>
                        </select>
                    </div>
                    <div class="form-group" style="text-align:left; margin-bottom:0;">
                        <label style="font-size:0.8rem; font-weight:600; display:block; margin-bottom:5px;">Discount Value</label>
                        <input type="number" step="0.01" name="discountAmount" placeholder="E.g. 15.00" required style="width:100%; padding:8px 12px; border-radius:8px; border:1px solid var(--border-color); background:var(--bg-dark); color:var(--text-primary);">
                    </div>
                </div>

                <div style="display:grid; grid-template-columns: 1fr 1fr; gap:15px; margin-bottom:15px;">
                    <div class="form-group" style="text-align:left; margin-bottom:0;">
                        <label style="font-size:0.8rem; font-weight:600; display:block; margin-bottom:5px;">Target Scope</label>
                        <select name="targetType" id="promoTargetType" onchange="togglePromoTargetValue()" required style="width:100%; padding:8px 12px; border-radius:8px; border:1px solid var(--border-color); background:var(--bg-dark); color:var(--text-primary);">
                            <option value="SITEWIDE">Sitewide</option>
                            <option value="PRODUCT">Specific Product ID</option>
                            <option value="CATEGORY">Specific Category</option>
                            <option value="BRAND">Specific Brand</option>
                        </select>
                    </div>
                    <div class="form-group" style="text-align:left; margin-bottom:0;">
                        <label style="font-size:0.8rem; font-weight:600; display:block; margin-bottom:5px;">Target Value</label>
                        <input type="text" name="targetValue" id="promoTargetValue" placeholder="Leave empty for Sitewide" disabled style="width:100%; padding:8px 12px; border-radius:8px; border:1px solid var(--border-color); background:var(--bg-dark); color:var(--text-primary);">
                    </div>
                </div>

                <div style="display:grid; grid-template-columns: 1fr 1fr; gap:15px; margin-bottom:15px;">
                    <div class="form-group" style="text-align:left; margin-bottom:0;">
                        <label style="font-size:0.8rem; font-weight:600; display:block; margin-bottom:5px;">Start Date</label>
                        <input type="datetime-local" name="startDate" style="width:100%; padding:8px 12px; border-radius:8px; border:1px solid var(--border-color); background:var(--bg-dark); color:var(--text-primary);">
                    </div>
                    <div class="form-group" style="text-align:left; margin-bottom:0;">
                        <label style="font-size:0.8rem; font-weight:600; display:block; margin-bottom:5px;">End Date</label>
                        <input type="datetime-local" name="endDate" style="width:100%; padding:8px 12px; border-radius:8px; border:1px solid var(--border-color); background:var(--bg-dark); color:var(--text-primary);">
                    </div>
                </div>

                <div class="form-group" style="text-align:left; margin-bottom:15px;">
                    <label style="font-size:0.8rem; font-weight:600; display:block; margin-bottom:5px;">Activation Status</label>
                    <select name="isActive" required style="width:100%; padding:8px 12px; border-radius:8px; border:1px solid var(--border-color); background:var(--bg-dark); color:var(--text-primary);">
                        <option value="1">Active</option>
                        <option value="0">Inactive</option>
                    </select>
                </div>

                <button type="submit" class="btn-gold" style="width:100%; border-radius:12px; padding:12px; margin-top:10px;">
                    Create Promotion
                </button>
            </form>
        </div>
    </div>

    <!-- ==================================================
         MODAL 8: ADD COUPON (NEW)
         ================================================== -->
    <div id="addCouponModal" class="modal">
        <div class="modal-content" style="max-width: 480px;">
            <span class="modal-close" onclick="closeAddCouponModal()">&times;</span>
            <h3 style="font-family:'Playfair Display', serif; font-size:1.4rem; color:var(--gold); border-bottom:1px solid var(--border-light); padding-bottom:8px; margin-bottom:20px; text-align:left;">
                Create Store Coupon Code
            </h3>
            <form action="AdminServlet" method="POST">
                <input type="hidden" name="action" value="addCoupon">
                
                <div class="form-group" style="text-align:left; margin-bottom:15px;">
                    <label style="font-size:0.8rem; font-weight:600; display:block; margin-bottom:5px;">Coupon Code</label>
                    <input type="text" name="code" placeholder="E.g. GLOW20" required style="text-transform: uppercase; width:100%; padding:8px 12px; border-radius:8px; border:1px solid var(--border-color); background:var(--bg-dark); color:var(--text-primary);">
                </div>

                <div style="display:grid; grid-template-columns: 1fr 1fr; gap:15px; margin-bottom:15px;">
                    <div class="form-group" style="text-align:left; margin-bottom:0;">
                        <label style="font-size:0.8rem; font-weight:600; display:block; margin-bottom:5px;">Discount Type</label>
                        <select name="discountType" required style="width:100%; padding:8px 12px; border-radius:8px; border:1px solid var(--border-color); background:var(--bg-dark); color:var(--text-primary);">
                            <option value="PERCENTAGE">Percentage (%)</option>
                            <option value="FIXED">Fixed Amount (₹)</option>
                        </select>
                    </div>
                    <div class="form-group" style="text-align:left; margin-bottom:0;">
                        <label style="font-size:0.8rem; font-weight:600; display:block; margin-bottom:5px;">Discount Value</label>
                        <input type="number" step="0.01" name="discountAmount" placeholder="E.g. 20.00" required style="width:100%; padding:8px 12px; border-radius:8px; border:1px solid var(--border-color); background:var(--bg-dark); color:var(--text-primary);">
                    </div>
                </div>

                <div style="display:grid; grid-template-columns: 1fr 1fr; gap:15px; margin-bottom:15px;">
                    <div class="form-group" style="text-align:left; margin-bottom:0;">
                        <label style="font-size:0.8rem; font-weight:600; display:block; margin-bottom:5px;">Minimum Purchase (₹)</label>
                        <input type="number" step="0.01" name="minimumPurchase" value="0.00" required style="width:100%; padding:8px 12px; border-radius:8px; border:1px solid var(--border-color); background:var(--bg-dark); color:var(--text-primary);">
                    </div>
                    <div class="form-group" style="text-align:left; margin-bottom:0;">
                        <label style="font-size:0.8rem; font-weight:600; display:block; margin-bottom:5px;">Usage Limit (Total)</label>
                        <input type="number" name="usageLimit" placeholder="Blank for unlimited" style="width:100%; padding:8px 12px; border-radius:8px; border:1px solid var(--border-color); background:var(--bg-dark); color:var(--text-primary);">
                    </div>
                </div>

                <div style="display:grid; grid-template-columns: 1fr 1fr; gap:15px; margin-bottom:15px;">
                    <div class="form-group" style="text-align:left; margin-bottom:0;">
                        <label style="font-size:0.8rem; font-weight:600; display:block; margin-bottom:5px;">Expiration Date</label>
                        <input type="datetime-local" name="expiryDate" style="width:100%; padding:8px 12px; border-radius:8px; border:1px solid var(--border-color); background:var(--bg-dark); color:var(--text-primary);">
                    </div>
                    <div class="form-group" style="text-align:left; margin-bottom:0;">
                        <label style="font-size:0.8rem; font-weight:600; display:block; margin-bottom:5px;">Activation Status</label>
                        <select name="isActive" required style="width:100%; padding:8px 12px; border-radius:8px; border:1px solid var(--border-color); background:var(--bg-dark); color:var(--text-primary);">
                            <option value="1">Active</option>
                            <option value="0">Inactive</option>
                        </select>
                    </div>
                </div>

                <button type="submit" class="btn-gold" style="width:100%; border-radius:12px; padding:12px; margin-top:10px;">
                    Create Coupon Code
                </button>
            </form>
        </div>
    </div>

    <!-- Footer -->
    <%@ include file="../footer.jsp" %>

    <script>
        // Modal toggles
        function openAddModal() {
            document.getElementById('addModal').style.display = 'flex';
        }
        function closeAddModal() {
            document.getElementById('addModal').style.display = 'none';
        }

        function openEditModal(id, name, desc, price, category, imageUrl, stock, rating) {
            document.getElementById('editId').value = id;
            document.getElementById('editName').value = name;
            document.getElementById('editDescription').value = desc;
            document.getElementById('editPrice').value = price;
            document.getElementById('editCategory').value = category;
            document.getElementById('editImageUrl').value = imageUrl;
            document.getElementById('editStock').value = stock;
            document.getElementById('editRating').value = rating;

            document.getElementById('editModal').style.display = 'flex';
        }
        function closeEditModal() {
            document.getElementById('editModal').style.display = 'none';
        }

        function showOrderDetails(orderId) {
            const content = document.getElementById('orderDetails-' + orderId).innerHTML;
            document.getElementById('orderDetailsModalBody').innerHTML = content;
            document.getElementById('orderDetailsModal').style.display = 'flex';
        }
        function closeOrderDetailsModal() {
            document.getElementById('orderDetailsModal').style.display = 'none';
        }

        // --- NEW MODAL CONTROLLERS ---
        function openAddVariantModal(productId, productName) {
            document.getElementById('addVarProductId').value = productId;
            const urlParams = new URLSearchParams(window.location.search);
            const currentTab = urlParams.get('tab') || 'products';
            const addVarRedirect = document.getElementById('addVarRedirectTab');
            if (addVarRedirect) {
                addVarRedirect.value = currentTab;
            }
            document.getElementById('addVariantModal').style.display = 'flex';
        }
        function closeAddVariantModal() {
            document.getElementById('addVariantModal').style.display = 'none';
        }

        function openEditVariantModal(variantId, productId, name, color, stock, price) {
            document.getElementById('editVarVariantId').value = variantId;
            document.getElementById('editVarProductId').value = productId;
            document.getElementById('editVarName').value = name;
            document.getElementById('editVarColor').value = color;
            document.getElementById('editVarStock').value = stock;
            document.getElementById('editVarPrice').value = price;
            const urlParams = new URLSearchParams(window.location.search);
            const currentTab = urlParams.get('tab') || 'products';
            const editVarRedirect = document.getElementById('editVarRedirectTab');
            if (editVarRedirect) {
                editVarRedirect.value = currentTab;
            }
            document.getElementById('editVariantModal').style.display = 'flex';
        }
        function closeEditVariantModal() {
            document.getElementById('editVariantModal').style.display = 'none';
        }

        function openManageGalleryModal(productId, productName) {
            document.getElementById('galleryProductId').value = productId;
            document.getElementById('galleryProductId').value = productId;
            document.getElementById('galleryProductName').innerText = productName;
            
            // Query current images from database dynamically
            fetchGalleryImages(productId);
            document.getElementById('manageGalleryModal').style.display = 'flex';
        }
        function closeManageGalleryModal() {
            document.getElementById('manageGalleryModal').style.display = 'none';
        }

        function fetchGalleryImages(productId) {
            const listEl = document.getElementById('galleryImagesList') || document.getElementById('detailGalleryImagesList');
            if (!listEl) return;
            listEl.innerHTML = '<p style="color:var(--text-muted); text-align:center; font-size:0.85rem;">Loading gallery assets...</p>';
            fetch('getGalleryImages.jsp?productId=' + productId)
                .then(res => res.text())
                .then(html => {
                    listEl.innerHTML = html;
                })
                .catch(err => {
                    listEl.innerHTML = '<p style="color:var(--danger); font-size:0.8rem;">Failed to load images.</p>';
                    console.error(err);
                });
        }

        // Close modal on outer clicks
        window.onclick = function(event) {
            const addM = document.getElementById('addModal');
            const editM = document.getElementById('editModal');
            const detailsM = document.getElementById('orderDetailsModal');
            const addVarM = document.getElementById('addVariantModal');
            const editVarM = document.getElementById('editVariantModal');
            const galleryM = document.getElementById('manageGalleryModal');
            const addPromoM = document.getElementById('addPromotionModal');
            const addCouponM = document.getElementById('addCouponModal');
            if (event.target == addM) addM.style.display = 'none';
            if (event.target == editM) editM.style.display = 'none';
            if (event.target == detailsM) detailsM.style.display = 'none';
            if (event.target == addVarM) addVarM.style.display = 'none';
            if (event.target == editVarM) editVarM.style.display = 'none';
            if (event.target == galleryM) galleryM.style.display = 'none';
            if (event.target == addPromoM) addPromoM.style.display = 'none';
            if (event.target == addCouponM) addCouponM.style.display = 'none';
        }

        // --- NEW MODAL ACTIONS ---
        function openAddPromoModal() {
            document.getElementById('addPromotionModal').style.display = 'flex';
        }
        function closeAddPromoModal() {
            document.getElementById('addPromotionModal').style.display = 'none';
        }
        function openAddCouponModal() {
            document.getElementById('addCouponModal').style.display = 'flex';
        }
        function closeAddCouponModal() {
            document.getElementById('addCouponModal').style.display = 'none';
        }
        function togglePromoTargetValue() {
            const scope = document.getElementById('promoTargetType').value;
            const input = document.getElementById('promoTargetValue');
            if (scope === 'SITEWIDE') {
                input.value = '';
                input.placeholder = 'Leave empty for Sitewide';
                input.disabled = true;
            } else if (scope === 'PRODUCT') {
                input.placeholder = 'Enter Product ID (e.g. 15)';
                input.disabled = false;
            } else if (scope === 'CATEGORY') {
                input.placeholder = 'Enter Category (e.g. Skincare)';
                input.disabled = false;
            } else if (scope === 'BRAND') {
                input.placeholder = 'Enter Brand Name (e.g. LuxeGlow)';
                input.disabled = false;
            }
        }

        const currentProductId = <%= prodId %>;

        // AJAX Notification Alert system
        function showBannerAlert(type, message) {
            let container = document.getElementById('ajaxAlertContainer');
            if (!container) {
                container = document.createElement('div');
                container.id = 'ajaxAlertContainer';
                container.style.position = 'fixed';
                container.style.top = '80px';
                container.style.right = '20px';
                container.style.zIndex = '9999';
                container.style.display = 'flex';
                container.style.flexDirection = 'column';
                container.style.gap = '10px';
                document.body.appendChild(container);
            }
            
            const alert = document.createElement('div');
            alert.className = `alert alert-\${type}`;
            alert.style.margin = '0';
            alert.style.boxShadow = 'var(--shadow-lux)';
            alert.style.minWidth = '300px';
            alert.style.animation = 'fadeInRight 0.3s ease-out';
            alert.style.display = 'flex';
            alert.style.alignItems = 'center';
            alert.style.gap = '10px';
            
            const icon = type === 'success' ? 'fa-check-circle' : 'fa-exclamation-circle';
            alert.innerHTML = `
                <i class="fas \${icon}" style="color: \${type === 'success' ? 'var(--success)' : 'var(--danger)'};"></i>
                <span style="font-size:0.85rem; font-weight:600; text-align:left;">\${message}</span>
                <span style="margin-left:auto; cursor:pointer; font-weight:bold; font-size:1.1rem;" onclick="this.parentNode.remove()">&times;</span>
            `;
            
            container.appendChild(alert);
            
            setTimeout(() => {
                alert.style.animation = 'fadeOutRight 0.3s ease-in';
                setTimeout(() => alert.remove(), 300);
            }, 4000);
        }

        // Inline Stock update via AJAX
        function updateStockAsync(productId) {
            const stockInput = document.getElementById(`inline-stock-\${productId}`);
            if (!stockInput) return;
            const stock = stockInput.value;
            
            fetch('AdminServlet?format=json', {
                method: 'POST',
                headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                body: new URLSearchParams({
                    action: 'updateStock',
                    id: productId,
                    stock: stock,
                    format: 'json'
                })
            })
            .then(res => res.json())
            .then(data => {
                if (data.status === 'success') {
                    showBannerAlert('success', data.message);
                    const row = document.querySelector(`.product-row[data-id="\${productId}"]`);
                    if (row) {
                        row.setAttribute('data-stock', stock);
                        const labelDiv = stockInput.parentNode.nextElementSibling;
                        if (labelDiv) {
                            const icon = stock == 0 ? 'fa-times-circle' : (stock < 10 ? 'fa-exclamation-triangle' : 'fa-check-circle');
                            const color = stock == 0 ? 'var(--danger)' : (stock < 10 ? 'var(--gold)' : 'var(--success)');
                            const text = stock == 0 ? 'Out of Stock' : (stock < 10 ? 'Low Stock: ' + stock : 'In Stock');
                            labelDiv.style.color = color;
                            labelDiv.innerHTML = `<i class="fas \${icon}" style="margin-right:2px;"></i> \${text}`;
                        }
                    }
                } else {
                    showBannerAlert('danger', data.message);
                }
            })
            .catch(err => {
                console.error(err);
                showBannerAlert('danger', 'Failed to update stock.');
            });
        }

        // Inline Status active/draft toggle via AJAX
        function toggleStatusAsync(productId) {
            fetch('AdminServlet?format=json', {
                method: 'POST',
                headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                body: new URLSearchParams({
                    action: 'toggleProductStatus',
                    id: productId,
                    format: 'json'
                })
            })
            .then(res => res.json())
            .then(data => {
                if (data.status === 'success') {
                    showBannerAlert('success', data.message);
                    const badge = document.getElementById(`status-badge-\${productId}`);
                    const row = document.querySelector(`.product-row[data-id="\${productId}"]`);
                    if (badge && row) {
                        const currentStatus = row.getAttribute('data-status');
                        const newStatus = currentStatus === 'ACTIVE' ? 'DRAFT' : 'ACTIVE';
                        row.setAttribute('data-status', newStatus);
                        
                        badge.className = `status-badge \${newStatus === 'ACTIVE' ? 'status-completed' : 'status-cancelled'}`;
                        badge.innerText = newStatus === 'ACTIVE' ? 'Active' : 'Draft';
                    }
                } else {
                    showBannerAlert('danger', data.message);
                }
            })
            .catch(err => {
                console.error(err);
                showBannerAlert('danger', 'Failed to toggle status.');
            });
        }

        // Delete product from Catalog list via AJAX
        function deleteProductAsync(productId, productName) {
            if (!confirm(`Are you sure you want to permanently delete product "\${productName}"?`)) {
                return;
            }
            fetch('AdminServlet?format=json', {
                method: 'POST',
                headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                body: new URLSearchParams({
                    action: 'delete',
                    id: productId,
                    format: 'json'
                })
            })
            .then(res => res.json())
            .then(data => {
                if (data.status === 'success') {
                    showBannerAlert('success', data.message);
                    const row = document.querySelector(`.product-row[data-id="\${productId}"]`);
                    if (row) {
                        row.remove();
                        updateSelectionState();
                    }
                } else {
                    showBannerAlert('danger', data.message);
                }
            })
            .catch(err => {
                console.error(err);
                showBannerAlert('danger', 'Failed to delete product.');
            });
        }

        // Checkbox controllers
        function toggleSelectAll(selectAllCheckbox) {
            const isChecked = selectAllCheckbox.checked;
            const checkboxes = document.querySelectorAll('.product-select-checkbox');
            checkboxes.forEach(cb => {
                const row = cb.closest('.product-row');
                if (row && row.style.display !== 'none') {
                    cb.checked = isChecked;
                }
            });
            updateSelectionState();
        }

        function updateSelectionState() {
            const checkedBoxes = document.querySelectorAll('.product-select-checkbox:checked');
            const totalVisible = Array.from(document.querySelectorAll('.product-select-checkbox')).filter(cb => {
                const row = cb.closest('.product-row');
                return row && row.style.display !== 'none';
            });
            
            const selectAllCb = document.getElementById('selectAllCheckbox');
            if (selectAllCb) {
                selectAllCb.checked = (checkedBoxes.length > 0 && checkedBoxes.length === totalVisible.length);
            }
            
            const toolbar = document.getElementById('bulkActionsToolbar');
            const countLabel = document.getElementById('selectedCountLabel');
            if (toolbar && countLabel) {
                if (checkedBoxes.length > 0) {
                    countLabel.innerText = `\${checkedBoxes.length} item(s) selected`;
                    toolbar.style.display = 'flex';
                } else {
                    toolbar.style.display = 'none';
                }
            }
        }

        function performBulkAction(operation) {
            const checkedBoxes = document.querySelectorAll('.product-select-checkbox:checked');
            if (checkedBoxes.length === 0) return;
            
            const ids = Array.from(checkedBoxes).map(cb => cb.getAttribute('data-id'));
            
            let confirmMsg = `Are you sure you want to perform bulk "\${operation}" on \${ids.length} item(s)?`;
            if (operation === 'delete') {
                confirmMsg = `CRITICAL WARNING: Are you sure you want to permanently delete all \${ids.length} selected product(s)? This action is irreversible!`;
            }
            
            if (!confirm(confirmMsg)) return;
            
            fetch('AdminServlet?format=json', {
                method: 'POST',
                headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                body: new URLSearchParams({
                    action: 'bulkProductAction',
                    operation: operation,
                    ids: ids.join(','),
                    format: 'json'
                })
            })
            .then(res => res.json())
            .then(data => {
                if (data.status === 'success') {
                    showBannerAlert('success', data.message);
                    
                    ids.forEach(id => {
                        const row = document.querySelector(`.product-row[data-id="\${id}"]`);
                        if (row) {
                            if (operation === 'delete') {
                                row.remove();
                            } else {
                                const statusVal = operation === 'activate' ? 'ACTIVE' : 'DRAFT';
                                row.setAttribute('data-status', statusVal);
                                const badge = document.getElementById(`status-badge-\${id}`);
                                if (badge) {
                                    badge.className = `status-badge \${statusVal === 'ACTIVE' ? 'status-completed' : 'status-cancelled'}`;
                                    badge.innerText = statusVal === 'ACTIVE' ? 'Active' : 'Draft';
                                }
                                const cb = row.querySelector('.product-select-checkbox');
                                if (cb) cb.checked = false;
                            }
                        }
                    });
                    
                    updateSelectionState();
                } else {
                    showBannerAlert('danger', data.message);
                }
            })
            .catch(err => {
                console.error(err);
                showBannerAlert('danger', 'Bulk action failed.');
            });
        }

        // Sorting catalog rows in-place
        function sortCatalogRows(sortBy) {
            const tbody = document.getElementById('catalogTableBody');
            if (!tbody) return;
            const rows = Array.from(tbody.querySelectorAll('.product-row'));
            
            rows.sort((a, b) => {
                let valA, valB;
                if (sortBy.startsWith('name')) {
                    valA = a.getAttribute('data-name');
                    valB = b.getAttribute('data-name');
                    return sortBy.endsWith('asc') ? valA.localeCompare(valB) : valB.localeCompare(valA);
                } else if (sortBy.startsWith('price')) {
                    valA = parseFloat(a.getAttribute('data-price') || '0');
                    valB = parseFloat(b.getAttribute('data-price') || '0');
                    return sortBy.endsWith('asc') ? valA - valB : valB - valA;
                } else if (sortBy.startsWith('stock')) {
                    valA = parseInt(a.getAttribute('data-stock') || '0', 10);
                    valB = parseInt(b.getAttribute('data-stock') || '0', 10);
                    return sortBy.endsWith('asc') ? valA - valB : valB - valA;
                } else if (sortBy.startsWith('rating')) {
                    valA = parseInt(a.getAttribute('data-rating') || '0', 10);
                    valB = parseInt(b.getAttribute('data-rating') || '0', 10);
                    return valB - valA;
                } else { // default id_desc
                    valA = parseInt(a.getAttribute('data-id') || '0', 10);
                    valB = parseInt(b.getAttribute('data-id') || '0', 10);
                    return valB - valA;
                }
            });
            
            rows.forEach(row => tbody.appendChild(row));
        }

        // Save specifications via AJAX
        function saveSpecifications(event) {
            event.preventDefault();
            const form = event.target;
            const formData = new FormData(form);
            formData.append('format', 'json');
            
            showBannerAlert('success', 'Saving specifications...');
            fetch('AdminServlet?format=json', {
                method: 'POST',
                body: formData
            })
            .then(res => res.json())
            .then(data => {
                if (data.status === 'success') {
                    showBannerAlert('success', data.message);
                    const nameHeader = document.getElementById('detailsProductNameHeader');
                    if (nameHeader) {
                        nameHeader.innerText = form.name.value;
                    }
                } else {
                    showBannerAlert('danger', data.message);
                }
            })
            .catch(err => {
                console.error(err);
                showBannerAlert('danger', 'Failed to save product specifications.');
            });
        }

        // AJAX variant list and settings loader
        function fetchVariantsList(productId, activeVariantId) {
            const container = document.getElementById('variantsContainer');
            if (!container) return;
            
            container.innerHTML = '<p style="color:var(--text-muted); text-align:center; font-size:0.85rem; padding:20px;">Updating variants list...</p>';
            
            let url = `getVariantsList.jsp?productId=\${productId}`;
            if (activeVariantId > 0) {
                url += `&activeVariantId=\${activeVariantId}`;
            }
            
            fetch(url)
                .then(res => res.text())
                .then(html => {
                    container.innerHTML = html;
                    const editForm = document.getElementById('editActiveVariantForm');
                    if (editForm) {
                        const activeVarId = editForm.variantId.value;
                        fetchVariantImages(activeVarId);
                    }
                })
                .catch(err => {
                    container.innerHTML = '<p style="color:var(--danger); font-size:0.8rem;">Failed to load variants configuration.</p>';
                    console.error(err);
                });
        }

        function selectVariantTab(variantId) {
            fetchVariantsList(currentProductId, variantId);
        }

        function saveVariantDetails(event, variantId) {
            event.preventDefault();
            const form = event.target;
            const formData = new FormData(form);
            formData.append('format', 'json');
            
            showBannerAlert('success', 'Saving shade details...');
            fetch('AdminServlet?format=json', {
                method: 'POST',
                body: formData
            })
            .then(res => res.json())
            .then(data => {
                if (data.status === 'success') {
                    showBannerAlert('success', data.message);
                    fetchVariantsList(currentProductId, variantId);
                    fetchGalleryImages(currentProductId);
                } else {
                    showBannerAlert('danger', data.message);
                }
            })
            .catch(err => {
                console.error(err);
                showBannerAlert('danger', 'Failed to save variant changes.');
            });
        }

        function deleteVariantAsync(variantId, variantName) {
            if (!confirm(`Are you sure you want to delete variant shade "\${variantName}"?`)) {
                return;
            }
            fetch('AdminServlet?format=json', {
                method: 'POST',
                headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                body: new URLSearchParams({
                    action: 'deleteVariant',
                    variantId: variantId,
                    redirectTab: 'product-details',
                    format: 'json'
                })
            })
            .then(res => res.json())
            .then(data => {
                if (data.status === 'success') {
                    showBannerAlert('success', data.message);
                    fetchVariantsList(currentProductId, 0);
                    fetchGalleryImages(currentProductId);
                } else {
                    showBannerAlert('danger', data.message);
                }
            })
            .catch(err => {
                console.error(err);
                showBannerAlert('danger', 'Failed to delete variant.');
            });
        }

        function fetchVariantImages(variantId) {
            const grid = document.getElementById('variantImagesGridContainer');
            if (!grid) return;
            
            grid.innerHTML = '<p style="color:var(--text-muted); text-align:center; font-size:0.8rem; padding:10px;">Loading variant photos...</p>';
            
            fetch(`getVariantImages.jsp?productId=\${currentProductId}&variantId=\${variantId}`)
                .then(res => res.text())
                .then(html => {
                    grid.innerHTML = html;
                })
                .catch(err => {
                    grid.innerHTML = '<p style="color:var(--danger); font-size:0.8rem;">Failed to load variant photos.</p>';
                    console.error(err);
                });
        }

        function setPrimaryVariantImage(imageId, variantId) {
            fetch('AdminServlet?format=json', {
                method: 'POST',
                headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                body: new URLSearchParams({
                    action: 'setPrimaryVariantImage',
                    imageId: imageId,
                    variantId: variantId,
                    productId: currentProductId,
                    redirectTab: 'product-details',
                    format: 'json'
                })
            })
            .then(res => res.json())
            .then(data => {
                if (data.status === 'success') {
                    showBannerAlert('success', data.message);
                    fetchVariantImages(variantId);
                    fetchGalleryImages(currentProductId);
                } else {
                    showBannerAlert('danger', data.message);
                }
            })
            .catch(err => {
                console.error(err);
                showBannerAlert('danger', 'Failed to set primary variant image.');
            });
        }

        function setProductCoverImage(imageUrl, productId) {
            fetch('AdminServlet?format=json', {
                method: 'POST',
                headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                body: new URLSearchParams({
                    action: 'setProductCoverImage',
                    productId: productId,
                    imageUrl: imageUrl,
                    redirectTab: 'product-details',
                    format: 'json'
                })
            })
            .then(res => res.json())
            .then(data => {
                if (data.status === 'success') {
                    showBannerAlert('success', data.message);
                    const coverInput = document.querySelector('input[name="imageUrl"]');
                    if (coverInput) coverInput.value = imageUrl;
                    
                    fetchGalleryImages(productId);
                    const editForm = document.getElementById('editActiveVariantForm');
                    if (editForm) {
                        const activeVarId = editForm.variantId.value;
                        fetchVariantImages(activeVarId);
                    }
                } else {
                    showBannerAlert('danger', data.message);
                }
            })
            .catch(err => {
                console.error(err);
                showBannerAlert('danger', 'Failed to update cover image.');
            });
        }

        function deleteVariantImage(imageId, variantId) {
            if (!confirm('Permanently delete this variant image from gallery?')) return;
            fetch('AdminServlet?format=json', {
                method: 'POST',
                headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                body: new URLSearchParams({
                    action: 'deleteProductImage',
                    imageId: imageId,
                    productId: currentProductId,
                    redirectTab: 'product-details',
                    format: 'json'
                })
            })
            .then(res => res.json())
            .then(data => {
                if (data.status === 'success') {
                    showBannerAlert('success', data.message);
                    fetchVariantImages(variantId);
                    fetchGalleryImages(currentProductId);
                } else {
                    showBannerAlert('danger', data.message);
                }
            })
            .catch(err => {
                console.error(err);
                showBannerAlert('danger', 'Failed to delete variant image.');
            });
        }

        function openVariantImageUploadModal(variantId) {
            let fileInput = document.getElementById('ajaxVariantImageInput');
            if (!fileInput) {
                fileInput = document.createElement('input');
                fileInput.id = 'ajaxVariantImageInput';
                fileInput.type = 'file';
                fileInput.name = 'variantImages';
                fileInput.multiple = true;
                fileInput.accept = 'image/*';
                fileInput.style.display = 'none';
                document.body.appendChild(fileInput);
                
                fileInput.onchange = function() {
                    if (fileInput.files.length === 0) return;
                    
                    const formData = new FormData();
                    formData.append('action', 'uploadVariantImages');
                    formData.append('productId', currentProductId);
                    formData.append('variantId', fileInput.getAttribute('data-variant-id'));
                    formData.append('redirectTab', 'product-details');
                    formData.append('format', 'json');
                    for (let file of fileInput.files) {
                        formData.append('variantImages', file);
                    }
                    
                    showBannerAlert('success', 'Uploading variant photos...');
                    fetch('AdminServlet?format=json', {
                        method: 'POST',
                        body: formData
                    })
                    .then(res => res.json())
                    .then(data => {
                        if (data.status === 'success') {
                            showBannerAlert('success', data.message);
                            fetchVariantImages(fileInput.getAttribute('data-variant-id'));
                            fetchGalleryImages(currentProductId);
                        } else {
                            showBannerAlert('danger', data.message);
                        }
                    })
                    .catch(err => {
                        console.error(err);
                        showBannerAlert('danger', 'Failed to upload variant photos.');
                    });
                };
            }
            fileInput.setAttribute('data-variant-id', variantId);
            fileInput.value = '';
            fileInput.click();
        }

        function uploadGeneralImages(event) {
            event.preventDefault();
            const form = event.target;
            const formData = new FormData(form);
            formData.append('format', 'json');
            
            showBannerAlert('success', 'Uploading gallery photos...');
            fetch('AdminServlet?format=json', {
                method: 'POST',
                body: formData
            })
            .then(res => res.json())
            .then(data => {
                if (data.status === 'success') {
                    showBannerAlert('success', data.message);
                    form.reset();
                    fetchGalleryImages(currentProductId);
                } else {
                    showBannerAlert('danger', data.message);
                }
            })
            .catch(err => {
                console.error(err);
                showBannerAlert('danger', 'Failed to upload gallery photos.');
            });
        }

        function deleteProductImageAsync(imageId, productId) {
            if (!confirm('Delete this image from gallery?')) return;
            fetch('AdminServlet?format=json', {
                method: 'POST',
                headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                body: new URLSearchParams({
                    action: 'deleteProductImage',
                    imageId: imageId,
                    productId: productId,
                    redirectTab: 'product-details',
                    format: 'json'
                })
            })
            .then(res => res.json())
            .then(data => {
                if (data.status === 'success') {
                    showBannerAlert('success', data.message);
                    fetchGalleryImages(productId);
                    const editForm = document.getElementById('editActiveVariantForm');
                    if (editForm) {
                        const activeVarId = editForm.variantId.value;
                        fetchVariantImages(activeVarId);
                    }
                } else {
                    showBannerAlert('danger', data.message);
                }
            })
            .catch(err => {
                console.error(err);
                showBannerAlert('danger', 'Failed to delete image.');
            });
        }

        // --- NEW FILTER CONTROLLERS ---
        function filterCatalog() {
            const search = document.getElementById('catalogSearch').value.toLowerCase();
            const category = document.getElementById('categoryFilter').value.toLowerCase();
            const status = document.getElementById('statusFilter').value;
            const stockLevel = document.getElementById('stockFilter').value;
            const onSale = document.getElementById('onSaleFilter').value;
            const sortBy = document.getElementById('sortSelector').value;
            
            const rows = document.querySelectorAll('#catalogTableBody .product-row');
            rows.forEach(row => {
                const name = row.getAttribute('data-name') || '';
                const sku = row.getAttribute('data-sku') || '';
                const brand = row.getAttribute('data-brand') || '';
                const cat = row.getAttribute('data-category') || '';
                const stat = row.getAttribute('data-status') || '';
                const stock = parseInt(row.getAttribute('data-stock') || '0', 10);
                const sale = row.getAttribute('data-onsale') === 'true';
                
                const matchesSearch = name.includes(search) || sku.includes(search) || brand.includes(search);
                const matchesCategory = category === 'all' || cat === category;
                const matchesStatus = status === 'ALL' || stat === status;
                
                let matchesStock = true;
                if (stockLevel === 'LOW') {
                    matchesStock = stock < 10;
                } else if (stockLevel === 'OUT') {
                    matchesStock = stock === 0;
                }
                
                let matchesSale = true;
                if (onSale === 'SALE') {
                    matchesSale = sale;
                } else if (onSale === 'NORMAL') {
                    matchesSale = !sale;
                }
                
                if (matchesSearch && matchesCategory && matchesStatus && matchesStock && matchesSale) {
                    row.style.display = '';
                } else {
                    row.style.display = 'none';
                    const cb = row.querySelector('.product-select-checkbox');
                    if (cb) cb.checked = false;
                }
            });
            
            updateSelectionState();
            sortCatalogRows(sortBy);
        }

        function searchReviews() {
            const input = document.getElementById('reviewSearch').value.toLowerCase();
            const rows = document.querySelectorAll('.review-row');
            rows.forEach(row => {
                const customer = row.querySelector('.rev-customer').textContent.toLowerCase();
                const comment = row.querySelector('.rev-comment').textContent.toLowerCase();
                if (customer.includes(input) || comment.includes(input)) {
                    row.style.display = '';
                } else {
                    row.style.display = 'none';
                }
            });
        }
        
        function filterReviews() {
            const filter = document.getElementById('reviewFilter').value;
            const rows = document.querySelectorAll('.review-row');
            rows.forEach(row => {
                const isHidden = row.getAttribute('data-hidden') === '1';
                if (filter === 'ALL') {
                    row.style.display = '';
                } else if (filter === 'VISIBLE' && !isHidden) {
                    row.style.display = '';
                } else if (filter === 'HIDDEN' && isHidden) {
                    row.style.display = '';
                } else {
                    row.style.display = 'none';
                }
            });
        }

        // On Load Trigger
        document.addEventListener('DOMContentLoaded', () => {
            <% if ("product-details".equalsIgnoreCase(activeTab) && prodId > 0) { %>
                fetchGalleryImages(<%= prodId %>);
                fetchVariantsList(<%= prodId %>, 0);
            <% } %>
        });

        // Search inputs filtering functions
        function searchCatalog() {
            const input = document.getElementById('catalogSearch').value.toLowerCase();
            const rows = document.querySelectorAll('.product-row');
            rows.forEach(row => {
                const name = row.querySelector('.prod-name').textContent.toLowerCase();
                const cat = row.querySelector('.prod-cat').textContent.toLowerCase();
                const nextRow = row.nextElementSibling; // the variants row
                if (name.includes(input) || cat.includes(input)) {
                    row.style.display = '';
                    if (nextRow && nextRow.classList.contains('variants-row') === false) {
                        nextRow.style.display = '';
                    }
                } else {
                    row.style.display = 'none';
                    if (nextRow && nextRow.classList.contains('variants-row') === false) {
                        nextRow.style.display = 'none';
                    }
                }
            });
        }

        function searchOrders() {
            const input = document.getElementById('orderSearch').value.toLowerCase();
            const rows = document.querySelectorAll('.order-row');
            rows.forEach(row => {
                const ref = row.querySelector('.order-ref').textContent.toLowerCase();
                const cust = row.querySelector('.order-customer').textContent.toLowerCase();
                if (ref.includes(input) || cust.includes(input)) {
                    row.style.display = '';
                } else {
                    row.style.display = 'none';
                }
            });
        }

        function filterOrders() {
            const filter = document.getElementById('statusFilter').value;
            const rows = document.querySelectorAll('.order-row');
            rows.forEach(row => {
                const status = row.getAttribute('data-status');
                if (filter === 'ALL' || status === filter) {
                    row.style.display = '';
                } else {
                    row.style.display = 'none';
                }
            });
        }

        function searchUsersList() {
            const input = document.getElementById('userSearch').value.toLowerCase();
            const rows = document.querySelectorAll('.user-row');
            rows.forEach(row => {
                const name = row.querySelector('.user-fullname').textContent.toLowerCase();
                const user = row.querySelector('.user-username').textContent.toLowerCase();
                const email = row.querySelector('.user-email').textContent.toLowerCase();
                const country = row.querySelector('.user-country').textContent.toLowerCase();
                if (name.includes(input) || user.includes(input) || email.includes(input) || country.includes(input)) {
                    row.style.display = '';
                } else {
                    row.style.display = 'none';
                }
            });
        }

        // Chart.js integrations
        document.addEventListener('DOMContentLoaded', () => {
            <%
                // Prepare analytical data from request parameters
                StringBuilder monthLabels = new StringBuilder("[");
                StringBuilder salesValues = new StringBuilder("[");
                StringBuilder orderValues = new StringBuilder("[");
                if (monthlySalesList != null) {
                    for (int i = 0; i < monthlySalesList.size(); i++) {
                        Map<String, Object> stat = monthlySalesList.get(i);
                        monthLabels.append("\"").append(stat.get("month")).append("\"");
                        salesValues.append(stat.get("sales"));
                        orderValues.append(stat.get("orders"));
                        if (i < monthlySalesList.size() - 1) {
                            monthLabels.append(",");
                            salesValues.append(",");
                            orderValues.append(",");
                        }
                    }
                }
                monthLabels.append("]");
                salesValues.append("]");
                orderValues.append("]");

                StringBuilder bestProductLabels = new StringBuilder("[");
                StringBuilder bestProductQty = new StringBuilder("[");
                if (bestSellersList != null) {
                    for (int i = 0; i < bestSellersList.size(); i++) {
                        Map<String, Object> stat = bestSellersList.get(i);
                        bestProductLabels.append("\"").append(stat.get("name").toString().replace("\"", "\\\"")).append("\"");
                        bestProductQty.append(stat.get("sold"));
                        if (i < bestSellersList.size() - 1) {
                            bestProductLabels.append(",");
                            bestProductQty.append(",");
                        }
                    }
                }
                bestProductLabels.append("]");
                bestProductQty.append("]");
            %>

            const months = <%= monthLabels.toString() %>;
            const sales = <%= salesValues.toString() %>;
            const orders = <%= orderValues.toString() %>;
            const bestProducts = <%= bestProductLabels.toString() %>;
            const bestQuantities = <%= bestProductQty.toString() %>;

            // Mini dashboard chart
            const miniCtx = document.getElementById('miniSalesChart');
            if (miniCtx) {
                new Chart(miniCtx, {
                    type: 'line',
                    data: {
                        labels: months,
                        datasets: [{
                            label: 'Monthly Sales (₹)',
                            data: sales,
                            backgroundColor: 'rgba(92, 13, 30, 0.05)',
                            borderColor: '#5C0D1E',
                            borderWidth: 2,
                            tension: 0.3,
                            fill: true
                        }]
                    },
                    options: {
                        responsive: true,
                        maintainAspectRatio: false,
                        plugins: {
                            legend: { display: false }
                        },
                        scales: {
                            y: { grid: { color: 'rgba(0,0,0,0.05)' } },
                            x: { grid: { display: false } }
                        }
                    }
                });
            }

            // Full analytics - sales trends
            const trendsCtx = document.getElementById('monthlySalesChart');
            if (trendsCtx) {
                new Chart(trendsCtx, {
                    type: 'bar',
                    data: {
                        labels: months,
                        datasets: [
                            {
                                label: 'Revenue (₹)',
                                data: sales,
                                backgroundColor: 'rgba(92, 13, 30, 0.85)',
                                borderColor: '#5C0D1E',
                                borderWidth: 1,
                                yAxisID: 'y'
                            },
                            {
                                label: 'Orders Count',
                                data: orders,
                                type: 'line',
                                borderColor: '#C5AB57',
                                backgroundColor: 'transparent',
                                borderWidth: 2,
                                tension: 0.3,
                                yAxisID: 'y1'
                            }
                        ]
                    },
                    options: {
                        responsive: true,
                        maintainAspectRatio: false,
                        scales: {
                            y: {
                                type: 'linear',
                                display: true,
                                position: 'left',
                                grid: { color: 'rgba(0,0,0,0.05)' }
                            },
                            y1: {
                                type: 'linear',
                                display: true,
                                position: 'right',
                                grid: { drawOnChartArea: false }
                            },
                            x: { grid: { display: false } }
                        }
                    }
                });
            }

            // Full analytics - best sellers
            const sellersCtx = document.getElementById('bestSellersChart');
            if (sellersCtx) {
                new Chart(sellersCtx, {
                    type: 'doughnut',
                    data: {
                        labels: bestProducts,
                        datasets: [{
                            data: bestQuantities,
                            backgroundColor: [
                                '#5C0D1E',
                                '#C5AB57',
                                '#8F8486',
                                '#4E4748',
                                '#E23E57'
                            ],
                            borderWidth: 1
                        }]
                    },
                    options: {
                        responsive: true,
                        maintainAspectRatio: false,
                        plugins: {
                            legend: {
                                position: 'right',
                                labels: { boxWidth: 12, font: { size: 10 } }
                            }
                        }
                    }
                });
            }
        });

        // Save scroll position before unloading the page to prevent losing position on saves/uploads
        window.addEventListener('beforeunload', () => {
            localStorage.setItem('adminScrollY', window.scrollY);
        });

        // Restore scroll position after DOM content is loaded
        window.addEventListener('DOMContentLoaded', () => {
            const scrollY = localStorage.getItem('adminScrollY');
            if (scrollY !== null) {
                window.scrollTo(0, parseInt(scrollY, 10));
                localStorage.removeItem('adminScrollY');
            }
        });
    </script>
</body>
</html>
