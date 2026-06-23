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
%>
<div class="variant-tabs-container" style="display:flex; gap:10px; flex-wrap:wrap; margin-bottom:20px;">
<%
    int activeVarId = 0;
    String activeVarIdStr = request.getParameter("activeVariantId");
    if (activeVarIdStr != null && !activeVarIdStr.trim().isEmpty()) {
        activeVarId = Integer.parseInt(activeVarIdStr.trim());
    }

    try (Connection con = DBConnection.getConnection();
         PreparedStatement psVars = con.prepareStatement(
             "SELECT id, variant_name, color_code, stock, price, custom_label, is_visible FROM product_variants WHERE product_id = ? ORDER BY id ASC")) {
        psVars.setInt(1, productId);
        try (ResultSet rsVars = psVars.executeQuery()) {
            boolean hasVars = false;
            java.util.List<java.util.Map<String, Object>> varList = new java.util.ArrayList<>();
            while (rsVars.next()) {
                hasVars = true;
                java.util.Map<String, Object> v = new java.util.HashMap<>();
                v.put("id", rsVars.getInt("id"));
                v.put("name", rsVars.getString("variant_name"));
                v.put("color", rsVars.getString("color_code"));
                v.put("stock", rsVars.getInt("stock"));
                v.put("price", rsVars.getDouble("price"));
                v.put("hasPriceOverride", !rsVars.wasNull());
                v.put("label", rsVars.getString("custom_label"));
                v.put("visible", rsVars.getInt("is_visible"));
                varList.add(v);
                
                if (activeVarId == 0) {
                    activeVarId = rsVars.getInt("id");
                }
            }

            if (!hasVars) {
%>
                <p style="color:var(--text-muted); font-size:0.85rem; width:100%; text-align:center; padding:20px; border: 1px dashed var(--border-color); border-radius:12px;">No variants configured. Click "Add Shade / Size" to create one.</p>
<%
            } else {
                for (java.util.Map<String, Object> v : varList) {
                    int vId = (Integer) v.get("id");
                    String vName = (String) v.get("name");
                    String vColor = (String) v.get("color");
                    String vLabel = (String) v.get("label");
                    int isVisible = (Integer) v.get("visible");
                    boolean isActive = (vId == activeVarId);
                    
                    String borderStyle = isActive ? "border:2px solid var(--gold);" : "border:1px solid var(--border-light);";
                    String bgStyle = isActive ? "background:var(--burgundy-glow); color:var(--gold);" : "background:var(--bg-surface); color:var(--text-primary);";
%>
                    <button type="button" class="variant-tab-btn" onclick="selectVariantTab(<%= vId %>)" 
                            style="display:flex; align-items:center; gap:8px; padding:10px 16px; border-radius:30px; font-size:0.8rem; font-weight:600; cursor:pointer; transition:all 0.2s ease; <%= borderStyle %> <%= bgStyle %>">
                        <% if (vColor != null && vColor.startsWith("#")) { %>
                            <span style="display:inline-block; width:12px; height:12px; border-radius:50%; border:1px solid rgba(0,0,0,0.15); background-color:<%= vColor %>;"></span>
                        <% } %>
                        <span><%= vName %></span>
                        <% if (vLabel != null && !vLabel.trim().isEmpty()) { %>
                            <span style="font-size:0.7rem; opacity:0.75; font-weight:normal;">(<%= vLabel %>)</span>
                        <% } %>
                        <% if (isVisible == 0) { %>
                            <i class="fas fa-eye-slash" style="font-size:0.75rem; opacity:0.6;"></i>
                        <% } %>
                    </button>
<%
                }
            }
%>
</div>

<%
            // Render active variant form
            if (activeVarId > 0) {
                java.util.Map<String, Object> activeVar = null;
                for (java.util.Map<String, Object> v : varList) {
                    if ((Integer) v.get("id") == activeVarId) {
                        activeVar = v;
                        break;
                    }
                }
                if (activeVar != null) {
                    int vId = (Integer) activeVar.get("id");
                    String vName = (String) activeVar.get("name");
                    String vColor = (String) activeVar.get("color");
                    double vPrice = activeVar.get("price") != null ? (Double) activeVar.get("price") : 0.0;
                    boolean hasOverride = (Boolean) activeVar.get("hasPriceOverride");
                    String vLabel = (String) activeVar.get("label");
                    int isVisible = (Integer) activeVar.get("visible");
                    int vStock = (Integer) activeVar.get("stock");
%>
                    <div class="active-variant-details-pane" style="background:var(--bg-surface); border:1px solid var(--border-light); padding:20px; border-radius:16px; margin-top:15px;">
                        <h4 style="font-family:'Playfair Display', serif; border-bottom:1px solid var(--border-light); padding-bottom:8px; margin-top:0; margin-bottom:15px; color:var(--burgundy); font-size:1.1rem;">
                            Configure Shade/Size: <span style="color:var(--gold);"><%= vName %></span>
                        </h4>
                        
                        <form id="editActiveVariantForm" onsubmit="saveVariantDetails(event, <%= vId %>)">
                            <input type="hidden" name="action" value="editVariant">
                            <input type="hidden" name="variantId" value="<%= vId %>">
                            <input type="hidden" name="productId" value="<%= productId %>">
                            <input type="hidden" name="redirectTab" value="product-details">
                            
                            <div style="display:grid; grid-template-columns:1fr 1fr; gap:15px; margin-bottom:12px;">
                                <div class="form-group" style="text-align:left; margin-bottom:0;">
                                    <label style="font-size:0.75rem; font-weight:600; display:block; margin-bottom:5px;">Variant Name</label>
                                    <input type="text" name="name" value="<%= vName %>" required style="width:100%; padding:8px 12px; border-radius:8px; border:1px solid var(--border-color); background:var(--bg-dark); color:var(--text-primary);">
                                </div>
                                <div class="form-group" style="text-align:left; margin-bottom:0;">
                                    <label style="font-size:0.75rem; font-weight:600; display:block; margin-bottom:5px;">Color Code (Hex/Pill)</label>
                                    <input type="text" name="colorCode" value="<%= vColor %>" required style="width:100%; padding:8px 12px; border-radius:8px; border:1px solid var(--border-color); background:var(--bg-dark); color:var(--text-primary);">
                                </div>
                            </div>
                            
                            <div style="display:grid; grid-template-columns:1fr 1fr; gap:15px; margin-bottom:12px;">
                                <div class="form-group" style="text-align:left; margin-bottom:0;">
                                    <label style="font-size:0.75rem; font-weight:600; display:block; margin-bottom:5px;">Custom Button Label (Optional)</label>
                                    <input type="text" name="customLabel" value="<%= vLabel != null ? vLabel : "" %>" placeholder="e.g. Special Edition" style="width:100%; padding:8px 12px; border-radius:8px; border:1px solid var(--border-color); background:var(--bg-dark); color:var(--text-primary);">
                                </div>
                                <div class="form-group" style="text-align:left; margin-bottom:0;">
                                    <label style="font-size:0.75rem; font-weight:600; display:block; margin-bottom:5px;">Visibility Status</label>
                                    <select name="isVisible" style="width:100%; padding:8px 12px; border-radius:8px; border:1px solid var(--border-color); background:var(--bg-dark); color:var(--text-primary);">
                                        <option value="1" <%= isVisible == 1 ? "selected" : "" %>>Visible on Storefront</option>
                                        <option value="0" <%= isVisible == 0 ? "selected" : "" %>>Hidden / Disabled</option>
                                    </select>
                                </div>
                            </div>
                            
                            <div style="display:grid; grid-template-columns:1fr 1fr; gap:15px; margin-bottom:15px;">
                                <div class="form-group" style="text-align:left; margin-bottom:0;">
                                    <label style="font-size:0.75rem; font-weight:600; display:block; margin-bottom:5px;">Stock Level</label>
                                    <input type="number" name="stock" value="<%= vStock %>" required min="0" style="width:100%; padding:8px 12px; border-radius:8px; border:1px solid var(--border-color); background:var(--bg-dark); color:var(--text-primary);">
                                </div>
                                <div class="form-group" style="text-align:left; margin-bottom:0;">
                                    <label style="font-size:0.75rem; font-weight:600; display:block; margin-bottom:5px;">Price Override (₹)</label>
                                    <input type="number" step="0.01" name="price" value="<%= hasOverride ? vPrice : "" %>" placeholder="Inherit base product price" style="width:100%; padding:8px 12px; border-radius:8px; border:1px solid var(--border-color); background:var(--bg-dark); color:var(--text-primary);">
                                </div>
                            </div>
                            
                            <div style="display:flex; justify-content:space-between; align-items:center; margin-top:20px; border-top:1px solid var(--border-light); padding-top:15px;">
                                <button type="button" onclick="deleteVariantAsync(<%= vId %>, '<%= vName.replace("'", "\\'") %>')" class="btn-outline" style="border-radius:8px; padding:8px 16px; font-size:0.8rem; color:var(--danger); border-color:var(--danger); background:transparent; text-transform:none; font-weight:600;">
                                    <i class="fas fa-trash-alt" style="margin-right:5px;"></i> Delete Shade
                                </button>
                                
                                <button type="submit" class="btn-gold" style="border-radius:8px; padding:8px 20px; font-size:0.8rem; font-weight:600; text-transform:none; margin:0;">
                                    Save Shade Changes
                                </button>
                            </div>
                        </form>
                    </div>
                    
                    <!-- Section 3: Variant Image Editor (Complete list of all images for selected variant) -->
                    <div style="background:var(--bg-surface); border:1px solid var(--border-light); padding:20px; border-radius:16px; margin-top:20px; text-align:left;">
                        <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:15px;">
                            <h4 style="font-family:'Playfair Display', serif; margin:0; color:var(--burgundy); font-size:1.1rem;">
                                Variant Photos: <span style="color:var(--gold);"><%= vName %></span>
                            </h4>
                            <button type="button" class="btn-outline" onclick="openVariantImageUploadModal(<%= vId %>)" style="padding:6px 12px; font-size:0.75rem; border-radius:6px; text-transform:none; cursor:pointer;">
                                <i class="fas fa-upload" style="margin-right:5px;"></i> Upload Variant Photos
                            </button>
                        </div>
                        
                        <!-- Variant Images Grid -->
                        <div id="variantImagesGridContainer" style="display:flex; flex-direction:column; gap:10px;">
                            <!-- Populated dynamically via fetchVariantImages(<%= vId %>) -->
                        </div>
                    </div>
<%
                }
            }
        }
    } catch (Exception e) {
        out.println("<p style='color:var(--danger);'>Error loading variants list: " + e.getMessage() + "</p>");
    }
%>
