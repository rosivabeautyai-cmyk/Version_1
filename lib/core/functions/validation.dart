// ignore_for_file: deprecated_member_use

String? validateEmail(String? value) {
  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  if (value == null || value.isEmpty) {
    return "Email is required";
  } else if (!emailRegex.hasMatch(value)) {
    return "Enter a valid email";
  }

  return null;
}

String? validateEgyptPhone(String? value) {
  final regex = RegExp(r'^01[0125][0-9]{8}$');

  if (value == null || value.isEmpty) {
    return 'Please enter a phone number';
  } else if (!regex.hasMatch(value)) {
    return 'Enter a valid Egyptian mobile number';
  }
  return null;
}

String? validatePassword(String? value) {
  if (value == null || value.isEmpty) {
    return 'Password is required';
  } else if (value.length < 6) {
    return 'Password must be at least 6 characters';
  }
  return null;
}
