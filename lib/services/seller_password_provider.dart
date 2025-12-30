// lib/providers/seller_password_provider.dart

import 'package:flutter/material.dart';
import '../services/graphql_client.dart';

class SellerPasswordProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  bool _isSuccess = false;
  String? _successMessage;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isSuccess => _isSuccess;
  String? get successMessage => _successMessage;

  /// Change seller password
  /// Returns true if successful, false otherwise
  Future<bool> changePassword({
    required String customId,
    required String newPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _isSuccess = false;
    _successMessage = null;
    notifyListeners();

    try {
      // Validate customId
      if (customId.isEmpty) {
        _errorMessage = "Seller ID is missing. Please try again.";
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Validate password
      if (newPassword.isEmpty) {
        _errorMessage = "Password cannot be empty";
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (newPassword.length < 8) {
        _errorMessage = "Password must be at least 8 characters long";
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Call GraphQL mutation
      final response = await GraphQLService.changeSellerPassword(
        customId: customId,
        newPassword: newPassword,
      );

      if (response.isNotEmpty && response.containsKey('customId')) {
        _isSuccess = true;
        _successMessage =
        "Password changed successfully!";
        _errorMessage = null;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = "No response from server. Please try again.";
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = _parseError(e.toString());
      _isLoading = false;
      _isSuccess = false;
      _successMessage = null;
      notifyListeners();
      return false;
    }
  }

  /// Parse error messages to user-friendly format
  String _parseError(String error) {
    final errorStr = error.replaceAll('Exception: ', '').trim();

    debugPrint('❌ Password change error: $errorStr');

    // Common error patterns
    if (errorStr.contains("Seller not found")) {
      return "Seller account not found. Please contact support.";
    }
    if (errorStr.contains("Firebase UID not found")) {
      return "Authentication error. Please log out and try again.";
    }
    if (errorStr.contains("Deactivated")) {
      return "Your account has been deactivated. You cannot change the password.";
    }
    if (errorStr.contains("password must be")) {
      return errorStr;
    }
    if (errorStr.contains("Network error") ||
        errorStr.contains("connection") ||
        errorStr.contains("Failed to") ||
        errorStr.contains("timeout")) {
      return "Network error. Please check your internet connection and try again.";
    }
    if (errorStr.contains("customId and newPassword are required")) {
      return "Invalid request. Please provide seller ID and password.";
    }
    if (errorStr.contains("Invalid")) {
      return errorStr;
    }

    // Default error message
    return errorStr.isNotEmpty
        ? errorStr
        : "An unexpected error occurred. Please try again.";
  }

  /// Reset provider state
  void reset() {
    _isLoading = false;
    _errorMessage = null;
    _isSuccess = false;
    _successMessage = null;
    notifyListeners();
  }

  /// Clear success state
  void clearSuccess() {
    _isSuccess = false;
    _successMessage = null;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}