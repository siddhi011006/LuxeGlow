<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="com.mycompany.mavenproject2.DBConnection" %>
<%
    // Enforce authentication & admin privileges
    HttpSession sess = request.getSession(false);
    if (sess == null || !"ADMIN".equalsIgnoreCase((String) sess.getAttribute("role"))) {
        response.sendRedirect(request.getContextPath() + "/");
        return;
    }

    String prodIdStr = request.getParameter("productId");
    if (prodIdStr == null || prodIdStr.trim().isEmpty()) {
        out.println("<p style='color:var(--danger);'>Error: Missing Product ID</p>");
        return;
    }

    int productId = Integer.parseInt(prodIdStr.trim());

    try (Connection con = DBConnection.getConnection();
         PreparedStatement ps = con.prepareStatement(
             "SELECT pi.id, pi.image_url, pi.sort_order, pi.is_primary, pi.variant_id, pv.variant_name FROM product_images pi " +
             "LEFT JOIN product_variants pv ON pi.variant_id = pv.id " +
             "WHERE pi.product_id = ? ORDER BY pi.sort_order ASC, pi.id ASC")) {
        
        ps.setInt(1, productId);
        try (ResultSet rs = ps.executeQuery()) {
            boolean hasImages = false;
            while (rs.next()) {
                hasImages = true;
                int imgId = rs.getInt("id");
                String url = rs.getString("image_url");
                int sortOrder = rs.getInt("sort_order");
                int isPrimary = rs.getInt("is_primary");
                String vName = rs.getString("variant_name");
%>
<div class="draggable-image-item" 
     draggable="true" 
     data-image-id="<%= imgId %>" 
     ondragstart="dragStart(event)" 
     ondragover="dragOver(event)" 
     ondrop="dragDrop(event)"
     style="display:flex; justify-content:space-between; align-items:center; background:var(--bg-surface); padding:10px; border-radius:10px; border:1px solid var(--border-light); cursor: grab; transition: all 0.2s ease;">
    
    <div style="display:flex; align-items:center; gap:12px; text-align:left; pointer-events: none;">
        <i class="fas fa-grip-lines" style="color:var(--text-muted); cursor: grab; margin-right:5px; pointer-events: auto;"></i>
        <img src="<%= url %>" style="width:50px; height:50px; object-fit:cover; border-radius:6px; border:1px solid var(--border-color);">
        <div>
            <% if (vName != null) { %>
                <div style="font-size:0.75rem; color:var(--gold); font-weight:600;"><i class="fas fa-tags" style="margin-right:3px;"></i> Variant Image (<%= vName %>)</div>
            <% } else { %>
                <div style="font-size:0.75rem; color:var(--text-muted); font-weight:600;"><i class="fas fa-image" style="margin-right:3px;"></i> Product General Image</div>
            <% } %>
            <div style="font-size:0.65rem; color:var(--text-muted); margin-top:2px;">Sort Order: <%= sortOrder %></div>
        </div>
    </div>
    
    <div style="display:flex; align-items:center; gap:6px;">
        <% if (isPrimary == 1) { %>
            <span style="font-size:0.65rem; font-weight:700; color:var(--gold); border:1px solid var(--gold); padding:3px 8px; border-radius:12px; background:rgba(197,171,87,0.05);"><i class="fas fa-star" style="margin-right:3px;"></i> Main Image</span>
        <% } else { %>
            <button type="button" class="btn-outline" onclick="setPrimaryProductImage(<%= imgId %>, <%= productId %>)" style="padding:4px 8px; font-size:0.65rem; border-radius:6px; text-transform:none; cursor:pointer;">Set Main</button>
        <% } %>
        
        <button type="button" onclick="deleteProductImageAsync(<%= imgId %>, <%= productId %>)" style="background:transparent; border:none; color:var(--danger); cursor:pointer; font-size:1.1rem; padding:4px 8px; display:inline-flex; align-items:center;"><i class="fas fa-trash-alt"></i></button>
    </div>
</div>
<%
            }
            if (!hasImages) {
                out.println("<p style='color:var(--text-muted); text-align:center; font-size:0.8rem; padding:20px;'>No images uploaded yet.</p>");
            }
        }
    } catch (Exception e) {
        out.println("<p style='color:var(--danger); font-size:0.8rem;'>Error loading gallery: " + e.getMessage() + "</p>");
    }
%>

<script>
    let dragSrcEl = null;

    function dragStart(e) {
        dragSrcEl = this;
        e.dataTransfer.effectAllowed = 'move';
        e.dataTransfer.setData('text/html', this.outerHTML);
        this.style.opacity = '0.4';
    }

    function dragOver(e) {
        if (e.preventDefault) {
            e.preventDefault();
        }
        e.dataTransfer.dropEffect = 'move';
        return false;
    }

    function dragDrop(e) {
        e.stopPropagation();
        if (dragSrcEl !== this) {
            // Swap node positions
            let parent = this.parentNode;
            let nextSibling = this.nextSibling === dragSrcEl ? this : this.nextSibling;
            parent.insertBefore(dragSrcEl, this);
            parent.insertBefore(this, nextSibling);
            
            // Post new order to AdminServlet
            recalculateAndSubmitOrder();
        }
        return false;
    }

    function recalculateAndSubmitOrder() {
        const items = document.querySelectorAll('.draggable-image-item');
        const ids = Array.from(items).map(item => item.getAttribute('data-image-id'));
        
        fetch('AdminServlet?format=json', {
            method: 'POST',
            body: new URLSearchParams({
                action: 'reorderProductImages',
                imageOrder: ids.join(','),
                productId: '<%= productId %>',
                redirectTab: 'product-details'
            }),
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded'
            }
        }).then(() => {
            if (typeof fetchGalleryImages === 'function') {
                fetchGalleryImages(<%= productId %>);
            }
        });
    }

    document.querySelectorAll('.draggable-image-item').forEach(item => {
        item.addEventListener('dragend', function() {
            this.style.opacity = '1';
        });
    });
</script>
