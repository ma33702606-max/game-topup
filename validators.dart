class Validators {
  static String? required(String? value, {String fieldName = 'هذا الحقل'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName مطلوب';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'البريد الإلكتروني مطلوب';
    }
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'البريد الإلكتروني غير صحيح';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'كلمة المرور مطلوبة';
    }
    if (value.length < 6) {
      return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'رقم الهاتف مطلوب';
    }
    final phoneRegex = RegExp(r'^[0-9]{8,15}$');
    final cleaned = value.replaceAll(RegExp(r'[\s\-\+]'), '');
    if (!phoneRegex.hasMatch(cleaned)) {
      return 'رقم الهاتف غير صحيح';
    }
    return null;
  }

  static String? playerId(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'معرّف اللاعب مطلوب';
    }
    if (value.trim().length < 5) {
      return 'معرّف اللاعب قصير جداً';
    }
    return null;
  }

  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'الاسم مطلوب';
    }
    if (value.trim().length < 2) {
      return 'الاسم قصير جداً';
    }
    return null;
  }

  static String? message(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'الرسالة مطلوبة';
    }
    if (value.trim().length < 10) {
      return 'الرسالة قصيرة جداً (10 أحرف على الأقل)';
    }
    return null;
  }
}
