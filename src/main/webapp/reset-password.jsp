<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="com.mycompany.mavenproject2.DBConnection" %>
<%@ page import="com.mycompany.mavenproject2.EmailUtility" %>
<%@ page import="java.util.UUID" %>
<%
    String error = null;
    String success = null;

    String tokenParam = request.getParameter("token");
    boolean hasToken = (tokenParam != null && !tokenParam.trim().isEmpty());

    // Handle form submissions
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String formType = request.getParameter("formType");
        
        if ("requestReset".equals(formType)) {
            String email = request.getParameter("email");
            if (email == null || email.trim().isEmpty()) {
                error = "Email address is required.";
            } else if (!com.mycompany.mavenproject2.ValidationHelper.isValidEmail(email)) {
                error = "Please enter a valid email address.";
            } else {
                Connection con = null;
                PreparedStatement checkPs = null;
                PreparedStatement insertPs = null;
                ResultSet rs = null;
                try {
                    con = DBConnection.getConnection();
                    // 1. Verify email exists in database
                    checkPs = con.prepareStatement("SELECT fullname FROM users WHERE email = ?");
                    checkPs.setString(1, email.trim());
                    rs = checkPs.executeQuery();
                    if (!rs.next()) {
                        error = "No account found with this email address.";
                    } else {
                        String fullName = rs.getString("fullname");
                        
                        // 2. Generate secure token
                        String token = UUID.randomUUID().toString();
                        
                        // 3. Set expiration time to 15 minutes from now
                        long expMillis = System.currentTimeMillis() + (15 * 60 * 1000); // 15 mins
                        Timestamp expiresAt = new Timestamp(expMillis);

                        // 4. Invalidate any existing unused tokens for this email
                        PreparedStatement cleanPs = con.prepareStatement("UPDATE password_resets SET used = 1 WHERE email = ? AND used = 0");
                        cleanPs.setString(1, email.trim());
                        cleanPs.executeUpdate();
                        cleanPs.close();
                        
                        // 5. Insert token
                        insertPs = con.prepareStatement("INSERT INTO password_resets (email, token, expires_at) VALUES (?, ?, ?)");
                        insertPs.setString(1, email.trim());
                        insertPs.setString(2, token);
                        insertPs.setTimestamp(3, expiresAt);
                        insertPs.executeUpdate();
                        
                        // 6. Send reset email conditionally
                        String resetLink = request.getRequestURL().toString() + "?token=" + token;
                        if (EmailUtility.isConfigured()) {
                            EmailUtility.sendPasswordResetEmail(email.trim(), fullName, resetLink, "15 minutes");
                            success = "A secure password reset link has been sent to your email. Please check your inbox.";
                        } else {
                            success = "Password reset link generated successfully (SMTP Service Offline): <a href=\"" + resetLink + "\" style=\"color: var(--gold); text-decoration: underline; font-weight: 600;\">" + resetLink + "</a>";
                        }
                    }
                } catch (Exception e) {
                    error = "Failed to initiate password reset: " + e.getMessage();
                } finally {
                    if (rs != null) try { rs.close(); } catch (Exception e) {}
                    if (checkPs != null) try { checkPs.close(); } catch (Exception e) {}
                    if (insertPs != null) try { insertPs.close(); } catch (Exception e) {}
                    if (con != null) try { con.close(); } catch (Exception e) {}
                }
            }
        } else if ("executeReset".equals(formType)) {
            String token = request.getParameter("token");
            String password = request.getParameter("password");
            String confirmPassword = request.getParameter("confirmPassword");

            if (token == null || token.trim().isEmpty() || password == null || confirmPassword == null ||
                password.trim().isEmpty() || confirmPassword.trim().isEmpty()) {
                error = "All fields are required.";
            } else if (!password.equals(confirmPassword)) {
                error = "Passwords do not match.";
            } else {
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
                    error = "Password does not meet security requirements: Minimum 8 characters, with at least one uppercase letter, one lowercase letter, one number, and one special character.";
                } else {
                    Connection con = null;
                    PreparedStatement checkPs = null;
                    PreparedStatement updatePs = null;
                    PreparedStatement updateTokenPs = null;
                    ResultSet rs = null;
                    try {
                        con = DBConnection.getConnection();
                        // 1. Verify token is still valid
                        checkPs = con.prepareStatement("SELECT email, expires_at, used FROM password_resets WHERE token = ?");
                        checkPs.setString(1, token.trim());
                        rs = checkPs.executeQuery();
                        if (rs.next()) {
                            String email = rs.getString("email");
                            Timestamp expiresAt = rs.getTimestamp("expires_at");
                            int used = rs.getInt("used");

                            if (used == 1 || expiresAt.before(new Timestamp(System.currentTimeMillis()))) {
                                error = "This reset link has expired or has already been used. Please request a new password reset.";
                            } else {
                                con.setAutoCommit(false); // Begin transaction

                                // 2. Update user's password in users table
                                updatePs = con.prepareStatement("UPDATE users SET password = ? WHERE email = ?");
                                updatePs.setString(1, password);
                                updatePs.setString(2, email);
                                updatePs.executeUpdate();

                                // 3. Mark token as used
                                updateTokenPs = con.prepareStatement("UPDATE password_resets SET used = 1 WHERE token = ?");
                                updateTokenPs.setString(1, token.trim());
                                updateTokenPs.executeUpdate();

                                con.commit();
                                response.sendRedirect("login.jsp?success=Password reset successfully! Please sign in with your new password.");
                                con.close();
                                return;
                            }
                        } else {
                            error = "Invalid reset token. Please request a new password reset.";
                        }
                    } catch (Exception e) {
                        error = "Failed to reset password: " + e.getMessage();
                        if (con != null) {
                            try { con.rollback(); } catch (Exception ex) {}
                        }
                    } finally {
                        if (rs != null) try { rs.close(); } catch (Exception e) {}
                        if (checkPs != null) try { checkPs.close(); } catch (Exception e) {}
                        if (updatePs != null) try { updatePs.close(); } catch (Exception e) {}
                        if (updateTokenPs != null) try { updateTokenPs.close(); } catch (Exception e) {}
                        if (con != null) try { con.close(); } catch (Exception e) {}
                    }
                }
            }
        }
    }

    // If it's a GET request with token, validate the token immediately before showing the form
    boolean isTokenValid = false;
    String resetEmail = "";
    if (hasToken && !"POST".equalsIgnoreCase(request.getMethod())) {
        Connection con = null;
        PreparedStatement checkPs = null;
        ResultSet rs = null;
        try {
            con = DBConnection.getConnection();
            checkPs = con.prepareStatement("SELECT email, expires_at, used FROM password_resets WHERE token = ?");
            checkPs.setString(1, tokenParam.trim());
            rs = checkPs.executeQuery();
            if (rs.next()) {
                resetEmail = rs.getString("email");
                Timestamp expiresAt = rs.getTimestamp("expires_at");
                int used = rs.getInt("used");
                if (used == 0 && expiresAt.after(new Timestamp(System.currentTimeMillis()))) {
                    isTokenValid = true;
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            if (rs != null) try { rs.close(); } catch (Exception e) {}
            if (checkPs != null) try { checkPs.close(); } catch (Exception e) {}
            if (con != null) try { con.close(); } catch (Exception e) {}
        }
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Reset Your Password | LuxeGlow</title>
    <!-- Core Styling -->
    <link rel="stylesheet" href="index.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
</head>
<body style="min-height: 100vh; display: flex; align-items: center; justify-content: center; padding: 20px;">

    <!-- Split Screen Auth Container -->
    <div class="auth-container">
        
        <!-- Left Side: Brand Splash -->
        <div class="auth-sidebar">
            <a href="index.jsp" class="logo">LuxeGlow</a>
            <p>"Security & Elegance. Reclaim access to your premium cosmetics and self-care profile."</p>
            <div style="margin-top: 30px; font-size: 0.8rem; color: var(--gold); border: 1px solid var(--border-color); padding: 15px 25px; border-radius: 12px; background: rgba(0,0,0,0.2);">
                <i class="fas fa-key" style="margin-right:8px;"></i> Secure Password Recovery
            </div>
        </div>

        <!-- Right Side: Forms -->
        <div class="auth-form-box">
            
            <div class="auth-toggle-links">
                <a href="#" class="active">Reset Password</a>
            </div>

            <!-- Alerts for errors/success -->
            <% if (error != null) { %>
                <div class="alert alert-danger" style="margin-bottom: 25px; padding: 12px 15px; font-size: 0.85rem;">
                    <i class="fas fa-exclamation-circle"></i>
                    <span><%= error %></span>
                </div>
            <% } %>

            <% if (success != null) { %>
                <div class="alert alert-success" style="margin-bottom: 25px; padding: 12px 15px; font-size: 0.85rem;">
                    <i class="fas fa-check-circle"></i>
                    <span><%= success %></span>
                </div>
            <% } %>

            <% if (!hasToken) { %>
                <!-- STEP 1: Forgot Password Request Form -->
                <h2>Forgot Password?</h2>
                <p class="subtitle">Enter your registered email below to receive a secure password reset link.</p>
                
                <form action="reset-password.jsp" method="POST">
                    <input type="hidden" name="formType" value="requestReset">
                    
                    <div class="form-group">
                        <label for="email">Email Address</label>
                        <input type="email" id="email" name="email" placeholder="name@example.com" pattern="^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$" title="Please enter a valid email address." required>
                    </div>

                    <button type="submit" class="btn-gold" style="width: 100%; border-radius: 12px; margin-top: 15px; padding: 14px;">
                        SEND RESET LINK
                    </button>
                </form>
            <% } else if (!isTokenValid && error == null) { %>
                <!-- Token Invalid/Expired Notice -->
                <h2>Invalid or Expired Link</h2>
                <p class="subtitle" style="color: var(--danger);">The password reset link is invalid, has expired, or has already been used.</p>
                <div style="text-align: center; margin-top: 25px;">
                    <a href="reset-password.jsp" class="btn-gold" style="width:100%; border-radius: 12px; display:block; padding: 14px;">REQUEST NEW LINK</a>
                </div>
            <% } else { %>
                <!-- STEP 2: Execute Reset Form -->
                <h2>Establish New Password</h2>
                <p class="subtitle">Please configure a strong password to secure your account details.</p>

                <form action="reset-password.jsp" method="POST">
                    <input type="hidden" name="formType" value="executeReset">
                    <input type="hidden" name="token" value="<%= tokenParam.replace("\"", "&quot;") %>">

                    <div class="form-group">
                        <label for="password">New Password</label>
                        <div class="password-wrapper">
                            <input type="password" id="password" name="password" placeholder="••••••••" required style="padding-right: 40px; width: 100%;">
                            <i class="far fa-eye toggle-password-btn" id="togglePassword"></i>
                        </div>
                        <ul id="password-requirements" style="list-style: none; padding: 0; margin-top: 10px; font-size: 0.8rem; display: flex; flex-direction: column; gap: 6px;">
                            <li id="req-length" style="color: #D32F2F; display: flex; align-items: center; gap: 6px;"><i class="fas fa-times-circle"></i> Minimum 8 characters</li>
                            <li id="req-uppercase" style="color: #D32F2F; display: flex; align-items: center; gap: 6px;"><i class="fas fa-times-circle"></i> Contains uppercase letter</li>
                            <li id="req-lowercase" style="color: #D32F2F; display: flex; align-items: center; gap: 6px;"><i class="fas fa-times-circle"></i> Contains lowercase letter</li>
                            <li id="req-number" style="color: #D32F2F; display: flex; align-items: center; gap: 6px;"><i class="fas fa-times-circle"></i> Contains number</li>
                            <li id="req-special" style="color: #D32F2F; display: flex; align-items: center; gap: 6px;"><i class="fas fa-times-circle"></i> Contains special character</li>
                        </ul>
                    </div>

                    <div class="form-group">
                        <label for="confirmPassword">Confirm New Password</label>
                        <div class="password-wrapper">
                            <input type="password" id="confirmPassword" name="confirmPassword" placeholder="••••••••" required style="padding-right: 40px; width: 100%;">
                            <i class="far fa-eye toggle-password-btn" id="toggleConfirmPassword"></i>
                        </div>
                    </div>

                    <button type="submit" class="btn-gold" style="width: 100%; border-radius: 12px; margin-top: 15px; padding: 14px;">
                        RESET PASSWORD
                    </button>
                </form>
            <% } %>

            <div style="text-align: center; margin-top: 35px; font-size: 0.85rem; color: var(--text-muted);">
                Remembered your credentials? 
                <a href="login.jsp" style="text-decoration: underline; font-weight: 600;">Sign In</a>
            </div>

        </div>

    </div>

    <script>
        // Toggle password visibility
        document.addEventListener('DOMContentLoaded', () => {
            const togglePassword = document.getElementById('togglePassword');
            const passwordInput = document.getElementById('password');
            if (togglePassword && passwordInput) {
                togglePassword.addEventListener('click', () => {
                    const type = passwordInput.getAttribute('type') === 'password' ? 'text' : 'password';
                    passwordInput.setAttribute('type', type);
                    togglePassword.classList.toggle('fa-eye');
                    togglePassword.classList.toggle('fa-eye-slash');
                });
            }

            const toggleConfirmPassword = document.getElementById('toggleConfirmPassword');
            const confirmPasswordInput = document.getElementById('confirmPassword');
            if (toggleConfirmPassword && confirmPasswordInput) {
                toggleConfirmPassword.addEventListener('click', () => {
                    const type = confirmPasswordInput.getAttribute('type') === 'password' ? 'text' : 'password';
                    confirmPasswordInput.setAttribute('type', type);
                    toggleConfirmPassword.classList.toggle('fa-eye');
                    toggleConfirmPassword.classList.toggle('fa-eye-slash');
                });
            }

            if (passwordInput) {
                const reqLength = document.getElementById('req-length');
                const reqUpper = document.getElementById('req-uppercase');
                const reqLower = document.getElementById('req-lowercase');
                const reqNumber = document.getElementById('req-number');
                const reqSpecial = document.getElementById('req-special');

                function updateIndicator(el, isValid, text) {
                    const icon = el.querySelector('i');
                    if (isValid) {
                        el.style.color = 'var(--success)';
                        if (icon) {
                            icon.className = 'fas fa-check-circle';
                            icon.style.color = 'var(--success)';
                        }
                    } else {
                        el.style.color = '#D32F2F';
                        if (icon) {
                            icon.className = 'fas fa-times-circle';
                            icon.style.color = '#D32F2F';
                        }
                    }
                }

                function validatePassword() {
                    const val = passwordInput.value;
                    const isLengthValid = val.length >= 8;
                    const isUpperValid = /[A-Z]/.test(val);
                    const isLowerValid = /[a-z]/.test(val);
                    const isNumberValid = /[0-9]/.test(val);
                    const isSpecialValid = /[^A-Za-z0-9]/.test(val);

                    updateIndicator(reqLength, isLengthValid, "Minimum 8 characters");
                    updateIndicator(reqUpper, isUpperValid, "Contains uppercase letter");
                    updateIndicator(reqLower, isLowerValid, "Contains lowercase letter");
                    updateIndicator(reqNumber, isNumberValid, "Contains number");
                    updateIndicator(reqSpecial, isSpecialValid, "Contains special character");

                    return isLengthValid && isUpperValid && isLowerValid && isNumberValid && isSpecialValid;
                }

                passwordInput.addEventListener('input', validatePassword);
                
                const form = document.querySelector('form');
                if (form) {
                    form.addEventListener('submit', (e) => {
                        const formType = form.querySelector('input[name="formType"]');
                        if (formType && formType.value === 'executeReset') {
                            if (!validatePassword()) {
                                e.preventDefault();
                                alert("Password does not meet all security requirements.");
                            }
                        } else if (formType && formType.value === 'requestReset') {
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
                        }
                    });
                }
            }
        });
    </script>
</body>
</html>
