<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Contact Our Beauty Experts | LuxeGlow</title>
    <!-- Core Styling -->
    <link rel="stylesheet" href="index.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
</head>
<body>
<!-- Dynamic Glassmorphic Navbar -->
    <%@ include file="navbar.jsp" %>

    <!-- Hero banner -->
    <section class="hero" style="height: 35vh; min-height: 250px;">
        <div class="hero-content">
            <h1 style="font-size: 2.8rem;">Get In Touch</h1>
            <p>Have questions about shade matching, orders, or shipping? Our experts are here to assist you.</p>
        </div>
    </section>

    <!-- Main Content Container -->
    <div class="page-container">
        
        <!-- Alerts for feedback -->
        <%
            String error = request.getParameter("error");
            String success = request.getParameter("success");
            if (error != null) {
        %>
            <div class="alert alert-danger" style="max-width: 900px; margin: 0 auto 30px;">
                <i class="fas fa-exclamation-circle"></i>
                <span><%= error %></span>
            </div>
        <%
            }
            if (success != null) {
        %>
            <div class="alert alert-success" style="max-width: 900px; margin: 0 auto 30px;">
                <i class="fas fa-check-circle"></i>
                <span><%= success %></span>
            </div>
        <%
            }
        %>

        <div class="contact-grid" style="max-width: 1100px; margin: 0 auto;">
            
            <!-- Contact Info Panel -->
            <div class="contact-info-panel">
                <h2 style="font-size: 1.8rem; margin-bottom: 15px;">Luxury Concierge</h2>
                <p style="color: var(--text-secondary); font-size: 0.95rem;">Reach out to our beauty concierge through the channels below, or submit the digital contact form.</p>
                
                <div class="contact-card-item">
                    <i class="fas fa-envelope"></i>
                    <div>
                        <h4>Email Us</h4>
                        <p>concierge@luxeglow.com</p>
                        <span style="font-size: 0.75rem; color: var(--text-muted);">24/7 client response desk</span>
                    </div>
                </div>

                <div class="contact-card-item">
                    <i class="fas fa-phone-alt"></i>
                    <div>
                        <h4>Call Us</h4>
                        <p>+1 (800) 555-GLOW</p>
                        <span style="font-size: 0.75rem; color: var(--text-muted);">Mon - Fri, 9 AM - 6 PM EST</span>
                    </div>
                </div>

                <div class="contact-card-item">
                    <i class="fas fa-map-marker-alt"></i>
                    <div>
                        <h4>Headquarters</h4>
                        <p>5th Avenue, Luxury District<br>New York, NY 10011</p>
                    </div>
                </div>
            </div>

            <!-- Form Wrapper -->
            <div class="contact-info-panel" style="background: var(--bg-card); border-color: var(--border-color);">
                <h2 style="font-size: 1.8rem; margin-bottom: 25px;">Send Us a Message</h2>
                <form action="ContactServlet" method="POST">
                    
                    <div class="form-group">
                        <label for="name">Full Name</label>
                        <input type="text" id="name" name="name" placeholder="Enter your name" required>
                    </div>

                    <div class="form-group">
                        <label for="email">Email Address</label>
                        <input type="email" id="email" name="email" placeholder="name@example.com" pattern="^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$" title="Please enter a valid email address." required>
                    </div>

                    <div class="form-group">
                        <label for="subject">Subject</label>
                        <select id="subject" name="subject" required>
                            <option value="" disabled selected>Select an inquiry category...</option>
                            <option value="order">Order Inquiry & Status Updates</option>
                            <option value="shade">Product Shade Matching Advice</option>
                            <option value="shipping">Shipping, Delivery & Returns</option>
                            <option value="partnership">Wholesale, PR & Partnerships</option>
                        </select>
                    </div>

                    <div class="form-group">
                        <label for="message">Message</label>
                        <textarea id="message" name="message" rows="5" placeholder="How can we assist you today?" required></textarea>
                    </div>

                    <button type="submit" class="btn-gold" style="width: 100%; border-radius: 12px; margin-top: 10px;">Send Message</button>
                </form>
            </div>

        </div>
    </div>

    <!-- Footer -->
    <%@ include file="footer.jsp" %>
    <script>
        document.addEventListener('DOMContentLoaded', () => {
            const form = document.querySelector('form');
            if (form) {
                form.addEventListener('submit', (e) => {
                    const emailInput = document.getElementById('email');
                    if (emailInput) {
                        const email = emailInput.value.trim();
                        const emailRegex = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
                        if (!emailRegex.test(email)) {
                            e.preventDefault();
                            alert("Please enter a valid email address.");
                            emailInput.focus();
                        }
                    }
                });
            }
        });
    </script>
</body>
</html>


