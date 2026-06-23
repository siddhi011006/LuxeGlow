package com.mycompany.mavenproject2;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

@WebServlet("/ContactServlet")
public class ContactServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String name = request.getParameter("name");
        String email = request.getParameter("email");
        String subject = request.getParameter("subject");
        String message = request.getParameter("message");

        if (name == null || email == null || subject == null || message == null ||
            name.trim().isEmpty() || email.trim().isEmpty() || subject.trim().isEmpty() || message.trim().isEmpty()) {
            response.sendRedirect("contact.jsp?error=All fields are required.");
            return;
        }

        if (!ValidationHelper.isValidEmail(email)) {
            response.sendRedirect("contact.jsp?error=Please enter a valid email address.");
            return;
        }

        try {
            Connection con = DBConnection.getConnection();
            String sql = "INSERT INTO contact_messages (name, email, subject, message) VALUES (?, ?, ?, ?)";
            PreparedStatement ps = con.prepareStatement(sql);
            ps.setString(1, name.trim());
            ps.setString(2, email.trim());
            ps.setString(3, subject.trim());
            ps.setString(4, message.trim());

            ps.executeUpdate();
            con.close();

            // Trigger admin notification email asynchronously (fails gracefully)
            try {
                EmailUtility.sendContactNotificationEmail(name, email, subject, message);
            } catch (Exception ex) {
                ex.printStackTrace();
            }

            response.sendRedirect("contact.jsp?success=Thank you for contacting us! We will get back to you shortly.");

        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("contact.jsp?error=Error saving message: " + e.getMessage());
        }
    }
}
