package com.mycompany.mavenproject2;

public class ValidationHelper {

    public static boolean isValidEmail(String email) {
        if (email == null || email.trim().isEmpty()) {
            return false;
        }
        // Match user@domain.tld where tld has at least 2 chars
        String emailRegex = "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$";
        return email.trim().matches(emailRegex);
    }

    public static boolean isValidPhone(String countryCode, String phone) {
        if (phone == null || phone.trim().isEmpty()) {
            return false;
        }
        
        String cleanPhone = phone.trim();
        
        // Reject phone numbers containing letters or special characters
        if (!cleanPhone.matches("\\d+")) {
            return false;
        }
        
        // Reject obviously invalid values:
        // 1. Repeating digits (e.g. 0000000000, 1111111111)
        boolean allSame = true;
        char firstChar = cleanPhone.charAt(0);
        for (int i = 1; i < cleanPhone.length(); i++) {
            if (cleanPhone.charAt(i) != firstChar) {
                allSame = false;
                break;
            }
        }
        if (allSame) {
            return false;
        }
        
        // 2. Sequential ascending/descending values (e.g. 1234567890, 0123456789, 9876543210)
        boolean isAsc = true;
        boolean isDesc = true;
        for (int i = 1; i < cleanPhone.length(); i++) {
            int prev = cleanPhone.charAt(i - 1) - '0';
            int curr = cleanPhone.charAt(i) - '0';
            if (curr != (prev + 1) % 10) {
                isAsc = false;
            }
            if (curr != (prev - 1 + 10) % 10) {
                isDesc = false;
            }
        }
        if (isAsc || isDesc) {
            return false;
        }
        
        // Country-specific rules
        if (countryCode == null) {
            countryCode = "";
        }
        countryCode = countryCode.trim();
        
        if (countryCode.equals("+91")) {
            // India: 10 digits, starts with 6, 7, 8, or 9
            if (cleanPhone.length() != 10) {
                return false;
            }
            char start = cleanPhone.charAt(0);
            if (start != '6' && start != '7' && start != '8' && start != '9') {
                return false;
            }
        } else if (countryCode.equals("+1")) {
            // US/Canada: 10 digits, starts with 2-9
            if (cleanPhone.length() != 10) {
                return false;
            }
            char start = cleanPhone.charAt(0);
            if (start == '0' || start == '1') {
                return false;
            }
        } else if (countryCode.equals("+44")) {
            // UK: 9 to 11 digits
            if (cleanPhone.length() < 9 || cleanPhone.length() > 11) {
                return false;
            }
        } else if (countryCode.equals("+61")) {
            // Australia: 9 to 10 digits
            if (cleanPhone.length() < 9 || cleanPhone.length() > 10) {
                return false;
            }
        } else if (countryCode.equals("+971")) {
            // UAE: 9 digits
            if (cleanPhone.length() != 9) {
                return false;
            }
        } else if (countryCode.equals("+81")) {
            // Japan: 10 to 11 digits
            if (cleanPhone.length() < 10 || cleanPhone.length() > 11) {
                return false;
            }
        } else if (countryCode.equals("+86")) {
            // China: 11 digits
            if (cleanPhone.length() != 11) {
                return false;
            }
        } else if (countryCode.equals("+49")) {
            // Germany: 10 to 11 digits
            if (cleanPhone.length() < 10 || cleanPhone.length() > 11) {
                return false;
            }
        } else if (countryCode.equals("+33")) {
            // France: 9 digits
            if (cleanPhone.length() != 9) {
                return false;
            }
        } else if (countryCode.equals("+65")) {
            // Singapore: 8 digits
            if (cleanPhone.length() != 8) {
                return false;
            }
        } else {
            // Fallback for other country formats
            if (cleanPhone.length() < 8 || cleanPhone.length() > 15) {
                return false;
            }
        }
        
        return true;
    }
}
