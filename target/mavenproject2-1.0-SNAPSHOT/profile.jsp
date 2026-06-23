<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="com.mycompany.mavenproject2.DBConnection" %>
<%
    // Authenticate user
    HttpSession s = request.getSession(false);
    if (s == null || s.getAttribute("user_id") == null) {
        response.sendRedirect("login.jsp?error=Please sign in to view your profile.&redirect=profile.jsp");
        return;
    }

    int userId = (Integer) s.getAttribute("user_id");
    String error = null;
    String success = null;

    // Handle profile update form submission (self-POST)
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String formAction = request.getParameter("action");
        if ("updateProfile".equals(formAction)) {
            String fullname = request.getParameter("fullname");
            String username = request.getParameter("username");
            String email = request.getParameter("email");
            String countryCode = request.getParameter("countryCode");
            String phoneParam = request.getParameter("phone");

            String fullPhone = null;
            if (countryCode != null && phoneParam != null && !phoneParam.trim().isEmpty()) {
                fullPhone = countryCode.trim() + phoneParam.trim();
            }

            if (fullname == null || username == null || email == null ||
                fullname.trim().isEmpty() || username.trim().isEmpty() || email.trim().isEmpty()) {
                error = "All fields are required.";
            } else if (!com.mycompany.mavenproject2.ValidationHelper.isValidEmail(email)) {
                error = "Please enter a valid email address.";
            } else if (phoneParam == null || phoneParam.trim().isEmpty() || !com.mycompany.mavenproject2.ValidationHelper.isValidPhone(countryCode, phoneParam)) {
                error = "Please enter a valid mobile number matching your country format. No letters, special characters, repeating, or sequential digits are allowed.";
            } else {
                Connection con = null;
                PreparedStatement ps = null;
                try {
                    con = DBConnection.getConnection();
                    String updateSql = "UPDATE users SET fullname = ?, username = ?, email = ?, phone = ? WHERE id = ?";
                    ps = con.prepareStatement(updateSql);
                    ps.setString(1, fullname.trim());
                    ps.setString(2, username.trim());
                    ps.setString(3, email.trim());
                    ps.setString(4, fullPhone);
                    ps.setInt(5, userId);
                    ps.executeUpdate();
                    
                    // Update session attributes if username changed
                    s.setAttribute("username", username.trim());
                    success = "Profile details updated successfully!";
                } catch (Exception e) {
                    error = "Failed to update profile: " + e.getMessage();
                } finally {
                    if (ps != null) try { ps.close(); } catch (Exception e) {}
                    if (con != null) try { con.close(); } catch (Exception e) {}
                }
            }
        } else if ("changePassword".equals(formAction)) {
            String oldPass = request.getParameter("oldPassword");
            String newPass = request.getParameter("newPassword");
            String confirmPass = request.getParameter("confirmPassword");

            if (oldPass == null || newPass == null || confirmPass == null ||
                oldPass.isEmpty() || newPass.isEmpty() || confirmPass.isEmpty()) {
                error = "All password fields are required.";
            } else if (!newPass.equals(confirmPass)) {
                error = "New passwords do not match.";
            } else {
                boolean hasUpper = false;
                boolean hasLower = false;
                boolean hasDigit = false;
                boolean hasSpecial = false;
                if (newPass.length() >= 8) {
                    for (char c : newPass.toCharArray()) {
                        if (Character.isUpperCase(c)) hasUpper = true;
                        else if (Character.isLowerCase(c)) hasLower = true;
                        else if (Character.isDigit(c)) hasDigit = true;
                        else if (!Character.isWhitespace(c)) hasSpecial = true;
                    }
                }
                if (!hasUpper || !hasLower || !hasDigit || !hasSpecial || newPass.length() < 8) {
                    error = "New password does not meet security requirements: Minimum 8 characters, with at least one uppercase letter, one lowercase letter, one number, and one special character.";
                } else {
                    Connection con = null;
                    PreparedStatement checkPs = null;
                    PreparedStatement updatePs = null;
                    ResultSet rs = null;
                    try {
                        con = DBConnection.getConnection();
                        checkPs = con.prepareStatement("SELECT password FROM users WHERE id = ?");
                        checkPs.setInt(1, userId);
                        rs = checkPs.executeQuery();
                        if (rs.next()) {
                            String currentPass = rs.getString("password");
                            if (!currentPass.equals(oldPass)) {
                                error = "Incorrect current password.";
                            } else {
                                updatePs = con.prepareStatement("UPDATE users SET password = ? WHERE id = ?");
                                updatePs.setString(1, newPass);
                                updatePs.setInt(2, userId);
                                updatePs.executeUpdate();
                                success = "Password changed successfully!";
                            }
                        }
                    } catch (Exception e) {
                        error = "Failed to change password: " + e.getMessage();
                    } finally {
                        if (rs != null) try { rs.close(); } catch (Exception e) {}
                        if (checkPs != null) try { checkPs.close(); } catch (Exception e) {}
                        if (updatePs != null) try { updatePs.close(); } catch (Exception e) {}
                        if (con != null) try { con.close(); } catch (Exception e) {}
                    }
                }
            }
        }
    }

    // Load current profile data
    String fullname = "";
    String username = "";
    String email = "";
    String role = "";
    String phone = "";

    // Stats
    int orderCount = 0;
    double totalSpent = 0.0;

    Connection con = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    try {
        con = DBConnection.getConnection();
        ps = con.prepareStatement("SELECT fullname, username, email, role, phone FROM users WHERE id = ?");
        ps.setInt(1, userId);
        rs = ps.executeQuery();
        if (rs.next()) {
            fullname = rs.getString("fullname");
            username = rs.getString("username");
            email = rs.getString("email");
            role = rs.getString("role");
            phone = rs.getString("phone");
        }
        rs.close();
        ps.close();

        // Calculate stats
        ps = con.prepareStatement("SELECT COUNT(*), SUM(total_amount) FROM orders WHERE user_id = ?");
        ps.setInt(1, userId);
        rs = ps.executeQuery();
        if (rs.next()) {
            orderCount = rs.getInt(1);
            totalSpent = rs.getDouble(2);
        }
    } catch (Exception e) {
        e.printStackTrace();
    } finally {
        if (rs != null) try { rs.close(); } catch (Exception e) {}
        if (ps != null) try { ps.close(); } catch (Exception e) {}
        if (con != null) try { con.close(); } catch (Exception e) {}
    }

    // Parse stored phone value
    String currentCountryCode = "+91"; // default
    String currentRawPhone = "";
    if (phone != null && !phone.trim().isEmpty()) {
        String[] codes = {"+971", "+91", "+44", "+61", "+81", "+86", "+49", "+33", "+65", "+1"};
        for (String code : codes) {
            if (phone.startsWith(code)) {
                currentCountryCode = code;
                currentRawPhone = phone.substring(code.length()).trim();
                break;
            }
        }
        if (currentRawPhone.isEmpty()) {
            currentRawPhone = phone;
        }
    }

%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My Profile Dashboard | LuxeGlow</title>
    <!-- Core Styling -->
    <link rel="stylesheet" href="index.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
</head>
<body>
<!-- Include Glassmorphic Header -->
    <%@ include file="navbar.jsp" %>

    <div class="page-container" style="padding: 60px 8%; max-width: 1200px; margin: 0 auto; text-align: left;">
        
        <!-- Alerts -->
        <% if (error != null) { %>
            <div class="alert alert-danger" style="margin-bottom: 25px;">
                <i class="fas fa-exclamation-circle"></i>
                <span><%= error %></span>
            </div>
        <% } %>
        <% if (success != null) { %>
            <div class="alert alert-success" style="margin-bottom: 25px;">
                <i class="fas fa-check-circle"></i>
                <span><%= success %></span>
            </div>
        <% } %>

        <h1 style="font-family:'Playfair Display', serif; font-size: 2.2rem; color: var(--burgundy); margin-bottom: 30px;">My Account Dashboard</h1>

        <!-- Account Layout -->
        <div class="profile-layout-grid">
            
            <!-- Left Sidebar Card -->
            <div style="background: var(--bg-card); border-radius: 20px; border: 1px solid var(--border-light); padding: 30px; box-shadow: var(--shadow-lux); text-align: center;">
                <div style="width: 80px; height: 80px; border-radius: 50%; background: var(--burgundy); color: white; display: flex; align-items: center; justify-content: center; font-size: 2rem; font-weight: 700; margin: 0 auto 20px;">
                    <%= username.substring(0,1).toUpperCase() %>
                </div>
                <h3 style="font-family:'Playfair Display', serif; font-size: 1.3rem; margin-bottom: 5px; color: var(--burgundy);"><%= fullname %></h3>
                <p style="font-size: 0.8rem; color: var(--gold); font-weight: 600; text-transform: uppercase; letter-spacing: 1px; margin-bottom: 20px;"><%= role %> Membership</p>
                
                <div style="border-top: 1px solid var(--border-light); padding-top: 20px; display: grid; grid-template-columns: 1fr 1fr; gap: 10px; margin-top: 20px;">
                    <div>
                        <div style="font-size: 1.4rem; font-weight: 700; color: var(--burgundy);"><%= orderCount %></div>
                        <div style="font-size: 0.75rem; color: var(--text-muted);">Orders Placed</div>
                    </div>
                    <div>
                        <div style="font-size: 1.4rem; font-weight: 700; color: var(--burgundy);"><%= com.mycompany.mavenproject2.CurrencyHelper.formatPrice(totalSpent, currentCountry) %></div>
                        <div style="font-size: 0.75rem; color: var(--text-muted);">Total Spent</div>
                    </div>
                </div>

                <div style="border-top: 1px solid var(--border-light); padding-top: 20px; margin-top: 20px; display:flex; flex-direction:column; gap:10px; text-align:left;">
                    <a href="orders.jsp" style="font-size: 0.85rem; color: var(--text-secondary); font-weight: 555; display:flex; align-items:center; gap:8px;"><i class="fas fa-history" style="color:var(--gold);"></i> View Purchase History</a>
                    <a href="addresses.jsp" style="font-size: 0.85rem; color: var(--text-secondary); font-weight: 555; display:flex; align-items:center; gap:8px;"><i class="fas fa-map-marker-alt" style="color:var(--gold);"></i> Manage Saved Addresses</a>
                    <a href="wishlist.jsp" style="font-size: 0.85rem; color: var(--text-secondary); font-weight: 555; display:flex; align-items:center; gap:8px;"><i class="fas fa-heart" style="color:var(--gold);"></i> View Wishlist Items</a>
                </div>
            </div>

            <!-- Right Profile Settings and Stats -->
            <div style="display: flex; flex-direction: column; gap: 30px;">
                
                <!-- Profile Settings Card -->
                <div style="background: var(--bg-card); border-radius: 20px; border: 1px solid var(--border-light); padding: 35px; box-shadow: var(--shadow-lux);">
                    <h3 style="font-family:'Playfair Display', serif; font-size: 1.4rem; color: var(--burgundy); margin-bottom: 25px; border-bottom: 1px solid var(--border-light); padding-bottom: 10px;">Account Profile Details</h3>
                    <form action="profile.jsp" method="POST">
                        <input type="hidden" name="action" value="updateProfile">
                        
                        <div class="form-group" style="margin-bottom: 20px;">
                            <label style="font-weight:600; font-size:0.85rem; display:block; margin-bottom:6px;">Full Name</label>
                            <input type="text" name="fullname" value="<%= fullname %>" required style="width: 100%; border-radius: 30px; padding: 12px 18px; border: 1px solid var(--border-color); outline:none;">
                        </div>

                        <div class="form-two-col-grid">
                            <div class="form-group">
                                <label style="font-weight:600; font-size:0.85rem; display:block; margin-bottom:6px;">Username</label>
                                <input type="text" name="username" value="<%= username %>" required style="width: 100%; border-radius: 30px; padding: 12px 18px; border: 1px solid var(--border-color); outline:none;">
                            </div>
                            <div class="form-group">
                                <label style="font-weight:600; font-size:0.85rem; display:block; margin-bottom:6px;">Email Address</label>
                                <input type="email" name="email" value="<%= email %>" pattern="^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$" title="Please enter a valid email address." required style="width: 100%; border-radius: 30px; padding: 12px 18px; border: 1px solid var(--border-color); outline:none;">
                            </div>
                        </div>

                        <div class="form-group" style="margin-bottom: 20px;">
                            <label style="font-weight:600; font-size:0.85rem; display:block; margin-bottom:6px;">Mobile Number</label>
                            <div class="phone-group-container">
                                <div class="country-select-wrapper" style="position: relative;">
                                    <div id="selected-country-box" class="selected-country-box">
                                        <span id="selected-country-display">
                                            <%= "+1".equals(currentCountryCode) ? "🇺🇸 +1" :
                                                "+44".equals(currentCountryCode) ? "🇬🇧 +44" :
                                                "+61".equals(currentCountryCode) ? "🇦🇺 +61" :
                                                "+971".equals(currentCountryCode) ? "🇦🇪 +971" :
                                                "+81".equals(currentCountryCode) ? "🇯🇵 +81" :
                                                "+86".equals(currentCountryCode) ? "🇨🇳 +86" :
                                                "+49".equals(currentCountryCode) ? "🇩🇪 +49" :
                                                "+33".equals(currentCountryCode) ? "🇫🇷 +33" :
                                                "+65".equals(currentCountryCode) ? "🇸🇬 +65" : "🇮🇳 +91" %>
                                        </span>
                                        <i class="fas fa-chevron-down" style="font-size: 0.8rem; color: var(--text-muted);"></i>
                                    </div>
                                    <input type="hidden" id="countryCode" name="countryCode" value="<%= currentCountryCode %>">
                                    
                                    <div id="country-dropdown-list" class="country-dropdown-list">
                                        <input type="text" id="country-search" placeholder="Search country..." style="width: 100%; border-radius: 8px; padding: 8px 12px; border: 1px solid var(--border-color); background: rgba(255,255,255,0.05); color: white; outline: none; margin-bottom: 8px; font-size: 0.85rem; box-sizing: border-box;">
                                        <div id="country-options" style="display: flex; flex-direction: column; gap: 4px;">
                                            <div class="country-opt" data-code="+91" data-search="India +91 IN">
                                                <span>🇮🇳 India</span>
                                                <span style="color: var(--gold); font-weight: 600;">+91</span>
                                            </div>
                                            <div class="country-opt" data-code="+1" data-search="United States +1 US">
                                                <span>🇺🇸 United States</span>
                                                <span style="color: var(--gold); font-weight: 600;">+1</span>
                                            </div>
                                            <div class="country-opt" data-code="+44" data-search="United Kingdom +44 UK">
                                                <span>🇬🇧 United Kingdom</span>
                                                <span style="color: var(--gold); font-weight: 600;">+44</span>
                                            </div>
                                            <div class="country-opt" data-code="+61" data-search="Australia +61 AU">
                                                <span>🇦🇺 Australia</span>
                                                <span style="color: var(--gold); font-weight: 600;">+61</span>
                                            </div>
                                            <div class="country-opt" data-code="+971" data-search="UAE United Arab Emirates +971 AE">
                                                <span>🇦🇪 UAE</span>
                                                <span style="color: var(--gold); font-weight: 600;">+971</span>
                                            </div>
                                            <div class="country-opt" data-code="+1" data-search="Canada +1 CA">
                                                <span>🇨🇦 Canada</span>
                                                <span style="color: var(--gold); font-weight: 600;">+1</span>
                                            </div>
                                            <div class="country-opt" data-code="+81" data-search="Japan +81 JP">
                                                <span>🇯🇵 Japan</span>
                                                <span style="color: var(--gold); font-weight: 600;">+81</span>
                                            </div>
                                            <div class="country-opt" data-code="+86" data-search="China +86 CN">
                                                <span>🇨🇳 China</span>
                                                <span style="color: var(--gold); font-weight: 600;">+86</span>
                                            </div>
                                            <div class="country-opt" data-code="+49" data-search="Germany +49 DE">
                                                <span>🇩🇪 Germany</span>
                                                <span style="color: var(--gold); font-weight: 600;">+49</span>
                                            </div>
                                            <div class="country-opt" data-code="+33" data-search="France +33 FR">
                                                <span>🇫🇷 France</span>
                                                <span style="color: var(--gold); font-weight: 600;">+33</span>
                                            </div>
                                            <div class="country-opt" data-code="+65" data-search="Singapore +65 SG">
                                                <span>🇸🇬 Singapore</span>
                                                <span style="color: var(--gold); font-weight: 600;">+65</span>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                                <input type="tel" id="phone" name="phone" placeholder="9876543210" pattern="\d{10,15}" title="Please enter a valid mobile number (10 to 15 digits)" required style="flex: 1; border-radius: 30px; padding: 12px 18px; border: 1px solid var(--border-color); outline:none;" value="<%= currentRawPhone %>">
                            </div>
                        </div>

                        <button type="submit" class="btn-gold" style="border-radius: 30px; font-size: 0.8rem; padding: 12px 30px; margin:0;">Save Profile Updates</button>
                    </form>
                </div>

                <!-- Password Change Card -->
                <div style="background: var(--bg-card); border-radius: 20px; border: 1px solid var(--border-light); padding: 35px; box-shadow: var(--shadow-lux);">
                    <h3 style="font-family:'Playfair Display', serif; font-size: 1.4rem; color: var(--burgundy); margin-bottom: 25px; border-bottom: 1px solid var(--border-light); padding-bottom: 10px;">Security Credentials</h3>
                    <form action="profile.jsp" method="POST">
                        <input type="hidden" name="action" value="changePassword">

                        <div class="form-group" style="margin-bottom: 20px;">
                            <label style="font-weight:600; font-size:0.85rem; display:block; margin-bottom:6px;">Current Password</label>
                            <div class="password-wrapper">
                                <input type="password" id="oldPassword" name="oldPassword" required style="width: 100%; border-radius: 30px; padding: 12px 18px; padding-right: 40px; border: 1px solid var(--border-color); outline:none;">
                                <i class="far fa-eye toggle-password-btn" id="toggleOldPassword"></i>
                            </div>
                        </div>

                        <div class="form-two-col-grid">
                            <div class="form-group">
                                <label style="font-weight:600; font-size:0.85rem; display:block; margin-bottom:6px;">New Password</label>
                                <div class="password-wrapper">
                                    <input type="password" id="newPassword" name="newPassword" required style="width: 100%; border-radius: 30px; padding: 12px 18px; padding-right: 40px; border: 1px solid var(--border-color); outline:none;">
                                    <i class="far fa-eye toggle-password-btn" id="toggleNewPassword"></i>
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
                                <label style="font-weight:600; font-size:0.85rem; display:block; margin-bottom:6px;">Confirm New Password</label>
                                <div class="password-wrapper">
                                    <input type="password" id="confirmPassword" name="confirmPassword" required style="width: 100%; border-radius: 30px; padding: 12px 18px; padding-right: 40px; border: 1px solid var(--border-color); outline:none;">
                                    <i class="far fa-eye toggle-password-btn" id="toggleConfirmPassword"></i>
                                </div>
                            </div>
                        </div>

                        <button type="submit" class="btn-gold" style="border-radius: 30px; font-size: 0.8rem; padding: 12px 30px; margin:0;">Change Password</button>
                    </form>
                </div>

            </div>

        </div>

    </div>

    <!-- Include Reusable Footer -->
    <%@ include file="footer.jsp" %>

    <script>
        // Toggle password visibility
        document.addEventListener('DOMContentLoaded', () => {
            const toggleOldPassword = document.getElementById('toggleOldPassword');
            const oldPasswordInput = document.getElementById('oldPassword');
            if (toggleOldPassword && oldPasswordInput) {
                toggleOldPassword.addEventListener('click', () => {
                    const type = oldPasswordInput.getAttribute('type') === 'password' ? 'text' : 'password';
                    oldPasswordInput.setAttribute('type', type);
                    toggleOldPassword.classList.toggle('fa-eye');
                    toggleOldPassword.classList.toggle('fa-eye-slash');
                });
            }

            const toggleNewPassword = document.getElementById('toggleNewPassword');
            const newPasswordInput = document.getElementById('newPassword');
            if (toggleNewPassword && newPasswordInput) {
                toggleNewPassword.addEventListener('click', () => {
                    const type = newPasswordInput.getAttribute('type') === 'password' ? 'text' : 'password';
                    newPasswordInput.setAttribute('type', type);
                    toggleNewPassword.classList.toggle('fa-eye');
                    toggleNewPassword.classList.toggle('fa-eye-slash');
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

            if (newPasswordInput) {
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
                    const val = newPasswordInput.value;
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

                newPasswordInput.addEventListener('input', validatePassword);
                
                function isValidEmail(email) {
                    if (!email || email.trim() === '') return false;
                    const emailRegex = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
                    return emailRegex.test(email.trim());
                }

                function isValidPhone(countryCode, phone) {
                    if (!phone || phone.trim() === '') return false;
                    const cleanPhone = phone.trim();
                    
                    if (!/^\d+$/.test(cleanPhone)) return false;
                    
                    let allSame = true;
                    for (let i = 1; i < cleanPhone.length; i++) {
                        if (cleanPhone[i] !== cleanPhone[0]) {
                            allSame = false;
                            break;
                        }
                    }
                    if (allSame) return false;
                    
                    let isAsc = true;
                    let isDesc = true;
                    for (let i = 1; i < cleanPhone.length; i++) {
                        let prev = parseInt(cleanPhone[i - 1]);
                        let curr = parseInt(cleanPhone[i]);
                        if (curr !== (prev + 1) % 10) {
                            isAsc = false;
                        }
                        if (curr !== (prev - 1 + 10) % 10) {
                            isDesc = false;
                        }
                    }
                    if (isAsc || isDesc) return false;
                    
                    const cc = (countryCode || '').trim();
                    const len = cleanPhone.length;
                    
                    if (cc === '+91') {
                        if (len !== 10) return false;
                        const start = cleanPhone[0];
                        if (start !== '6' && start !== '7' && start !== '8' && start !== '9') return false;
                    } else if (cc === '+1') {
                        if (len !== 10) return false;
                        const start = cleanPhone[0];
                        if (start === '0' || start === '1') return false;
                    } else if (cc === '+44') {
                        if (len < 9 || len > 11) return false;
                    } else if (cc === '+61') {
                        if (len < 9 || len > 10) return false;
                    } else if (cc === '+971') {
                        if (len !== 9) return false;
                    } else if (cc === '+81') {
                        if (len < 10 || len > 11) return false;
                    } else if (cc === '+86') {
                        if (len !== 11) return false;
                    } else if (cc === '+49') {
                        if (len < 10 || len > 11) return false;
                    } else if (cc === '+33') {
                        if (len !== 9) return false;
                    } else if (cc === '+65') {
                        if (len !== 8) return false;
                    } else {
                        if (len < 8 || len > 15) return false;
                    }
                    
                    return true;
                }

                const forms = document.querySelectorAll('form');
                forms.forEach(f => {
                    const actionInput = f.querySelector('input[name="action"]');
                    if (actionInput && actionInput.value === 'changePassword') {
                        f.addEventListener('submit', (e) => {
                            if (!validatePassword()) {
                                e.preventDefault();
                                alert("New password does not meet all security requirements.");
                            }
                        });
                    } else if (actionInput && actionInput.value === 'updateProfile') {
                        f.addEventListener('submit', (e) => {
                            const emailInput = f.querySelector('input[name="email"]');
                            const phoneInput = f.querySelector('input[name="phone"]');
                            const countryCodeInput = f.querySelector('input[name="countryCode"]');
                            
                            if (emailInput && !isValidEmail(emailInput.value)) {
                                e.preventDefault();
                                alert("Please enter a valid email address.");
                                emailInput.focus();
                                return;
                            }
                            
                            if (phoneInput && countryCodeInput && !isValidPhone(countryCodeInput.value, phoneInput.value)) {
                                e.preventDefault();
                                alert("Please enter a valid mobile number matching your country format. No letters, special characters, repeating, or sequential digits are allowed.");
                                phoneInput.focus();
                                return;
                            }
                        });
                    }
                });
            }

            // Searchable Country Code Selector logic
            const selectedBox = document.getElementById('selected-country-box');
            const dropdownList = document.getElementById('country-dropdown-list');
            const searchInput = document.getElementById('country-search');
            const options = document.querySelectorAll('.country-opt');
            const countryCodeInput = document.getElementById('countryCode');
            const selectedDisplay = document.getElementById('selected-country-display');

            if (selectedBox && dropdownList) {
                selectedBox.addEventListener('click', (e) => {
                    e.stopPropagation();
                    dropdownList.style.display = dropdownList.style.display === 'none' ? 'block' : 'none';
                    if (dropdownList.style.display === 'block' && searchInput) {
                        searchInput.focus();
                    }
                });

                document.addEventListener('click', () => {
                    dropdownList.style.display = 'none';
                });

                dropdownList.addEventListener('click', (e) => {
                    e.stopPropagation();
                });

                if (searchInput) {
                    searchInput.addEventListener('input', (e) => {
                        const term = e.target.value.toLowerCase();
                        options.forEach(opt => {
                            const txt = opt.getAttribute('data-search').toLowerCase();
                            if (txt.includes(term)) {
                                opt.style.display = 'flex';
                            } else {
                                opt.style.display = 'none';
                            }
                        });
                    });
                }

                options.forEach(opt => {
                    opt.addEventListener('click', () => {
                        const code = opt.getAttribute('data-code');
                        const flagAndCode = opt.querySelector('span').innerText.split(' ')[0] + ' ' + code;
                        
                        countryCodeInput.value = code;
                        selectedDisplay.innerText = flagAndCode;
                        dropdownList.style.display = 'none';
                        if (searchInput) searchInput.value = '';
                        options.forEach(o => o.style.display = 'flex');
                    });
                });
            }
        });
    </script>
</body>
</html>

