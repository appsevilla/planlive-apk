class Validators {
  /// Valida un correo electrónico
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Por favor ingresa un correo electrónico';
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Por favor ingresa un correo válido';
    }
    return null;
  }

  /// Valida una contraseña
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa una contraseña';
    }
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    return null;
  }

  /// Valida que un campo no esté vacío
  static String? validateNotEmpty(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'El campo $fieldName es obligatorio';
    }
    return null;
  }

  /// Valida edad entre 0 y 120
  static String? validateAge(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa tu edad';
    }
    final age = int.tryParse(value);
    if (age == null) {
      return 'La edad debe ser un número';
    }
    if (age < 0 || age > 120) {
      return 'Por favor ingresa una edad válida (0-120)';
    }
    return null;
  }

  /// Valida una ciudad (solo letras y espacios)
  static String? validateCity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Por favor ingresa tu ciudad';
    }
    final regex = RegExp(r'^[a-zA-ZÀ-ÿ\s]+$');
    if (!regex.hasMatch(value)) {
      return 'La ciudad solo puede contener letras';
    }
    return null;
  }
}
