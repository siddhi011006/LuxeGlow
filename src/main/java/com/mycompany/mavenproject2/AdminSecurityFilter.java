package com.mycompany.mavenproject2;

import java.io.IOException;
import jakarta.servlet.Filter;
import jakarta.servlet.FilterChain;
import jakarta.servlet.FilterConfig;
import jakarta.servlet.ServletException;
import jakarta.servlet.ServletRequest;
import jakarta.servlet.ServletResponse;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

/**
 * Centralized security filter for admin console and operations routes.
 * Redirects unauthorized users and unauthenticated sessions to the main website homepage.
 * Makes the admin endpoints completely invisible/inaccessible to non-administrators.
 * 
 * @author Antigravity
 */
public class AdminSecurityFilter implements Filter {

    @Override
    public void init(FilterConfig filterConfig) throws ServletException {
        // No-op
    }

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {
        
        HttpServletRequest httpRequest = (HttpServletRequest) request;
        HttpServletResponse httpResponse = (HttpServletResponse) response;
        
        HttpSession session = httpRequest.getSession(false);
        boolean isAdmin = false;
        
        if (session != null) {
            String role = (String) session.getAttribute("role");
            if ("ADMIN".equalsIgnoreCase(role)) {
                isAdmin = true;
            }
        }
        
        if (isAdmin) {
            chain.doFilter(request, response);
        } else {
            // Redirect to home page
            httpResponse.sendRedirect(httpRequest.getContextPath() + "/");
            return;
        }
    }

    @Override
    public void destroy() {
        // No-op
    }
}
