package com.mycompany.mavenproject2;

import java.io.File;
import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Timestamp;
import java.util.List;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import jakarta.servlet.http.Part;

@WebServlet("/AdminServlet")
@MultipartConfig(
    fileSizeThreshold = 1024 * 1024 * 2, // 2MB
    maxFileSize = 1024 * 1024 * 10,      // 10MB
    maxRequestSize = 1024 * 1024 * 50    // 50MB
)
public class AdminServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        // Enforce admin privileges
        HttpSession session = request.getSession(false);
        if (session == null || !"ADMIN".equalsIgnoreCase((String) session.getAttribute("role"))) {
            response.sendRedirect(request.getContextPath() + "/");
            return;
        }
        doPost(request, response);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        // Enforce admin privileges
        HttpSession session = request.getSession(false);
        if (session == null || !"ADMIN".equalsIgnoreCase((String) session.getAttribute("role"))) {
            response.sendRedirect(request.getContextPath() + "/");
            return;
        }

        String action = request.getParameter("action");
        String tab = "products";
        if (action != null) {
            if (action.toLowerCase().contains("order")) {
                tab = "orders";
            } else if (action.toLowerCase().contains("user") || action.toLowerCase().contains("role")) {
                tab = "users";
            } else if (action.toLowerCase().contains("category")) {
                tab = "categories";
            }
        }

        if (action == null) {
            response.sendRedirect("admin?tab=products&error=Missing action parameter.");
            return;
        }

        try {
            Connection con = DBConnection.getConnection();

            if ("add".equalsIgnoreCase(action)) {
                String name = request.getParameter("name");
                String description = request.getParameter("description");
                double price = Double.parseDouble(request.getParameter("price"));
                String category = request.getParameter("category");
                String imageUrl = request.getParameter("imageUrl");
                int stock = Integer.parseInt(request.getParameter("stock"));
                int rating = Integer.parseInt(request.getParameter("rating"));
                String brand = request.getParameter("brand");
                if (brand == null || brand.trim().isEmpty()) brand = "LuxeGlow";
                String sku = request.getParameter("sku");
                String status = request.getParameter("status");
                if (status == null || status.trim().isEmpty()) status = "ACTIVE";
                String metaTitle = request.getParameter("meta_title");
                String metaDescription = request.getParameter("meta_description");
                String metaKeywords = request.getParameter("meta_keywords");

                // Handle optional image file upload
                Part filePart = request.getPart("imageFile");
                if (filePart != null && filePart.getSize() > 0) {
                    String fileName = java.nio.file.Paths.get(filePart.getSubmittedFileName()).getFileName().toString();
                    String uploadPath = request.getServletContext().getRealPath("") + File.separator + "image";
                    File uploadDir = new File(uploadPath);
                    if (!uploadDir.exists()) {
                        uploadDir.mkdirs();
                    }
                    String filePath = uploadPath + File.separator + fileName;
                    filePart.write(filePath);
                    imageUrl = "image/" + fileName;
                }

                String sql = "INSERT INTO products (name, description, price, category, image_url, stock, rating, brand, sku, status, meta_title, meta_description, meta_keywords) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
                PreparedStatement ps = con.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS);
                ps.setString(1, name);
                ps.setString(2, description);
                ps.setDouble(3, price);
                ps.setString(4, category);
                ps.setString(5, imageUrl);
                ps.setInt(6, stock);
                ps.setInt(7, rating);
                ps.setString(8, brand);
                ps.setString(9, sku);
                ps.setString(10, status);
                ps.setString(11, metaTitle);
                ps.setString(12, metaDescription);
                ps.setString(13, metaKeywords);
                ps.executeUpdate();
                
                // Add the primary image to product_images automatically
                ResultSet rsKeys = ps.getGeneratedKeys();
                int newProductId = 0;
                if (rsKeys.next()) {
                    newProductId = rsKeys.getInt(1);
                    String imgSql = "INSERT INTO product_images (product_id, image_url, sort_order, is_primary, variant_id) VALUES (?, ?, 0, 1, NULL)";
                    PreparedStatement imgPs = con.prepareStatement(imgSql);
                    imgPs.setInt(1, newProductId);
                    imgPs.setString(2, imageUrl);
                    imgPs.executeUpdate();
                    imgPs.close();
                }
                
                java.util.Map<String, Object> extra = new java.util.HashMap<>();
                extra.put("productId", newProductId);
                sendRedirectOrJson(request, response, "admin?tab=products&success=Product added successfully!", "success", "Product added successfully!", extra);

            } else if ("edit".equalsIgnoreCase(action)) {
                int id = Integer.parseInt(request.getParameter("id"));
                String name = request.getParameter("name");
                String description = request.getParameter("description");
                double price = Double.parseDouble(request.getParameter("price"));
                String category = request.getParameter("category");
                String imageUrl = request.getParameter("imageUrl");
                int stock = Integer.parseInt(request.getParameter("stock"));
                int rating = Integer.parseInt(request.getParameter("rating"));
                String brand = request.getParameter("brand");
                if (brand == null || brand.trim().isEmpty()) brand = "LuxeGlow";
                String sku = request.getParameter("sku");
                String status = request.getParameter("status");
                if (status == null || status.trim().isEmpty()) status = "ACTIVE";
                String metaTitle = request.getParameter("meta_title");
                String metaDescription = request.getParameter("meta_description");
                String metaKeywords = request.getParameter("meta_keywords");

                // Handle optional image file upload
                Part filePart = request.getPart("imageFile");
                if (filePart != null && filePart.getSize() > 0) {
                    String fileName = java.nio.file.Paths.get(filePart.getSubmittedFileName()).getFileName().toString();
                    String uploadPath = request.getServletContext().getRealPath("") + File.separator + "image";
                    File uploadDir = new File(uploadPath);
                    if (!uploadDir.exists()) {
                        uploadDir.mkdirs();
                    }
                    String filePath = uploadPath + File.separator + fileName;
                    filePart.write(filePath);
                    imageUrl = "image/" + fileName;
                }

                String sql = "UPDATE products SET name=?, description=?, price=?, category=?, image_url=?, stock=?, rating=?, brand=?, sku=?, status=?, meta_title=?, meta_description=?, meta_keywords=? WHERE id=?";
                PreparedStatement ps = con.prepareStatement(sql);
                ps.setString(1, name);
                ps.setString(2, description);
                ps.setDouble(3, price);
                ps.setString(4, category);
                ps.setString(5, imageUrl);
                ps.setInt(6, stock);
                ps.setInt(7, rating);
                ps.setString(8, brand);
                ps.setString(9, sku);
                ps.setString(10, status);
                ps.setString(11, metaTitle);
                ps.setString(12, metaDescription);
                ps.setString(13, metaKeywords);
                ps.setInt(14, id);
                ps.executeUpdate();
                
                java.util.Map<String, Object> extra = new java.util.HashMap<>();
                extra.put("productId", id);
                String redirectTab = request.getParameter("redirectTab");
                String dest = "admin?tab=products&success=Product updated successfully!";
                if ("product-details".equalsIgnoreCase(redirectTab)) {
                    dest = "admin?tab=product-details&id=" + id + "&success=Product updated successfully!";
                }
                sendRedirectOrJson(request, response, dest, "success", "Product updated successfully!", extra);

            } else if ("delete".equalsIgnoreCase(action)) {
                int id = Integer.parseInt(request.getParameter("id"));

                String sql = "DELETE FROM products WHERE id=?";
                PreparedStatement ps = con.prepareStatement(sql);
                ps.setInt(1, id);
                ps.executeUpdate();
                
                sendRedirectOrJson(request, response, "admin?tab=products&success=Product deleted successfully!", "success", "Product deleted successfully!");

            } else if ("updateStock".equalsIgnoreCase(action)) {
                int id = Integer.parseInt(request.getParameter("id"));
                int stock = Integer.parseInt(request.getParameter("stock"));

                String sql = "UPDATE products SET stock=? WHERE id=?";
                PreparedStatement ps = con.prepareStatement(sql);
                ps.setInt(1, stock);
                ps.setInt(2, id);
                ps.executeUpdate();
                ps.close();
                
                String redirectTab = request.getParameter("redirectTab");
                String dest = "admin?tab=products&success=Product stock quantity updated successfully.";
                if ("product-details".equalsIgnoreCase(redirectTab)) {
                    dest = "admin?tab=product-details&id=" + id + "&success=Product stock quantity updated successfully.";
                }
                sendRedirectOrJson(request, response, dest, "success", "Product stock quantity updated successfully.");

            } else if ("toggleProductStatus".equalsIgnoreCase(action)) {
                int id = Integer.parseInt(request.getParameter("id"));
                String currentStatus = null;
                try (PreparedStatement psGet = con.prepareStatement("SELECT status FROM products WHERE id = ?")) {
                    psGet.setInt(1, id);
                    try (ResultSet rsGet = psGet.executeQuery()) {
                        if (rsGet.next()) {
                            currentStatus = rsGet.getString("status");
                        }
                    }
                }
                String newStatus = "ACTIVE".equalsIgnoreCase(currentStatus) ? "DRAFT" : "ACTIVE";
                String sql = "UPDATE products SET status=? WHERE id=?";
                PreparedStatement ps = con.prepareStatement(sql);
                ps.setString(1, newStatus);
                ps.setInt(2, id);
                ps.executeUpdate();
                ps.close();

                String redirectTab = request.getParameter("redirectTab");
                String dest = "admin?tab=products&success=Product visibility status updated successfully.";
                if ("product-details".equalsIgnoreCase(redirectTab)) {
                    dest = "admin?tab=product-details&id=" + id + "&success=Product visibility status updated successfully.";
                }
                sendRedirectOrJson(request, response, dest, "success", "Product visibility status updated successfully.");

            } else if ("updateOrder".equalsIgnoreCase(action)) {
                int orderId = Integer.parseInt(request.getParameter("orderId"));
                String status = request.getParameter("status");

                String sql = "UPDATE orders SET status=? WHERE id=?";
                PreparedStatement ps = con.prepareStatement(sql);
                ps.setString(1, status);
                ps.setInt(2, orderId);
                ps.executeUpdate();
                
                response.sendRedirect("admin?tab=orders&success=Order status updated successfully!");
                
            } else if ("cancelOrder".equalsIgnoreCase(action)) {
                int orderId = Integer.parseInt(request.getParameter("orderId"));

                con.setAutoCommit(false); // Start transaction
                
                // Restock items before cancelling
                String itemsSql = "SELECT product_id, variant_id, quantity FROM order_items WHERE order_id = ?";
                PreparedStatement itemsPs = con.prepareStatement(itemsSql);
                itemsPs.setInt(1, orderId);
                ResultSet itemsRs = itemsPs.executeQuery();

                String restoreProdStock = "UPDATE products SET stock = stock + ? WHERE id = ?";
                PreparedStatement restoreProdPs = con.prepareStatement(restoreProdStock);

                String restoreVarStock = "UPDATE product_variants SET stock = stock + ? WHERE id = ?";
                PreparedStatement restoreVarPs = con.prepareStatement(restoreVarStock);

                while (itemsRs.next()) {
                    int prodId = itemsRs.getInt("product_id");
                    int qty = itemsRs.getInt("quantity");
                    int varId = itemsRs.getInt("variant_id");
                    boolean isVariant = !itemsRs.wasNull();

                    if (isVariant) {
                        restoreVarPs.setInt(1, qty);
                        restoreVarPs.setInt(2, varId);
                        restoreVarPs.addBatch();
                    } else {
                        restoreProdPs.setInt(1, qty);
                        restoreProdPs.setInt(2, prodId);
                        restoreProdPs.addBatch();
                    }
                }
                itemsRs.close();
                itemsPs.close();

                restoreProdPs.executeBatch();
                restoreVarPs.executeBatch();
                restoreProdPs.close();
                restoreVarPs.close();

                // Update orders table with cancellation details
                String sql = "UPDATE orders SET status='CANCELLED', cancellation_reason='Cancelled by Administrator', cancellation_date=CURRENT_TIMESTAMP, cancelled_by='ADMIN' WHERE id=?";
                PreparedStatement ps = con.prepareStatement(sql);
                ps.setInt(1, orderId);
                ps.executeUpdate();
                ps.close();

                con.commit();
                response.sendRedirect("admin?tab=orders&success=Order cancelled successfully.");

            } else if ("toggleUser".equalsIgnoreCase(action)) {
                int userId = Integer.parseInt(request.getParameter("userId"));
                int currentAdminId = (Integer) session.getAttribute("user_id");

                if (userId == currentAdminId) {
                    response.sendRedirect("admin?tab=users&error=You cannot disable your own admin account.");
                    return;
                }

                String sql = "UPDATE users SET enabled = 1 - enabled WHERE id=?";
                PreparedStatement ps = con.prepareStatement(sql);
                ps.setInt(1, userId);
                ps.executeUpdate();
                
                response.sendRedirect("admin?tab=users&success=User account status toggled successfully.");

            } else if ("toggleRole".equalsIgnoreCase(action)) {
                int userId = Integer.parseInt(request.getParameter("userId"));
                int currentAdminId = (Integer) session.getAttribute("user_id");

                if (userId == currentAdminId) {
                    response.sendRedirect("admin?tab=users&error=You cannot alter your own administrative role.");
                    return;
                }

                // Check the user's current role
                String querySql = "SELECT role FROM users WHERE id=?";
                PreparedStatement queryPs = con.prepareStatement(querySql);
                queryPs.setInt(1, userId);
                ResultSet rs = queryPs.executeQuery();
                String currentRole = "USER";
                if (rs.next()) {
                    currentRole = rs.getString("role");
                }
                rs.close();
                queryPs.close();

                // Toggle role between USER and ADMIN
                String newRole = "ADMIN".equalsIgnoreCase(currentRole) ? "USER" : "ADMIN";
                String updateSql = "UPDATE users SET role=? WHERE id=?";
                PreparedStatement updatePs = con.prepareStatement(updateSql);
                updatePs.setString(1, newRole);
                updatePs.setInt(2, userId);
                updatePs.executeUpdate();
                
                response.sendRedirect("admin?tab=users&success=User role updated successfully to " + newRole);

            } else if ("addCategory".equalsIgnoreCase(action)) {
                String name = request.getParameter("name");
                if (name == null || name.trim().isEmpty()) {
                    response.sendRedirect("admin?tab=categories&error=Category name cannot be empty.");
                    return;
                }

                String sql = "INSERT INTO categories (name) VALUES (?)";
                PreparedStatement ps = con.prepareStatement(sql);
                ps.setString(1, name.trim());
                ps.executeUpdate();
                
                response.sendRedirect("admin?tab=categories&success=Category added successfully.");

            } else if ("deleteCategory".equalsIgnoreCase(action)) {
                int categoryId = Integer.parseInt(request.getParameter("id"));

                String sql = "DELETE FROM categories WHERE id=?";
                PreparedStatement ps = con.prepareStatement(sql);
                ps.setInt(1, categoryId);
                ps.executeUpdate();
                
                response.sendRedirect("admin?tab=categories&success=Category deleted successfully.");

            } 
            
            else if ("addVariant".equalsIgnoreCase(action)) {
                int productId = Integer.parseInt(request.getParameter("productId"));
                String name = request.getParameter("name");
                String colorCode = request.getParameter("colorCode");
                int stock = Integer.parseInt(request.getParameter("stock"));
                String priceStr = request.getParameter("price");
                Double price = null;
                if (priceStr != null && !priceStr.trim().isEmpty()) {
                    price = Double.parseDouble(priceStr);
                }
                String customLabel = request.getParameter("customLabel");
                String isVisibleStr = request.getParameter("isVisible");
                int isVisible = 1;
                if (isVisibleStr != null && !isVisibleStr.trim().isEmpty()) {
                    try {
                        isVisible = Integer.parseInt(isVisibleStr.trim());
                    } catch (Exception e) {}
                }

                String sql = "INSERT INTO product_variants (product_id, variant_name, color_code, stock, price, custom_label, is_visible) VALUES (?, ?, ?, ?, ?, ?, ?)";
                PreparedStatement ps = con.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS);
                ps.setInt(1, productId);
                ps.setString(2, name);
                ps.setString(3, colorCode);
                ps.setInt(4, stock);
                if (price != null) {
                    ps.setDouble(5, price);
                } else {
                    ps.setNull(5, java.sql.Types.DECIMAL);
                }
                ps.setString(6, customLabel);
                ps.setInt(7, isVisible);
                ps.executeUpdate();

                ResultSet rsKeys = ps.getGeneratedKeys();
                int variantId = 0;
                if (rsKeys.next()) {
                    variantId = rsKeys.getInt(1);
                }
                ps.close();

                // Upload variant images
                List<String> imageUrls = uploadMultipleFiles(request, "variantImages");
                if (!imageUrls.isEmpty()) {
                    String imgSql = "INSERT INTO product_images (product_id, image_url, sort_order, is_primary, variant_id) VALUES (?, ?, ?, 0, ?)";
                    PreparedStatement imgPs = con.prepareStatement(imgSql);
                    int order = 0;
                    for (String url : imageUrls) {
                        imgPs.setInt(1, productId);
                        imgPs.setString(2, url);
                        imgPs.setInt(3, order++);
                        imgPs.setInt(4, variantId);
                        imgPs.addBatch();
                    }
                    imgPs.executeBatch();
                    imgPs.close();
                }

                java.util.Map<String, Object> extra = new java.util.HashMap<>();
                extra.put("variantId", variantId);
                extra.put("productId", productId);
                
                String redirectTab = request.getParameter("redirectTab");
                String dest = "admin?tab=products&success=Variant added successfully!";
                if ("product-details".equalsIgnoreCase(redirectTab)) {
                    dest = "admin?tab=product-details&id=" + productId + "&success=Variant added successfully!";
                }
                sendRedirectOrJson(request, response, dest, "success", "Variant added successfully!", extra);

            } else if ("editVariant".equalsIgnoreCase(action)) {
                int variantId = Integer.parseInt(request.getParameter("variantId"));
                int productId = Integer.parseInt(request.getParameter("productId"));
                String name = request.getParameter("name");
                String colorCode = request.getParameter("colorCode");
                int stock = Integer.parseInt(request.getParameter("stock"));
                String priceStr = request.getParameter("price");
                Double price = null;
                if (priceStr != null && !priceStr.trim().isEmpty()) {
                    price = Double.parseDouble(priceStr);
                }
                String customLabel = request.getParameter("customLabel");
                String isVisibleStr = request.getParameter("isVisible");
                int isVisible = 1;
                if (isVisibleStr != null && !isVisibleStr.trim().isEmpty()) {
                    try {
                        isVisible = Integer.parseInt(isVisibleStr.trim());
                    } catch (Exception e) {}
                }

                String sql = "UPDATE product_variants SET variant_name = ?, color_code = ?, stock = ?, price = ?, custom_label = ?, is_visible = ? WHERE id = ?";
                PreparedStatement ps = con.prepareStatement(sql);
                ps.setString(1, name);
                ps.setString(2, colorCode);
                ps.setInt(3, stock);
                if (price != null) {
                    ps.setDouble(4, price);
                } else {
                    ps.setNull(4, java.sql.Types.DECIMAL);
                }
                ps.setString(5, customLabel);
                ps.setInt(6, isVisible);
                ps.setInt(7, variantId);
                ps.executeUpdate();
                ps.close();

                // Upload additional variant images
                List<String> imageUrls = uploadMultipleFiles(request, "variantImages");
                if (!imageUrls.isEmpty()) {
                    String imgSql = "INSERT INTO product_images (product_id, image_url, sort_order, is_primary, variant_id) VALUES (?, ?, ?, 0, ?)";
                    PreparedStatement imgPs = con.prepareStatement(imgSql);
                    int order = 0;
                    for (String url : imageUrls) {
                        imgPs.setInt(1, productId);
                        imgPs.setString(2, url);
                        imgPs.setInt(3, order++);
                        imgPs.setInt(4, variantId);
                        imgPs.addBatch();
                    }
                    imgPs.executeBatch();
                    imgPs.close();
                }

                java.util.Map<String, Object> extra = new java.util.HashMap<>();
                extra.put("variantId", variantId);
                extra.put("productId", productId);
                
                String redirectTab = request.getParameter("redirectTab");
                String dest = "admin?tab=products&success=Variant updated successfully!";
                if ("product-details".equalsIgnoreCase(redirectTab)) {
                    dest = "admin?tab=product-details&id=" + productId + "&success=Variant updated successfully!";
                }
                sendRedirectOrJson(request, response, dest, "success", "Variant updated successfully!", extra);

            } else if ("deleteVariant".equalsIgnoreCase(action)) {
                int variantId = Integer.parseInt(request.getParameter("variantId"));
                int productId = 0;
                try (PreparedStatement psGet = con.prepareStatement("SELECT product_id FROM product_variants WHERE id = ?")) {
                    psGet.setInt(1, variantId);
                    try (ResultSet rsGet = psGet.executeQuery()) {
                        if (rsGet.next()) {
                            productId = rsGet.getInt("product_id");
                        }
                    }
                }

                String sql = "DELETE FROM product_variants WHERE id = ?";
                PreparedStatement ps = con.prepareStatement(sql);
                ps.setInt(1, variantId);
                ps.executeUpdate();
                ps.close();

                String redirectTab = request.getParameter("redirectTab");
                String dest = "admin?tab=products&success=Variant deleted successfully.";
                if ("product-details".equalsIgnoreCase(redirectTab) && productId > 0) {
                    dest = "admin?tab=product-details&id=" + productId + "&success=Variant deleted successfully.";
                }
                sendRedirectOrJson(request, response, dest, "success", "Variant deleted successfully.");

            }
            
            // --- NEW: PRODUCT IMAGES GALLERY MANAGEMENT ---
            else if ("uploadProductImages".equalsIgnoreCase(action)) {
                int productId = Integer.parseInt(request.getParameter("productId"));
                
                List<String> imageUrls = uploadMultipleFiles(request, "productImages");
                if (!imageUrls.isEmpty()) {
                    String imgSql = "INSERT INTO product_images (product_id, image_url, sort_order, is_primary, variant_id) VALUES (?, ?, ?, 0, NULL)";
                    PreparedStatement imgPs = con.prepareStatement(imgSql);
                    int order = 0;
                    for (String url : imageUrls) {
                        imgPs.setInt(1, productId);
                        imgPs.setString(2, url);
                        imgPs.setInt(3, order++);
                        imgPs.addBatch();
                    }
                    imgPs.executeBatch();
                    imgPs.close();
                }

                String redirectTab = request.getParameter("redirectTab");
                String dest = "admin?tab=products&success=Images uploaded successfully!";
                if ("product-details".equalsIgnoreCase(redirectTab)) {
                    dest = "admin?tab=product-details&id=" + productId + "&success=Images uploaded successfully!";
                }
                sendRedirectOrJson(request, response, dest, "success", "Images uploaded successfully!");

            } else if ("deleteProductImage".equalsIgnoreCase(action)) {
                int imageId = Integer.parseInt(request.getParameter("imageId"));
                int productId = 0;
                try (PreparedStatement psGet = con.prepareStatement("SELECT product_id FROM product_images WHERE id = ?")) {
                    psGet.setInt(1, imageId);
                    try (ResultSet rsGet = psGet.executeQuery()) {
                        if (rsGet.next()) {
                            productId = rsGet.getInt("product_id");
                        }
                    }
                }

                String sql = "DELETE FROM product_images WHERE id = ?";
                PreparedStatement ps = con.prepareStatement(sql);
                ps.setInt(1, imageId);
                ps.executeUpdate();
                ps.close();

                String redirectTab = request.getParameter("redirectTab");
                String dest = "admin?tab=products&success=Image deleted successfully.";
                if ("product-details".equalsIgnoreCase(redirectTab) && productId > 0) {
                    dest = "admin?tab=product-details&id=" + productId + "&success=Image deleted successfully.";
                }
                sendRedirectOrJson(request, response, dest, "success", "Image deleted successfully.");

            } else if ("setPrimaryProductImage".equalsIgnoreCase(action)) {
                int imageId = Integer.parseInt(request.getParameter("imageId"));
                int productId = Integer.parseInt(request.getParameter("productId"));

                // Clear existing primary
                String clearSql = "UPDATE product_images SET is_primary = 0 WHERE product_id = ? AND variant_id IS NULL";
                PreparedStatement clearPs = con.prepareStatement(clearSql);
                clearPs.setInt(1, productId);
                clearPs.executeUpdate();
                clearPs.close();

                // Set new primary
                String setSql = "UPDATE product_images SET is_primary = 1 WHERE id = ?";
                PreparedStatement setPs = con.prepareStatement(setSql);
                setPs.setInt(1, imageId);
                setPs.executeUpdate();
                setPs.close();

                // Update products.image_url to match primary image URL
                String selectSql = "SELECT image_url FROM product_images WHERE id = ?";
                PreparedStatement selectPs = con.prepareStatement(selectSql);
                selectPs.setInt(1, imageId);
                ResultSet rs = selectPs.executeQuery();
                if (rs.next()) {
                    String primaryUrl = rs.getString("image_url");
                    String updateProductSql = "UPDATE products SET image_url = ? WHERE id = ?";
                    PreparedStatement updateProductPs = con.prepareStatement(updateProductSql);
                    updateProductPs.setString(1, primaryUrl);
                    updateProductPs.setInt(2, productId);
                    updateProductPs.executeUpdate();
                    updateProductPs.close();
                }
                rs.close();
                selectPs.close();

                String redirectTab = request.getParameter("redirectTab");
                String dest = "admin?tab=products&success=Primary image updated successfully.";
                if ("product-details".equalsIgnoreCase(redirectTab)) {
                    dest = "admin?tab=product-details&id=" + productId + "&success=Primary image updated successfully.";
                }
                sendRedirectOrJson(request, response, dest, "success", "Primary image updated successfully.");

            } else if ("reorderProductImages".equalsIgnoreCase(action)) {
                String imageOrder = request.getParameter("imageOrder");
                String sortValStr = request.getParameter("sort_order_val");
                if (sortValStr != null && !sortValStr.trim().isEmpty()) {
                    int sortVal = Integer.parseInt(sortValStr.trim());
                    int imageId = Integer.parseInt(imageOrder.trim());
                    String sql = "UPDATE product_images SET sort_order = ? WHERE id = ?";
                    PreparedStatement ps = con.prepareStatement(sql);
                    ps.setInt(1, sortVal);
                    ps.setInt(2, imageId);
                    ps.executeUpdate();
                    ps.close();
                } else if (imageOrder != null && !imageOrder.trim().isEmpty()) {
                    String[] ids = imageOrder.split(",");
                    String sql = "UPDATE product_images SET sort_order = ? WHERE id = ?";
                    PreparedStatement ps = con.prepareStatement(sql);
                    for (int i = 0; i < ids.length; i++) {
                        ps.setInt(1, i);
                        ps.setInt(2, Integer.parseInt(ids[i].trim()));
                        ps.addBatch();
                    }
                    ps.executeBatch();
                    ps.close();
                }

                String redirectTab = request.getParameter("redirectTab");
                String pIdStr = request.getParameter("productId");
                String dest = "admin?tab=products&success=Image order updated successfully.";
                if ("product-details".equalsIgnoreCase(redirectTab) && pIdStr != null) {
                    dest = "admin?tab=product-details&id=" + pIdStr + "&success=Image order updated successfully.";
                }
                sendRedirectOrJson(request, response, dest, "success", "Image order updated successfully.");

            } else if ("uploadVariantImages".equalsIgnoreCase(action)) {
                int productId = Integer.parseInt(request.getParameter("productId"));
                int variantId = Integer.parseInt(request.getParameter("variantId"));
                
                List<String> imageUrls = uploadMultipleFiles(request, "variantImages");
                if (!imageUrls.isEmpty()) {
                    String imgSql = "INSERT INTO product_images (product_id, image_url, sort_order, is_primary, variant_id) VALUES (?, ?, ?, 0, ?)";
                    PreparedStatement imgPs = con.prepareStatement(imgSql);
                    int order = 0;
                    for (String url : imageUrls) {
                        imgPs.setInt(1, productId);
                        imgPs.setString(2, url);
                        imgPs.setInt(3, order++);
                        imgPs.setInt(4, variantId);
                        imgPs.addBatch();
                    }
                    imgPs.executeBatch();
                    imgPs.close();
                }

                String redirectTab = request.getParameter("redirectTab");
                String dest = "admin?tab=products&success=Variant images uploaded successfully!";
                if ("product-details".equalsIgnoreCase(redirectTab)) {
                    dest = "admin?tab=product-details&id=" + productId + "&variantId=" + variantId + "&success=Variant images uploaded successfully!";
                }
                sendRedirectOrJson(request, response, dest, "success", "Variant images uploaded successfully!");

            } else if ("setPrimaryVariantImage".equalsIgnoreCase(action)) {
                int imageId = Integer.parseInt(request.getParameter("imageId"));
                int variantId = Integer.parseInt(request.getParameter("variantId"));
                int productId = Integer.parseInt(request.getParameter("productId"));

                // Clear existing primary for this variant
                String clearSql = "UPDATE product_images SET is_primary = 0 WHERE variant_id = ?";
                try (PreparedStatement clearPs = con.prepareStatement(clearSql)) {
                    clearPs.setInt(1, variantId);
                    clearPs.executeUpdate();
                }

                // Set new primary
                String setSql = "UPDATE product_images SET is_primary = 1 WHERE id = ?";
                try (PreparedStatement setPs = con.prepareStatement(setSql)) {
                    setPs.setInt(1, imageId);
                    setPs.executeUpdate();
                }

                String redirectTab = request.getParameter("redirectTab");
                String dest = "admin?tab=products&success=Variant primary image updated successfully.";
                if ("product-details".equalsIgnoreCase(redirectTab)) {
                    dest = "admin?tab=product-details&id=" + productId + "&variantId=" + variantId + "&success=Variant primary image updated successfully.";
                }
                sendRedirectOrJson(request, response, dest, "success", "Variant primary image updated successfully.");

            } else if ("setProductCoverImage".equalsIgnoreCase(action)) {
                int productId = Integer.parseInt(request.getParameter("productId"));
                String imageUrl = request.getParameter("imageUrl");

                String sql = "UPDATE products SET image_url = ? WHERE id = ?";
                try (PreparedStatement ps = con.prepareStatement(sql)) {
                    ps.setString(1, imageUrl);
                    ps.setInt(2, productId);
                    ps.executeUpdate();
                }

                String redirectTab = request.getParameter("redirectTab");
                String dest = "admin?tab=products&success=Product cover image updated successfully.";
                if ("product-details".equalsIgnoreCase(redirectTab)) {
                    dest = "admin?tab=product-details&id=" + productId + "&success=Product cover image updated successfully.";
                }
                sendRedirectOrJson(request, response, dest, "success", "Product cover image updated successfully.");

            } else if ("bulkProductAction".equalsIgnoreCase(action)) {
                String operation = request.getParameter("operation");
                String idsStr = request.getParameter("ids");
                if (idsStr != null && !idsStr.trim().isEmpty()) {
                    String[] idArray = idsStr.split(",");
                    if ("delete".equalsIgnoreCase(operation)) {
                        String sql = "DELETE FROM products WHERE id = ?";
                        try (PreparedStatement ps = con.prepareStatement(sql)) {
                            for (String idStr : idArray) {
                                ps.setInt(1, Integer.parseInt(idStr.trim()));
                                ps.addBatch();
                            }
                            ps.executeBatch();
                        }
                    } else if ("activate".equalsIgnoreCase(operation) || "draft".equalsIgnoreCase(operation)) {
                        String statusVal = "activate".equalsIgnoreCase(operation) ? "ACTIVE" : "DRAFT";
                        String sql = "UPDATE products SET status = ? WHERE id = ?";
                        try (PreparedStatement ps = con.prepareStatement(sql)) {
                            for (String idStr : idArray) {
                                ps.setString(1, statusVal);
                                ps.setInt(2, Integer.parseInt(idStr.trim()));
                                ps.addBatch();
                            }
                            ps.executeBatch();
                        }
                    }
                }
                
                String redirectTab = request.getParameter("redirectTab");
                String dest = "admin?tab=products&success=Bulk action completed successfully.";
                sendRedirectOrJson(request, response, dest, "success", "Bulk action completed successfully.");

            } else if ("addPromotion".equalsIgnoreCase(action)) {
                String name = request.getParameter("name");
                String discountType = request.getParameter("discountType");
                double discountAmount = Double.parseDouble(request.getParameter("discountAmount"));
                String targetType = request.getParameter("targetType");
                String targetValue = request.getParameter("targetValue");
                String startDateStr = request.getParameter("startDate");
                String endDateStr = request.getParameter("endDate");
                int isActive = Integer.parseInt(request.getParameter("isActive"));

                String sql = "INSERT INTO promotions (name, discount_type, discount_amount, target_type, target_value, start_date, end_date, is_active) VALUES (?, ?, ?, ?, ?, ?, ?, ?)";
                PreparedStatement ps = con.prepareStatement(sql);
                ps.setString(1, name);
                ps.setString(2, discountType);
                ps.setDouble(3, discountAmount);
                ps.setString(4, targetType);
                ps.setString(5, targetValue);
                ps.setTimestamp(6, parseTimestamp(startDateStr));
                ps.setTimestamp(7, parseTimestamp(endDateStr));
                ps.setInt(8, isActive);
                ps.executeUpdate();
                ps.close();

                String redirectTab = request.getParameter("redirectTab");
                String pId = request.getParameter("productId");
                if ("product-details".equalsIgnoreCase(redirectTab) && pId != null) {
                    response.sendRedirect("admin?tab=product-details&id=" + pId + "&success=Promotion added successfully!");
                } else {
                    response.sendRedirect("admin?tab=promotions&success=Promotion added successfully!");
                }

            } else if ("editPromotion".equalsIgnoreCase(action)) {
                int promotionId = Integer.parseInt(request.getParameter("promotionId"));
                String name = request.getParameter("name");
                String discountType = request.getParameter("discountType");
                double discountAmount = Double.parseDouble(request.getParameter("discountAmount"));
                String targetType = request.getParameter("targetType");
                String targetValue = request.getParameter("targetValue");
                String startDateStr = request.getParameter("startDate");
                String endDateStr = request.getParameter("endDate");
                int isActive = Integer.parseInt(request.getParameter("isActive"));

                String sql = "UPDATE promotions SET name=?, discount_type=?, discount_amount=?, target_type=?, target_value=?, start_date=?, end_date=?, is_active=? WHERE id=?";
                PreparedStatement ps = con.prepareStatement(sql);
                ps.setString(1, name);
                ps.setString(2, discountType);
                ps.setDouble(3, discountAmount);
                ps.setString(4, targetType);
                ps.setString(5, targetValue);
                ps.setTimestamp(6, parseTimestamp(startDateStr));
                ps.setTimestamp(7, parseTimestamp(endDateStr));
                ps.setInt(8, isActive);
                ps.setInt(9, promotionId);
                ps.executeUpdate();
                ps.close();

                response.sendRedirect("admin?tab=promotions&success=Promotion updated successfully!");

            } else if ("deletePromotion".equalsIgnoreCase(action)) {
                int promotionId = Integer.parseInt(request.getParameter("promotionId"));
                String sql = "DELETE FROM promotions WHERE id=?";
                PreparedStatement ps = con.prepareStatement(sql);
                ps.setInt(1, promotionId);
                ps.executeUpdate();
                ps.close();

                String redirectTab = request.getParameter("redirectTab");
                String pId = request.getParameter("productId");
                if ("product-details".equalsIgnoreCase(redirectTab) && pId != null) {
                    response.sendRedirect("admin?tab=product-details&id=" + pId + "&success=Promotion deleted successfully!");
                } else {
                    response.sendRedirect("admin?tab=promotions&success=Promotion deleted successfully.");
                }

            } else if ("addCoupon".equalsIgnoreCase(action)) {
                String code = request.getParameter("code").trim().toUpperCase();
                String discountType = request.getParameter("discountType");
                double discountAmount = Double.parseDouble(request.getParameter("discountAmount"));
                String expiryDateStr = request.getParameter("expiryDate");
                String usageLimitStr = request.getParameter("usageLimit");
                double minPurchase = Double.parseDouble(request.getParameter("minimumPurchase"));
                int isActive = Integer.parseInt(request.getParameter("isActive"));

                String sql = "INSERT INTO coupons (code, discount_type, discount_amount, expiry_date, usage_limit, minimum_purchase_amount, is_active) VALUES (?, ?, ?, ?, ?, ?, ?)";
                PreparedStatement ps = con.prepareStatement(sql);
                ps.setString(1, code);
                ps.setString(2, discountType);
                ps.setDouble(3, discountAmount);
                ps.setTimestamp(4, parseTimestamp(expiryDateStr));
                if (usageLimitStr != null && !usageLimitStr.trim().isEmpty()) {
                    ps.setInt(5, Integer.parseInt(usageLimitStr.trim()));
                } else {
                    ps.setNull(5, java.sql.Types.INTEGER);
                }
                ps.setDouble(6, minPurchase);
                ps.setInt(7, isActive);
                ps.executeUpdate();
                ps.close();

                response.sendRedirect("admin?tab=coupons&success=Coupon added successfully!");

            } else if ("editCoupon".equalsIgnoreCase(action)) {
                int couponId = Integer.parseInt(request.getParameter("couponId"));
                String code = request.getParameter("code").trim().toUpperCase();
                String discountType = request.getParameter("discountType");
                double discountAmount = Double.parseDouble(request.getParameter("discountAmount"));
                String expiryDateStr = request.getParameter("expiryDate");
                String usageLimitStr = request.getParameter("usageLimit");
                double minPurchase = Double.parseDouble(request.getParameter("minimumPurchase"));
                int isActive = Integer.parseInt(request.getParameter("isActive"));

                String sql = "UPDATE coupons SET code=?, discount_type=?, discount_amount=?, expiry_date=?, usage_limit=?, minimum_purchase_amount=?, is_active=? WHERE id=?";
                PreparedStatement ps = con.prepareStatement(sql);
                ps.setString(1, code);
                ps.setString(2, discountType);
                ps.setDouble(3, discountAmount);
                ps.setTimestamp(4, parseTimestamp(expiryDateStr));
                if (usageLimitStr != null && !usageLimitStr.trim().isEmpty()) {
                    ps.setInt(5, Integer.parseInt(usageLimitStr.trim()));
                } else {
                    ps.setNull(5, java.sql.Types.INTEGER);
                }
                ps.setDouble(6, minPurchase);
                ps.setInt(7, isActive);
                ps.setInt(8, couponId);
                ps.executeUpdate();
                ps.close();

                response.sendRedirect("admin?tab=coupons&success=Coupon updated successfully!");

            } else if ("deleteCoupon".equalsIgnoreCase(action)) {
                int couponId = Integer.parseInt(request.getParameter("couponId"));
                String sql = "DELETE FROM coupons WHERE id=?";
                PreparedStatement ps = con.prepareStatement(sql);
                ps.setInt(1, couponId);
                ps.executeUpdate();
                ps.close();

                response.sendRedirect("admin?tab=coupons&success=Coupon deleted successfully.");

            } else if ("toggleCouponStatus".equalsIgnoreCase(action)) {
                int couponId = Integer.parseInt(request.getParameter("couponId"));
                String sql = "UPDATE coupons SET is_active = 1 - is_active WHERE id=?";
                PreparedStatement ps = con.prepareStatement(sql);
                ps.setInt(1, couponId);
                ps.executeUpdate();
                ps.close();

                response.sendRedirect("admin?tab=coupons&success=Coupon status toggled.");

            } else if ("updateAnnouncement".equalsIgnoreCase(action)) {
                String text = request.getParameter("text");
                int isActive = Integer.parseInt(request.getParameter("isActive"));
                String startDateStr = request.getParameter("startDate");
                String endDateStr = request.getParameter("endDate");

                String checkSql = "SELECT id FROM announcements LIMIT 1";
                PreparedStatement checkPs = con.prepareStatement(checkSql);
                ResultSet rsCheck = checkPs.executeQuery();
                if (rsCheck.next()) {
                    int id = rsCheck.getInt("id");
                    String sql = "UPDATE announcements SET text=?, is_active=?, start_date=?, end_date=? WHERE id=?";
                    PreparedStatement ps = con.prepareStatement(sql);
                    ps.setString(1, text);
                    ps.setInt(2, isActive);
                    ps.setTimestamp(3, parseTimestamp(startDateStr));
                    ps.setTimestamp(4, parseTimestamp(endDateStr));
                    ps.setInt(5, id);
                    ps.executeUpdate();
                    ps.close();
                } else {
                    String sql = "INSERT INTO announcements (text, is_active, start_date, end_date) VALUES (?, ?, ?, ?)";
                    PreparedStatement ps = con.prepareStatement(sql);
                    ps.setString(1, text);
                    ps.setInt(2, isActive);
                    ps.setTimestamp(3, parseTimestamp(startDateStr));
                    ps.setTimestamp(4, parseTimestamp(endDateStr));
                    ps.executeUpdate();
                    ps.close();
                }
                rsCheck.close();
                checkPs.close();

                response.sendRedirect("admin?tab=settings&success=Announcement updated successfully!");

            } else if ("toggleReviewVisibility".equalsIgnoreCase(action)) {
                int reviewId = Integer.parseInt(request.getParameter("reviewId"));
                String sql = "UPDATE reviews SET is_hidden = 1 - is_hidden WHERE id=?";
                PreparedStatement ps = con.prepareStatement(sql);
                ps.setInt(1, reviewId);
                ps.executeUpdate();
                ps.close();

                String redirectTab = request.getParameter("redirectTab");
                String pId = request.getParameter("productId");
                if ("product-details".equalsIgnoreCase(redirectTab) && pId != null) {
                    response.sendRedirect("admin?tab=product-details&id=" + pId + "&success=Review visibility toggled.");
                } else {
                    response.sendRedirect("admin?tab=reviews&success=Review visibility toggled.");
                }

            } else if ("updateHeroBanner".equalsIgnoreCase(action)) {
                Part filePart = request.getPart("heroImageFile");
                String redirectDest = "admin?tab=hero";
                if (filePart != null && filePart.getSize() > 0) {
                    String fileName = java.nio.file.Paths.get(filePart.getSubmittedFileName()).getFileName().toString();
                    String nameWithoutExt = fileName;
                    String ext = "";
                    int dotIndex = fileName.lastIndexOf('.');
                    if (dotIndex > 0) {
                        nameWithoutExt = fileName.substring(0, dotIndex);
                        ext = fileName.substring(dotIndex);
                    }
                    String newFileName = nameWithoutExt + "_" + System.currentTimeMillis() + ext;
                    String uploadPath = request.getServletContext().getRealPath("") + File.separator + "image";
                    File uploadDir = new File(uploadPath);
                    if (!uploadDir.exists()) {
                        uploadDir.mkdirs();
                    }
                    String filePath = uploadPath + File.separator + newFileName;
                    filePart.write(filePath);
                    String customHeroImage = "image/" + newFileName;

                    // Save to config file
                    String configPath = request.getServletContext().getRealPath("/WEB-INF/hero_config.txt");
                    File configFile = new File(configPath);
                    try (java.io.FileWriter fw = new java.io.FileWriter(configFile)) {
                        fw.write(customHeroImage);
                    }
                    response.sendRedirect(redirectDest + "&success=Hero image updated successfully.");
                } else {
                    response.sendRedirect(redirectDest + "&error=Please select a valid image file to upload.");
                }

            } else if ("deleteHeroBanner".equalsIgnoreCase(action)) {
                String redirectDest = "admin?tab=hero";
                String configPath = request.getServletContext().getRealPath("/WEB-INF/hero_config.txt");
                File configFile = new File(configPath);
                if (configFile.exists()) {
                    try {
                        String currentImage = "";
                        try (java.io.BufferedReader br = new java.io.BufferedReader(new java.io.FileReader(configFile))) {
                            currentImage = br.readLine();
                        }
                        if (currentImage != null && !currentImage.trim().isEmpty()) {
                            String physicalPath = request.getServletContext().getRealPath("") + File.separator + currentImage.replace('/', File.separatorChar);
                            File imgFile = new File(physicalPath);
                            if (imgFile.exists()) {
                                imgFile.delete();
                            }
                        }
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                    configFile.delete();
                }
                response.sendRedirect(redirectDest + "&success=Hero image deleted. Reverted to default banner.");

            } else if ("deleteReviewAdmin".equalsIgnoreCase(action)) {
                int reviewId = Integer.parseInt(request.getParameter("reviewId"));
                String sql = "DELETE FROM reviews WHERE id=?";
                PreparedStatement ps = con.prepareStatement(sql);
                ps.setInt(1, reviewId);
                ps.executeUpdate();
                ps.close();

                String redirectTab = request.getParameter("redirectTab");
                String pId = request.getParameter("productId");
                if ("product-details".equalsIgnoreCase(redirectTab) && pId != null) {
                    response.sendRedirect("admin?tab=product-details&id=" + pId + "&success=Review deleted successfully.");
                } else {
                    response.sendRedirect("admin?tab=reviews&success=Review deleted successfully.");
                }

            } else {
                response.sendRedirect("admin?tab=products&error=Unknown action: " + action);
            }

            con.close();

        } catch (Exception e) {
            e.printStackTrace();
            String format = request.getParameter("format");
            if ("json".equalsIgnoreCase(format)) {
                response.setContentType("application/json;charset=UTF-8");
                try {
                    java.io.PrintWriter out = response.getWriter();
                    String msg = e.getMessage() != null ? e.getMessage() : "Unknown error";
                    out.print("{\"status\":\"error\",\"message\":\"" + msg.replace("\"", "\\\"") + "\"}");
                    out.flush();
                } catch (IOException ioEx) {
                    ioEx.printStackTrace();
                }
            } else {
                response.sendRedirect("admin?tab=" + tab + "&error=Operation failed: " + java.net.URLEncoder.encode(e.getMessage() != null ? e.getMessage() : "Unknown error", "UTF-8"));
            }
        }
    }

    private void sendRedirectOrJson(HttpServletRequest request, HttpServletResponse response, String redirectUrl, String status, String message) throws IOException {
        sendRedirectOrJson(request, response, redirectUrl, status, message, null);
    }

    private void sendRedirectOrJson(HttpServletRequest request, HttpServletResponse response, String redirectUrl, String status, String message, java.util.Map<String, Object> extra) throws IOException {
        String format = request.getParameter("format");
        if ("json".equalsIgnoreCase(format)) {
            response.setContentType("application/json;charset=UTF-8");
            java.io.PrintWriter out = response.getWriter();
            StringBuilder sb = new StringBuilder();
            sb.append("{");
            sb.append("\"status\":\"").append(status.replace("\"", "\\\"")).append("\",");
            sb.append("\"message\":\"").append(message.replace("\"", "\\\"")).append("\"");
            if (extra != null && !extra.isEmpty()) {
                for (java.util.Map.Entry<String, Object> entry : extra.entrySet()) {
                    sb.append(",\"");
                    sb.append(entry.getKey().replace("\"", "\\\""));
                    sb.append("\":");
                    Object val = entry.getValue();
                    if (val instanceof Number) {
                        sb.append(val);
                    } else if (val instanceof Boolean) {
                        sb.append(val);
                    } else if (val == null) {
                        sb.append("null");
                    } else {
                        sb.append("\"").append(val.toString().replace("\"", "\\\"")).append("\"");
                    }
                }
            }
            sb.append("}");
            out.print(sb.toString());
            out.flush();
        } else {
            response.sendRedirect(redirectUrl);
        }
    }

    private Timestamp parseTimestamp(String str) {
        if (str == null || str.trim().isEmpty()) {
            return null;
        }
        String clean = str.replace("T", " ").trim();
        if (clean.length() == 16) {
            clean += ":00";
        }
        try {
            return Timestamp.valueOf(clean);
        } catch (Exception e) {
            return null;
        }
    }

    // Helper method to upload multiple files
    private List<String> uploadMultipleFiles(HttpServletRequest request, String paramName) throws ServletException, IOException {
        List<String> urls = new java.util.ArrayList<>();
        for (Part part : request.getParts()) {
            if (part.getName().equals(paramName) && part.getSize() > 0) {
                String fileName = java.nio.file.Paths.get(part.getSubmittedFileName()).getFileName().toString();
                // Ensure a unique filename to prevent overwrite conflicts
                String uniqueFileName = System.currentTimeMillis() + "_" + fileName;
                String uploadPath = request.getServletContext().getRealPath("") + File.separator + "image";
                File uploadDir = new File(uploadPath);
                if (!uploadDir.exists()) {
                    uploadDir.mkdirs();
                }
                String filePath = uploadPath + File.separator + uniqueFileName;
                part.write(filePath);
                urls.add("image/" + uniqueFileName);
            }
        }
        return urls;
    }
}
