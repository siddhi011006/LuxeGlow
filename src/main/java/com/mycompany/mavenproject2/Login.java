package com.mycompany.mavenproject2;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

@WebServlet("/Login")
public class Login extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        String fullname = request.getParameter("fullname");
        String email = request.getParameter("email");
        String password = request.getParameter("password");
        String confirmPassword = request.getParameter("confirmPassword");
        String countryCode = request.getParameter("countryCode");
        String phone = request.getParameter("phone");
        String country = request.getParameter("country");

        if (country == null || country.trim().isEmpty()) {
            country = "India";
        }

        // Simple validation
        if (fullname == null || email == null || password == null || confirmPassword == null ||
            fullname.trim().isEmpty() || email.trim().isEmpty() || password.trim().isEmpty() ||
            countryCode == null || phone == null || countryCode.trim().isEmpty() || phone.trim().isEmpty()) {
            request.setAttribute("error", "All fields are required.");
            request.setAttribute("fullname", fullname);
            request.setAttribute("email", email);
            request.setAttribute("phone", phone);
            request.setAttribute("countryCode", countryCode);
            request.setAttribute("country", country);
            request.getRequestDispatcher("register.jsp").forward(request, response);
            return;
        }

        if (!ValidationHelper.isValidEmail(email)) {
            request.setAttribute("error", "Please enter a valid email address.");
            request.setAttribute("fullname", fullname);
            request.setAttribute("email", email);
            request.setAttribute("phone", phone);
            request.setAttribute("countryCode", countryCode);
            request.setAttribute("country", country);
            request.getRequestDispatcher("register.jsp").forward(request, response);
            return;
        }

        if (!ValidationHelper.isValidPhone(countryCode, phone)) {
            request.setAttribute("error", "Please enter a valid mobile number matching your country format. No letters, special characters, all repeating, or sequential digits are allowed.");
            request.setAttribute("fullname", fullname);
            request.setAttribute("email", email);
            request.setAttribute("phone", phone);
            request.setAttribute("countryCode", countryCode);
            request.setAttribute("country", country);
            request.getRequestDispatcher("register.jsp").forward(request, response);
            return;
        }

        if (!password.equals(confirmPassword)) {
            request.setAttribute("error", "Passwords do not match.");
            request.setAttribute("fullname", fullname);
            request.setAttribute("email", email);
            request.setAttribute("phone", phone);
            request.setAttribute("countryCode", countryCode);
            request.setAttribute("country", country);
            request.getRequestDispatcher("register.jsp").forward(request, response);
            return;
        }

        // Password strength validation
        boolean hasUpper = false;
        boolean hasLower = false;
        boolean hasDigit = false;
        boolean hasSpecial = false;
        if (password.length() >= 8) {
            for (char c : password.toCharArray()) {
                if (Character.isUpperCase(c)) hasUpper = true;
                else if (Character.isLowerCase(c)) hasLower = true;
                else if (Character.isDigit(c)) hasDigit = true;
                else if (!Character.isWhitespace(c)) hasSpecial = true;
            }
        }
        if (!hasUpper || !hasLower || !hasDigit || !hasSpecial || password.length() < 8) {
            request.setAttribute("error", "Password does not meet security requirements: Minimum 8 characters, with at least one uppercase letter, one lowercase letter, one number, and one special character.");
            request.setAttribute("fullname", fullname);
            request.setAttribute("email", email);
            request.setAttribute("phone", phone);
            request.setAttribute("countryCode", countryCode);
            request.setAttribute("country", country);
            request.getRequestDispatcher("register.jsp").forward(request, response);
            return;
        }

        try {
            Connection con = DBConnection.getConnection();

            // Check if email already exists
            String checkSql = "SELECT id FROM users WHERE email = ?";
            PreparedStatement checkPs = con.prepareStatement(checkSql);
            checkPs.setString(1, email);
            ResultSet checkRs = checkPs.executeQuery();
            if (checkRs.next()) {
                request.setAttribute("error", "An account with this email already exists.");
                request.setAttribute("fullname", fullname);
                request.setAttribute("phone", phone);
                request.setAttribute("countryCode", countryCode);
                request.setAttribute("country", country);
                request.getRequestDispatcher("register.jsp").forward(request, response);
                con.close();
                return;
            }

            // Derive username from email (the part before @)
            String username = email.contains("@") ? email.substring(0, email.indexOf("@")) : email;

            // Concatenate phone number correctly
            String fullPhone = countryCode.trim() + phone.trim();

            // Insert new user
            String sql = "INSERT INTO users(fullname, email, password, username, role, phone, country_name) VALUES(?, ?, ?, ?, 'USER', ?, ?)";
            PreparedStatement ps = con.prepareStatement(sql);
            ps.setString(1, fullname);
            ps.setString(2, email);
            ps.setString(3, password);
            ps.setString(4, username);
            ps.setString(5, fullPhone);
            ps.setString(6, country);

            ps.executeUpdate();
            con.close();

            // Trigger welcome email asynchronously (fails gracefully)
            try {
                EmailUtility.sendWelcomeEmail(email, fullname);
            } catch (Exception ex) {
                ex.printStackTrace();
            }

            // Redirect to login page with success message
            response.sendRedirect("login.jsp?success=Account created successfully! Please sign in.");

        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "A database error occurred: " + e.getMessage());
            request.setAttribute("fullname", fullname);
            request.setAttribute("email", email);
            request.setAttribute("phone", phone);
            request.setAttribute("countryCode", countryCode);
            request.setAttribute("country", country);
            request.getRequestDispatcher("register.jsp").forward(request, response);
        }
    }
}