<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%
    String currentCountry = "India";
    if (session != null && session.getAttribute("selected_country") != null) {
        currentCountry = (String) session.getAttribute("selected_country");
    }

    // Check if a session already exists. Do not create a new one yet.
    HttpSession navSess = request.getSession(false);
    String navUsername = null;
    String navRole = null;
    Integer navUserId = null;
    int navCartCount = 0;
    int navWishlistCount = 0;


    if (navSess != null) {
        navUsername = (String) navSess.getAttribute("username");
        navRole = (String) navSess.getAttribute("role");
        navUserId = (Integer) navSess.getAttribute("user_id");
        if (navUserId != null) {
            java.sql.Connection navCon = null;
            java.sql.PreparedStatement navPs = null;
            java.sql.ResultSet navRs = null;
            try {
                navCon = com.mycompany.mavenproject2.DBConnection.getConnection();

                // Dynamic country resolution for logged-in user:
                String resolvedCountry = null;
                // 1. Get default address country
                navPs = navCon.prepareStatement("SELECT country FROM addresses WHERE user_id = ? AND is_default = TRUE LIMIT 1");
                navPs.setInt(1, navUserId);
                navRs = navPs.executeQuery();
                if (navRs.next()) {
                    resolvedCountry = navRs.getString("country");
                }
                navRs.close();
                navPs.close();

                // 2. Fallback to last added saved address country
                if (resolvedCountry == null || resolvedCountry.trim().isEmpty()) {
                    navPs = navCon.prepareStatement("SELECT country FROM addresses WHERE user_id = ? ORDER BY id DESC LIMIT 1");
                    navPs.setInt(1, navUserId);
                    navRs = navPs.executeQuery();
                    if (navRs.next()) {
                        resolvedCountry = navRs.getString("country");
                    }
                    navRs.close();
                    navPs.close();
                }

                // 3. Fallback to profile registration country
                if (resolvedCountry == null || resolvedCountry.trim().isEmpty()) {
                    navPs = navCon.prepareStatement("SELECT country_name FROM users WHERE id = ?");
                    navPs.setInt(1, navUserId);
                    navRs = navPs.executeQuery();
                    if (navRs.next()) {
                        resolvedCountry = navRs.getString("country_name");
                    }
                    navRs.close();
                    navPs.close();
                }

                if (resolvedCountry != null && !resolvedCountry.trim().isEmpty()) {
                    session.setAttribute("selected_country", resolvedCountry.trim());
                }

                navPs = navCon.prepareStatement("SELECT SUM(quantity) FROM cart WHERE user_id = ?");
                navPs.setInt(1, navUserId);
                navRs = navPs.executeQuery();
                if (navRs.next()) {
                    navCartCount = navRs.getInt(1);
                }
                navRs.close();
                navPs.close();

                navPs = navCon.prepareStatement("SELECT COUNT(*) FROM wishlist WHERE user_id = ?");
                navPs.setInt(1, navUserId);
                navRs = navPs.executeQuery();
                if (navRs.next()) {
                    navWishlistCount = navRs.getInt(1);
                }
            } catch (Exception e) {
                // Connection errors or table not setup yet
            } finally {
                if (navRs != null) try { navRs.close(); } catch (Exception e) {}
                if (navPs != null) try { navPs.close(); } catch (Exception e) {}
                if (navCon != null) try { navCon.close(); } catch (Exception e) {}
            }
        }
    }

    if (navUsername == null) {
        // Retrieve guest cart count
        java.util.Map<Integer, Integer> guestCart = (java.util.Map<Integer, Integer>) session.getAttribute("guest_cart");
        if (guestCart != null) {
            for (int qty : guestCart.values()) {
                navCartCount += qty;
            }
        }
        // Retrieve guest wishlist count
        java.util.Set<?> guestWishlist = (java.util.Set<?>) session.getAttribute("guest_wishlist");
        if (guestWishlist != null) {
            navWishlistCount = guestWishlist.size();
        }
    }

    // Keep currentCountry synchronized with the resolved session setting
    if (session != null && session.getAttribute("selected_country") != null) {
        currentCountry = (String) session.getAttribute("selected_country");
    }

    String requestURI = request.getRequestURI();
    boolean showAnnouncement = !requestURI.contains("admin") && !requestURI.contains("admin-dashboard.jsp");
%>
<% if (showAnnouncement) { 
    String annMessage = "Complimentary Standard Shipping on Orders Over " + com.mycompany.mavenproject2.CurrencyHelper.formatPrice(1500.0, currentCountry);
    try (java.sql.Connection conAnn = com.mycompany.mavenproject2.DBConnection.getConnection();
         java.sql.PreparedStatement psAnn = conAnn.prepareStatement(
             "SELECT text FROM announcements WHERE is_active = 1 " +
             "AND (start_date IS NULL OR start_date <= CURRENT_TIMESTAMP) " +
             "AND (end_date IS NULL OR end_date >= CURRENT_TIMESTAMP) LIMIT 1")) {
        try (java.sql.ResultSet rsAnn = psAnn.executeQuery()) {
            if (rsAnn.next()) {
                annMessage = rsAnn.getString("text");
            }
        }
    } catch (Exception e) {
        // Fallback to default shipping notice
    }
%>
<div class="announcement-bar">
    <p><%= annMessage %></p>
</div>
<% } %>

<nav class="navbar">
    <button class="nav-hamburger" id="navHamburger" onclick="toggleNavMenu()" aria-label="Toggle menu">
        <i class="fas fa-bars"></i>
    </button>

    <a href="index.jsp" class="logo">LuxeGlow</a>

    <!-- Sitemap Navigation links -->
    <ul class="nav-links" id="navLinks">
        <li><a href="index.jsp">Home</a></li>
        <li><a href="product.jsp">Shop</a></li>
        <li><a href="new-arrivals.jsp">New Arrivals</a></li>
        <li><a href="best-sellers.jsp">Best Sellers</a></li>
        <li><a href="offers.jsp">Offers</a></li>
        <li><a href="gift-sets.jsp">Gift Sets</a></li>
        <li><a href="blog.jsp">Blog</a></li>
        <li><a href="about.jsp">About</a></li>
        <li><a href="contact.jsp">Contact</a></li>
    </ul>

    <!-- Search & Utility Controls -->
    <div class="nav-controls-right">
        <!-- Search bar wrapper -->
        <div class="nav-search-row">
            <form action="product.jsp" method="get" class="nav-search-form">
                <input type="text" name="search" placeholder="Search products..." class="nav-search-input">
                <button type="submit" class="nav-search-btn"><i class="fas fa-search"></i></button>
            </form>
        </div>

        <div class="nav-utils">
            <a href="wishlist.jsp" class="cart-icon-wrapper" title="Wishlist" style="color: var(--burgundy); font-size: 1.1rem; display: inline-flex; align-items: center; position: relative;">
                <i class="far fa-heart"></i>
                <span class="wishlist-count" id="wishlistCount" style="background: var(--gold); color: #FFFFFF; font-size: 0.6rem; font-weight: 700; border-radius: 50%; width: 16px; height: 16px; display: <%= navWishlistCount > 0 ? "flex" : "none" %>; align-items: center; justify-content: center; position: absolute; top: -6px; right: -10px;"><%= navWishlistCount %></span>
            </a>

            <a href="cart.jsp" class="cart-icon-wrapper" title="Shopping Bag" style="color: var(--burgundy); font-size: 1.1rem; display: inline-flex; align-items: center; position: relative;">
                <i class="fas fa-shopping-bag"></i>
                <span class="cart-count" id="cartCount" style="background: var(--burgundy); color: #FFFFFF; font-size: 0.6rem; font-weight: 700; border-radius: 50%; width: 16px; height: 16px; display: flex; align-items: center; justify-content: center; position: absolute; top: -6px; right: -10px;"><%= navCartCount %></span>
            </a>

            <% if (navUsername == null) { %>
                <a href="login.jsp" class="login-btn">Login</a>
            <% } else { %>
                <div class="profile-menu" style="position: relative; display: inline-block;">
                    <div class="profile-circle" style="width: 32px; height: 32px; border-radius: 50%; background: var(--burgundy); color: #FFFFFF; display: flex; align-items: center; justify-content: center; font-weight: 700; font-size: 0.8rem; border: 1px solid rgba(0,0,0,0.05); cursor: pointer; transition: var(--transition);">
                        <%= navUsername.substring(0,1).toUpperCase() %>
                    </div>

                    <div class="dropdown" style="position: absolute; top: 34px; right: 0; background: var(--bg-card); border: 1px solid var(--border-color); border-radius: 16px; min-width: 200px; box-shadow: var(--shadow-lux); overflow: hidden; z-index: 100;">
                        <div style="padding: 12px 20px; font-size: 0.75rem; color: var(--gold); border-bottom: 1px solid var(--border-light)">
                            Hi, <%= navUsername %>
                        </div>
                        <% if ("ADMIN".equalsIgnoreCase(navRole)) { %>
                            <a href="admin" style="display: block; padding: 10px 20px; color: var(--text-secondary); font-size: 0.8rem; text-decoration: none; border-bottom: 1px solid var(--border-light);"><i class="fas fa-chart-line" style="margin-right: 8px;"></i>Admin Panel</a>
                        <% } %>
                        <a href="profile.jsp" style="display: block; padding: 10px 20px; color: var(--text-secondary); font-size: 0.8rem; text-decoration: none;"><i class="fas fa-user" style="margin-right: 8px;"></i>My Profile</a>
                        <a href="orders.jsp" style="display: block; padding: 10px 20px; color: var(--text-secondary); font-size: 0.8rem; text-decoration: none;"><i class="fas fa-history" style="margin-right: 8px;"></i>My Orders</a>
                        <a href="wishlist.jsp" style="display: block; padding: 10px 20px; color: var(--text-secondary); font-size: 0.8rem; text-decoration: none;"><i class="fas fa-heart" style="margin-right: 8px;"></i>My Wishlist</a>
                        <a href="addresses.jsp" style="display: block; padding: 10px 20px; color: var(--text-secondary); font-size: 0.8rem; text-decoration: none;"><i class="fas fa-map-marker-alt" style="margin-right: 8px;"></i>Saved Addresses</a>
                        <div class="dropdown-divider" style="height: 1px; background: var(--border-light);"></div>
                        <a href="logout" style="display: block; padding: 10px 20px; color: var(--text-secondary); font-size: 0.8rem; text-decoration: none;"><i class="fas fa-sign-out-alt" style="margin-right: 8px;"></i>Logout</a>
                    </div>
                </div>
            <% } %>
        </div>
    </div>
</nav>

<!-- CSS logic to handle profile dropdown hover -->
<style>
    .profile-menu:hover .dropdown {
        display: block !important;
    }
    .profile-menu .dropdown {
        display: none;
    }
    .profile-menu .dropdown::before {
        content: '';
        position: absolute;
        top: -15px;
        left: 0;
        right: 0;
        height: 15px;
        background: transparent;
    }
    .dropdown a:hover {
        background: rgba(92, 13, 30, 0.04);
        color: var(--burgundy) !important;
        padding-left: 25px !important;
    }
</style>

<!-- JavaScript to dynamically update cart count and display premium toast notifications -->
<div id="toast-container" style="position: fixed; bottom: 25px; right: 25px; z-index: 10000; display: flex; flex-direction: column; gap: 10px; pointer-events: none;"></div>

<script>
    function refreshCartCount() {
        fetch('CartServlet?action=count')
            .then(res => res.json())
            .then(data => {
                if (data.count !== undefined) {
                    const el = document.getElementById('cartCount');
                    if (el) el.innerText = data.count;
                }
            })
            .catch(err => console.error(err));
    }

    function showToast(message, type = 'success') {
        const container = document.getElementById('toast-container');
        const toast = document.createElement('div');
        toast.style.cssText = 'pointer-events: auto; display: flex; align-items: center; gap: 12px; padding: 16px 24px; border-radius: 12px; font-weight: 500; font-size: 0.9rem; border: 1px solid var(--border-color); background: rgba(20, 14, 16, 0.95); backdrop-filter: blur(10px); box-shadow: var(--shadow-lux); color: white; min-width: 280px; transform: translateY(20px); opacity: 0; transition: all 0.4s cubic-bezier(0.25, 0.8, 0.25, 1);';
        
        let icon = 'fa-check-circle';
        let iconColor = 'var(--gold)';
        if (type === 'danger') {
            icon = 'fa-exclamation-circle';
            iconColor = '#f56c6c';
        } else if (type === 'warning') {
            icon = 'fa-exclamation-triangle';
            iconColor = '#e6a23c';
        }

        toast.innerHTML = `<i class="fas ${icon}" style="color: ${iconColor}; font-size: 1.1rem;"></i><span>${message}</span>`;
        container.appendChild(toast);

        // Trigger animation
        setTimeout(() => {
            toast.style.transform = 'translateY(0)';
            toast.style.opacity = '1';
        }, 50);

        // Remove toast
        setTimeout(() => {
            toast.style.transform = 'translateY(-20px)';
            toast.style.opacity = '0';
            setTimeout(() => {
                toast.remove();
            }, 400);
        }, 3500);
    }

    function toggleWishlist(event, productId) {
        if (event) {
            event.preventDefault();
            event.stopPropagation();
        }

        const heartButtons = document.querySelectorAll(`.wishlist-heart-btn[data-product-id="${productId}"]`);
        
        let isLiked = false;
        if (heartButtons.length > 0) {
            isLiked = heartButtons[0].classList.contains('liked');
        }

        const action = isLiked ? 'remove' : 'add';

        const params = new URLSearchParams();
        params.append('action', action);
        params.append('productId', productId);

        fetch('WishlistServlet', {
            method: 'POST',
            body: params,
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded'
            }
        })
        .then(res => res.json())
        .then(data => {
            if (data.success) {
                const nowLiked = (action === 'add');

                heartButtons.forEach(btn => {
                    const icon = btn.querySelector('i');
                    if (nowLiked) {
                        btn.classList.add('liked');
                        if (icon) {
                            icon.className = 'fas fa-heart';
                            if (icon.style.color) {
                                icon.style.color = '#E23E57';
                            }
                        }
                        btn.setAttribute('title', 'Remove from Wishlist');
                    } else {
                        btn.classList.remove('liked');
                        if (icon) {
                            icon.className = 'far fa-heart';
                            if (icon.style.color) {
                                icon.style.color = 'var(--burgundy)';
                            }
                        }
                        btn.setAttribute('title', 'Add to Wishlist');
                    }
                });

                // Update wishlist count badge
                const wlCountEl = document.getElementById('wishlistCount');
                if (wlCountEl && data.count !== undefined) {
                    wlCountEl.innerText = data.count;
                    wlCountEl.style.display = data.count > 0 ? 'flex' : 'none';
                }

                // If on wishlist.jsp, dynamically hide and remove card on item removal
                if (window.location.pathname.includes('wishlist.jsp') && !nowLiked) {
                    const card = document.getElementById(`card-${productId}`);
                    if (card) {
                        card.style.opacity = '0';
                        card.style.transform = 'scale(0.9)';
                        setTimeout(() => {
                            card.remove();
                            const grid = document.querySelector('.products-grid');
                            if (grid && grid.querySelectorAll('.card').length === 0) {
                                window.location.reload();
                            }
                        }, 300);
                    }
                }

                showToast(nowLiked ? 'Added to Wishlist' : 'Removed from Wishlist', 'success');
            } else {
                showToast(data.error || 'Operation failed', 'danger');
            }
        })
        .catch(err => {
            console.error(err);
            showToast('Please log in or try again.', 'warning');
        });
    }

    function toggleNavMenu() {
        const navLinks = document.getElementById('navLinks');
        const hamburgerIcon = document.querySelector('.nav-hamburger i');
        if (navLinks) {
            navLinks.classList.toggle('active');
            if (navLinks.classList.contains('active')) {
                if (hamburgerIcon) hamburgerIcon.className = 'fas fa-times';
            } else {
                if (hamburgerIcon) hamburgerIcon.className = 'fas fa-bars';
            }
        }
    }
</script>
