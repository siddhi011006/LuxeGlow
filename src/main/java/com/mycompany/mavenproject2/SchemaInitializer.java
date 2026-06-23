package com.mycompany.mavenproject2;

import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

public class SchemaInitializer {
    private static boolean schemaInitialized = false;

    public static synchronized void initializeSchema(Connection con) {
        if (schemaInitialized) {
            return;
        }

        try {
            // 1. Update products table columns
            ensureColumn(con, "products", "brand", "VARCHAR(100) DEFAULT 'LuxeGlow'");
            ensureColumn(con, "products", "sku", "VARCHAR(100) DEFAULT NULL");
            ensureColumn(con, "products", "status", "VARCHAR(50) DEFAULT 'ACTIVE'");
            ensureColumn(con, "products", "meta_title", "VARCHAR(255) DEFAULT NULL");
            ensureColumn(con, "products", "meta_description", "TEXT DEFAULT NULL");
            ensureColumn(con, "products", "meta_keywords", "VARCHAR(255) DEFAULT NULL");

            // 2. Update reviews table columns
            ensureColumn(con, "reviews", "is_hidden", "TINYINT(1) DEFAULT 0");

            // 2b. Update product_variants table columns
            ensureColumn(con, "product_variants", "custom_label", "VARCHAR(255) DEFAULT NULL");
            ensureColumn(con, "product_variants", "is_visible", "TINYINT(1) DEFAULT 1");

            // 3. Create announcements table
            if (!tableExists(con, "announcements")) {
                try (Statement st = con.createStatement()) {
                    String sql = "CREATE TABLE announcements ("
                               + "id INT AUTO_INCREMENT PRIMARY KEY, "
                               + "text VARCHAR(500) NOT NULL, "
                               + "is_active TINYINT(1) DEFAULT 1, "
                               + "start_date TIMESTAMP NULL DEFAULT NULL, "
                               + "end_date TIMESTAMP NULL DEFAULT NULL"
                               + ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci";
                    st.executeUpdate(sql);
                    
                    // Insert default announcement
                    st.executeUpdate("INSERT INTO announcements (text, is_active) VALUES ('Complimentary Standard Shipping on Orders Over ₹1500.00', 1)");
                }
            }

            // 4. Create promotions table
            if (!tableExists(con, "promotions")) {
                try (Statement st = con.createStatement()) {
                    String sql = "CREATE TABLE promotions ("
                               + "id INT AUTO_INCREMENT PRIMARY KEY, "
                               + "name VARCHAR(255) NOT NULL, "
                               + "discount_type VARCHAR(50) NOT NULL, "
                               + "discount_amount DECIMAL(10,2) NOT NULL, "
                               + "target_type VARCHAR(50) NOT NULL, "
                               + "target_value VARCHAR(255) DEFAULT NULL, "
                               + "start_date TIMESTAMP NULL DEFAULT NULL, "
                               + "end_date TIMESTAMP NULL DEFAULT NULL, "
                               + "is_active TINYINT(1) DEFAULT 1"
                               + ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci";
                    st.executeUpdate(sql);
                }
            }

            // 5. Create coupons table
            if (!tableExists(con, "coupons")) {
                try (Statement st = con.createStatement()) {
                    String sql = "CREATE TABLE coupons ("
                               + "id INT AUTO_INCREMENT PRIMARY KEY, "
                               + "code VARCHAR(50) NOT NULL UNIQUE, "
                               + "discount_type VARCHAR(50) NOT NULL, "
                               + "discount_amount DECIMAL(10,2) NOT NULL, "
                               + "expiry_date TIMESTAMP NULL DEFAULT NULL, "
                               + "usage_limit INT DEFAULT NULL, "
                               + "usage_count INT DEFAULT 0, "
                               + "minimum_purchase_amount DECIMAL(10,2) DEFAULT 0.00, "
                               + "is_active TINYINT(1) DEFAULT 1"
                               + ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci";
                    st.executeUpdate(sql);

                    // Insert sample coupons
                    st.executeUpdate("INSERT INTO coupons (code, discount_type, discount_amount, is_active) VALUES ('WELCOME10', 'PERCENTAGE', 10.00, 1)");
                    st.executeUpdate("INSERT INTO coupons (code, discount_type, discount_amount, is_active) VALUES ('FESTIVE15', 'PERCENTAGE', 15.00, 1)");
                    st.executeUpdate("INSERT INTO coupons (code, discount_type, discount_amount, is_active) VALUES ('LUXEGLOW20', 'PERCENTAGE', 20.00, 1)");
                }
            }

            schemaInitialized = true;
        } catch (SQLException e) {
            System.err.println("Schema initialization failed: " + e.getMessage());
            e.printStackTrace();
        }
    }

    private static boolean tableExists(Connection con, String tableName) throws SQLException {
        try (ResultSet rs = con.getMetaData().getTables(null, null, tableName, null)) {
            return rs.next();
        }
    }

    private static boolean columnExists(Connection con, String tableName, String columnName) throws SQLException {
        try (ResultSet rs = con.getMetaData().getColumns(null, null, tableName, columnName)) {
            return rs.next();
        }
    }

    private static void ensureColumn(Connection con, String tableName, String columnName, String columnDefinition) throws SQLException {
        if (!columnExists(con, tableName, columnName)) {
            try (Statement st = con.createStatement()) {
                st.executeUpdate("ALTER TABLE " + tableName + " ADD COLUMN " + columnName + " " + columnDefinition);
            }
        }
    }
}
