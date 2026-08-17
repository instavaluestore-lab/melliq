String? validateAccountEmail(String? value) {
  final email = value?.trim() ?? '';

  if (email.isEmpty) {
    return 'Enter your email address';
  }

  if (!email.contains('@')) {
    return 'Enter a valid email address';
  }

  return null;
}

String? validateNewPassword(String? value) {
  if ((value ?? '').length < 8) {
    return 'Use at least 8 characters';
  }

  return null;
}

String? validatePasswordConfirmation({
  required String? value,
  required String password,
}) {
  if (value != password) {
    return 'Passwords do not match';
  }

  return null;
}

bool hasAuthCodeCallback(Uri uri) {
  final code = uri.queryParameters['code'];
  return code != null && code.trim().isNotEmpty;
}

String? readAuthCallbackError(Uri uri) {
  final message = uri.queryParameters['error_description']?.trim();

  if (message == null || message.isEmpty) {
    return null;
  }

  return message;
}

bool isPasswordRecoveryRedirectType(String? redirectType) {
  return redirectType == 'passwordRecovery';
}
