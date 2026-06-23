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
    String varIdStr = request.getParameter("variantId");
    if (prodIdStr == null || prodIdStr.trim().isEmpty() || varIdStr == null || varIdStr.trim().isEmpty()) {
        out.println("<p style='color:var(--danger);'>Error: Missing Product ID or Variant ID</p>");
        return;
    }

    int productId = Integer.parseInt(prodIdStr.trim());
    int variantId = Integer.parseInt(varIdStr.trim());

    try (Connection con = DBConnection.getConnection();
         PreparedStatement ps = con.prepareStatement(
             "SELECT id, image_url, sort_order, is_primary FROM product_images " +
             "WHERE product_id = ? AND variant_id = ? ORDER BY sort_order ASC, id ASC")) {
        
        ps.setInt(1, productId);
        ps.setInt(2, variantId);
        try (ResultSet rs = ps.executeQuery()) {
            boolean hasImages = false;
            while (rs.next()) {
                hasImages = true;
                int imgId = rs.getInt("id");
                String url = rs.getString("image_url");
                int sortOrder = rs.getInt("sort_order");
                int isPrimary = rs.getInt("is_primary");
                
                // Extract filename
                String filename = url;
                if (url.contains("/")) {
                    filename = url.substring(url.lastIndexOf("/") + 1);
                }
%>
<div class="draggable-variant-image-item" 
     draggable="true" 
     data-image-id="<%= imgId %>" 
     data-sort-order="<%= sortOrder %>"
     ondragstart="varDragStart(event)" 
     ondragover="varDragOver(event)" 
     ondrop="varDragDrop(event)"
     style="display:flex; justify-content:space-between; align-items:center; background:var(--bg-surface); padding:10px; border-radius:10px; border:1px solid var(--border-light); cursor: grab; transition: all 0.2s ease; margin-bottom: 8px;">
    
    <div style="display:flex; align-items:center; gap:12px; text-align:left; pointer-events: none;">
        <i class="fas fa-grip-lines" style="color:var(--text-muted); cursor: grab; margin-right:5px; pointer-events: auto;"></i>
        <img src="<%= url %>" style="width:50px; height:50px; object-fit:cover; border-radius:6px; border:1px solid var(--border-color);">
        <div>
            <div style="font-size:0.75rem; color:var(--text-color); font-weight:600; word-break: break-all;"><%= filename %></div>
            <div style="font-size:0.65rem; color:var(--text-muted); margin-top:2px;">Order rank: <%= sortOrder %></div>
        </div>
    </div>
    
    <div style="display:flex; align-items:center; gap:6px;">
        <% if (isPrimary == 1) { %>
            <span style="font-size:0.65rem; font-weight:700; color:var(--gold); border:1px solid var(--gold); padding:3px 8px; border-radius:12px; background:rgba(197,171,87,0.05);"><i class="fas fa-check-circle"></i> Primary</span>
        <% } else { %>
            <button type="button" class="btn-outline" onclick="setPrimaryVariantImage(<%= imgId %>, <%= variantId %>)" style="padding:4px 8px; font-size:0.65rem; border-radius:6px; text-transform:none; cursor:pointer;">Set Primary</button>
        <% } %>
        
        <button type="button" class="btn-outline" onclick="setProductCoverImage('<%= url %>', <%= productId %>)" style="padding:4px 8px; font-size:0.65rem; border-radius:6px; text-transform:none; cursor:pointer;"><i class="fas fa-star" style="margin-right:2px;"></i> Cover</button>
        
        <button type="button" onclick="deleteVariantImage(<%= imgId %>, <%= variantId %>)" style="background:transparent; border:none; color:var(--danger); cursor:pointer; font-size:1.1rem; padding:4px 8px; display:inline-flex; align-items:center;"><i class="fas fa-trash-alt"></i></button>
    </div>
</div>
<%
            }
            if (!hasImages) {
                out.println("<p style='color:var(--text-muted); text-align:center; font-size:0.8rem; padding:20px;'>No variant images uploaded yet.</p>");
            }
        }
    } catch (Exception e) {
        out.println("<p style='color:var(--danger); font-size:0.8rem;'>Error loading variant images: " + e.getMessage() + "</p>");
    }
%>

<script>
    if (typeof varDragSrcEl === 'undefined') {
        var varDragSrcEl = null;
    }

    function varDragStart(e) {
        varDragSrcEl = this;
        e.dataTransfer.effectAllowed = 'move';
        e.dataTransfer.setData('text/html', this.outerHTML);
        this.style.opacity = '0.4';
    }

    function varDragOver(e) {
        if (e.preventDefault) {
            e.preventDefault();
        }
        e.dataTransfer.dropEffect = 'move';
        return false;
    }

    function varDragDrop(e) {
        e.stopPropagation();
        if (varDragSrcEl !== this) {
            let parent = this.parentNode;
            let nextSibling = this.nextSibling === varDragSrcEl ? this : this.nextSibling;
            parent.insertBefore(varDragSrcEl, this);
            parent.insertBefore(this, nextSibling);
            
            recalculateAndSubmitVariantOrder();
        }
        return false;
    }

    function recalculateAndSubmitVariantOrder() {
        const items = document.querySelectorAll('.draggable-variant-image-item');
        const ids = Array.from(items).map(item => item.getAttribute('data-image-id'));
        
        fetch('AdminServlet?format=json', {
            method: 'POST',
            body: new URLSearchParams({
                action: 'reorderProductImages',
                imageOrder: ids.join(','),
                productId: '<%= productId %>',
                redirectTab: 'product-details',
                format: 'json'
            }),
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded'
            }
        }).then(res => res.json()).then(data => {
            if (typeof fetchVariantImages === 'function') {
                fetchVariantImages(<%= variantId %>);
            }
            if (typeof fetchGalleryImages === 'function') {
                fetchGalleryImages(<%= productId %>);
            }
        });
    }

    document.querySelectorAll('.draggable-variant-image-item').forEach(item => {
        item.addEventListener('dragend', function() {
            this.style.opacity = '1';
        });
    });
</script>
