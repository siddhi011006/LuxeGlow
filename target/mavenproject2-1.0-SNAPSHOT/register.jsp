<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%
    // Check for success or error attributes
    String error = (String) request.getAttribute("error");
    String fullnameVal = (String) request.getAttribute("fullname");
    String emailVal = (String) request.getAttribute("email");
    String phoneVal = (String) request.getAttribute("phone");
    String countryCodeVal = (String) request.getAttribute("countryCode");
    String countryVal = (String) request.getAttribute("country");
    
    if (fullnameVal == null) fullnameVal = "";
    if (emailVal == null) emailVal = "";
    if (phoneVal == null) phoneVal = "";
    if (countryCodeVal == null) countryCodeVal = "+91";
    if (countryVal == null) countryVal = "India";
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Create Your Account | LuxeGlow</title>
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
            <p>"Begin your beauty journey with premium skincare, luxury cosmetics, and curated self-care essentials."</p>
            <div style="margin-top: 30px; font-size: 0.8rem; color: var(--gold); border: 1px solid var(--border-color); padding: 15px 25px; border-radius: 12px; background: rgba(0,0,0,0.2);">
                <i class="fas fa-hand-holding-heart" style="margin-right:8px;"></i> Dermatologist-Tested Luxury
            </div>
        </div>

        <!-- Right Side: Forms -->
        <div class="auth-form-box">
            
            <div class="auth-toggle-links">
                <a href="login.jsp">Sign In</a>
                <a href="register.jsp" class="active">Register</a>
            </div>

            <h2>Create Account</h2>
            <p class="subtitle">Join LuxeGlow to manage and track cosmetic orders.</p>

            <!-- Error Alerts -->
            <% if (error != null) { %>
                <div class="alert alert-danger" style="margin-bottom: 25px; padding: 12px 15px; font-size: 0.85rem;">
                    <i class="fas fa-exclamation-circle"></i>
                    <span><%= error %></span>
                </div>
            <% } %>

            <!-- Form submits to Login servlet -->
            <form action="Login" method="POST">
                
                <div class="form-group">
                    <label for="fullname">Full Name</label>
                    <input type="text" id="fullname" name="fullname" placeholder="Enter your full name" value="<%= fullnameVal.replace("\"", "&quot;") %>" required>
                </div>

                <div class="form-group">
                    <label for="email">Email Address</label>
                    <input type="email" id="email" name="email" placeholder="name@example.com" value="<%= emailVal.replace("\"", "&quot;") %>" pattern="^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$" title="Please enter a valid email address." required>
                </div>

                <div class="form-group">
                    <label for="phone">Mobile Number</label>
                    <div class="phone-group-container">
                        <div class="country-select-wrapper" style="position: relative;">
                            <div id="selected-country-box" class="selected-country-box">
                                <span id="selected-country-display">
                                    <%= "+1".equals(countryCodeVal) ? "🇺🇸 +1" :
                                        "+44".equals(countryCodeVal) ? "🇬🇧 +44" :
                                        "+61".equals(countryCodeVal) ? "🇦🇺 +61" :
                                        "+971".equals(countryCodeVal) ? "🇦🇪 +971" :
                                        "+81".equals(countryCodeVal) ? "🇯🇵 +81" :
                                        "+86".equals(countryCodeVal) ? "🇨🇳 +86" :
                                        "+49".equals(countryCodeVal) ? "🇩🇪 +49" :
                                        "+33".equals(countryCodeVal) ? "🇫🇷 +33" :
                                        "+65".equals(countryCodeVal) ? "🇸🇬 +65" : "🇮🇳 +91" %>
                                </span>
                                <i class="fas fa-chevron-down" style="font-size: 0.8rem; color: var(--text-muted);"></i>
                            </div>
                            <input type="hidden" id="countryCode" name="countryCode" value="<%= countryCodeVal.replace("\"", "&quot;") %>">
                            
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
                        <input type="tel" id="phone" name="phone" placeholder="9876543210" pattern="\d{10,15}" title="Please enter a valid mobile number (10 to 15 digits)" required style="flex: 1; border-radius: 30px; padding: 12px 18px; border: 1px solid var(--border-color); outline:none;" value="<%= phoneVal.replace("\"", "&quot;") %>">
                    </div>
                </div>

                <div class="form-group">
                    <label for="country">Country</label>
                    <select id="country" name="country" required style="width: 100%; border-radius: 30px; padding: 12px 18px; border: 1px solid var(--border-color); outline:none; background: var(--bg-card); color: var(--text-primary); font-size: 0.85rem;">
                        <option value="India" <%= "India".equals(countryVal) ? "selected" : "" %>>India</option>
                        <option value="United States" <%= "United States".equals(countryVal) ? "selected" : "" %>>United States</option>
                        <option value="United Kingdom" <%= "United Kingdom".equals(countryVal) ? "selected" : "" %>>United Kingdom</option>
                        <option value="Canada" <%= "Canada".equals(countryVal) ? "selected" : "" %>>Canada</option>
                        <option value="Australia" <%= "Australia".equals(countryVal) ? "selected" : "" %>>Australia</option>
                        <option value="UAE" <%= "UAE".equals(countryVal) ? "selected" : "" %>>UAE</option>
                        <option value="Germany" <%= "Germany".equals(countryVal) ? "selected" : "" %>>Germany</option>
                        <option value="France" <%= "France".equals(countryVal) ? "selected" : "" %>>France</option>
                    </select>
                </div>

                <div class="form-group">
                    <label for="password">Password</label>
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
                    <label for="confirmPassword">Confirm Password</label>
                    <div class="password-wrapper">
                        <input type="password" id="confirmPassword" name="confirmPassword" placeholder="••••••••" required style="padding-right: 40px; width: 100%;">
                        <i class="far fa-eye toggle-password-btn" id="toggleConfirmPassword"></i>
                    </div>
                </div>

                <button type="submit" class="btn-gold" style="width: 100%; border-radius: 12px; margin-top: 15px; padding: 14px;">
                    CREATE ACCOUNT
                </button>
            </form>

            <div style="text-align: center; margin-top: 35px; font-size: 0.85rem; color: var(--text-muted);">
                Already have an account? 
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

                const form = document.querySelector('form');
                if (form) {
                    form.addEventListener('submit', (e) => {
                        if (!validatePassword()) {
                            e.preventDefault();
                            alert("Password does not meet all security requirements.");
                            return;
                        }
                        
                        const emailInput = document.getElementById('email');
                        const phoneInput = document.getElementById('phone');
                        const countryCodeInput = document.getElementById('countryCode');
                        
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
