/// Form validation utilities
class FormValidators {
  FormValidators._();

  /// Validates that a field is not empty
  static String? required(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validates email format
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Let required handle empty
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  /// Validates minimum length
  static String? minLength(
    String? value,
    int minLength, {
    String fieldName = 'This field',
  }) {
    if (value == null || value.isEmpty) {
      return null; // Let required handle empty
    }

    if (value.length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }
    return null;
  }

  /// Validates maximum length
  static String? maxLength(
    String? value,
    int maxLength, {
    String fieldName = 'This field',
  }) {
    if (value == null || value.isEmpty) {
      return null;
    }

    if (value.length > maxLength) {
      return '$fieldName must be at most $maxLength characters';
    }
    return null;
  }

  /// Validates that value is a valid number
  static String? number(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.isEmpty) {
      return null; // Let required handle empty
    }

    if (double.tryParse(value.replaceAll(',', '')) == null) {
      return '$fieldName must be a valid number';
    }
    return null;
  }

  /// Validates that value is a positive number
  static String? positiveNumber(
    String? value, {
    String fieldName = 'This field',
  }) {
    if (value == null || value.isEmpty) {
      return null;
    }

    final number = double.tryParse(value.replaceAll(',', ''));
    if (number == null) {
      return '$fieldName must be a valid number';
    }

    if (number <= 0) {
      return '$fieldName must be greater than 0';
    }
    return null;
  }

  /// Validates that value is within a range
  static String? range(
    String? value,
    double min,
    double max, {
    String fieldName = 'This field',
  }) {
    if (value == null || value.isEmpty) {
      return null;
    }

    final number = double.tryParse(value.replaceAll(',', ''));
    if (number == null) {
      return '$fieldName must be a valid number';
    }

    if (number < min || number > max) {
      return '$fieldName must be between $min and $max';
    }
    return null;
  }

  /// Validates password strength
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }

    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }

    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }

    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }

    return null;
  }

  /// Validates that two fields match
  static String? match(
    String? value,
    String? otherValue, {
    String fieldName = 'This field',
    String otherFieldName = 'the other field',
  }) {
    if (value == null || value.isEmpty) {
      return null;
    }

    if (value != otherValue) {
      return '$fieldName must match $otherFieldName';
    }
    return null;
  }

  /// Validates URL format
  static String? url(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
    );

    if (!urlRegex.hasMatch(value)) {
      return 'Please enter a valid URL';
    }
    return null;
  }

  /// Validates phone number format
  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    // Basic phone validation - allows various formats
    final phoneRegex = RegExp(r'^[\+]?[(]?[0-9]{3}[)]?[-\s\.]?[0-9]{3}[-\s\.]?[0-9]{4,6}$');

    if (!phoneRegex.hasMatch(value.replaceAll(RegExp(r'\s'), ''))) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  /// Combines multiple validators
  static String? compose(
    String? value,
    List<String? Function(String?)> validators,
  ) {
    for (final validator in validators) {
      final result = validator(value);
      if (result != null) {
        return result;
      }
    }
    return null;
  }
}

/// Form field validator class for easy composition
class FieldValidator {
  final List<String? Function(String?)> _validators = [];

  FieldValidator required({String fieldName = 'This field'}) {
    _validators.add((value) => FormValidators.required(value, fieldName: fieldName));
    return this;
  }

  FieldValidator email() {
    _validators.add(FormValidators.email);
    return this;
  }

  FieldValidator minLength(int length, {String fieldName = 'This field'}) {
    _validators.add((value) => FormValidators.minLength(value, length, fieldName: fieldName));
    return this;
  }

  FieldValidator maxLength(int length, {String fieldName = 'This field'}) {
    _validators.add((value) => FormValidators.maxLength(value, length, fieldName: fieldName));
    return this;
  }

  FieldValidator number({String fieldName = 'This field'}) {
    _validators.add((value) => FormValidators.number(value, fieldName: fieldName));
    return this;
  }

  FieldValidator positiveNumber({String fieldName = 'This field'}) {
    _validators.add((value) => FormValidators.positiveNumber(value, fieldName: fieldName));
    return this;
  }

  FieldValidator range(double min, double max, {String fieldName = 'This field'}) {
    _validators.add((value) => FormValidators.range(value, min, max, fieldName: fieldName));
    return this;
  }

  FieldValidator password() {
    _validators.add(FormValidators.password);
    return this;
  }

  FieldValidator match(String otherValue, {String fieldName = 'This field', String otherFieldName = 'the other field'}) {
    _validators.add((value) => FormValidators.match(value, otherValue, fieldName: fieldName, otherFieldName: otherFieldName));
    return this;
  }

  FieldValidator url() {
    _validators.add(FormValidators.url);
    return this;
  }

  FieldValidator phone() {
    _validators.add(FormValidators.phone);
    return this;
  }

  FieldValidator custom(String? Function(String?) validator) {
    _validators.add(validator);
    return this;
  }

  String? validate(String? value) {
    return FormValidators.compose(value, _validators);
  }
}

/// Extension for easy validator access
extension ValidatorExtension on String? {
  String? get required => FormValidators.required(this);
  String? get email => FormValidators.email(this);
  String? get number => FormValidators.number(this);
  String? get positiveNumber => FormValidators.positiveNumber(this);
  String? get url => FormValidators.url(this);
  String? get phone => FormValidators.phone(this);

  String? minLength(int min) => FormValidators.minLength(this, min);
  String? maxLength(int max) => FormValidators.maxLength(this, max);
  String? range(double min, double max) => FormValidators.range(this, min, max);
}
