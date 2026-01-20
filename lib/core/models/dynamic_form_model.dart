import 'package:freezed_annotation/freezed_annotation.dart';
import '../utils/timestamp_converter.dart';

part 'dynamic_form_model.freezed.dart';
part 'dynamic_form_model.g.dart';

@freezed
class DynamicForm with _$DynamicForm {
  const factory DynamicForm({
    required String id,
    required String companyId,
    String? departmentId, // null = company-wide
    required String name,
    String? description,
    required List<FormField> fields,
    @Default(true) bool isActive,
    @TimestampConverter() required DateTime createdAt,
    @TimestampConverter() required DateTime updatedAt,
    String? createdBy,
  }) = _DynamicForm;

  factory DynamicForm.fromJson(Map<String, dynamic> json) =>
      _$DynamicFormFromJson(json);
}

@freezed
class FormField with _$FormField {
  const factory FormField({
    required String id,
    required String fieldName,
    required String label,
    required String fieldType, // text, number, dropdown, etc.
    @Default(false) bool isRequired,
    @Default(true) bool isVisible,
    int? order,
    String? placeholder,
    String? defaultValue,

    // Validation
    String? validationRegex,
    String? validationMessage,
    int? minLength,
    int? maxLength,
    double? minValue,
    double? maxValue,

    // For dropdown/multi-select
    List<String>? options,

    // Conditional visibility
    String? dependsOnField,
    dynamic dependsOnValue,
  }) = _FormField;

  factory FormField.fromJson(Map<String, dynamic> json) =>
      _$FormFieldFromJson(json);
}
