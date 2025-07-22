enum Format { DATE_TIME, EMAIL, UUID }

final formatValues = EnumValues({
  "date-time": Format.DATE_TIME,
  "email": Format.EMAIL,
  "uuid": Format.UUID,
});

enum Type { STRING }

final typeValues = EnumValues({
  "string": Type.STRING,
});

class CreatedAt {
  final Type type;
  final Format format;

  CreatedAt({
    required this.type,
    required this.format,
  });

  CreatedAt copyWith({
    Type? type,
    Format? format,
  }) =>
      CreatedAt(
        type: type ?? this.type,
        format: format ?? this.format,
      );

  factory CreatedAt.fromJson(Map<String, dynamic> json) => CreatedAt(
        type: typeValues.map[json["type"]]!,
        format: formatValues.map[json["format"]]!,
      );

  Map<String, dynamic> toJson() => {
        "type": typeValues.reverse[type],
        "format": formatValues.reverse[format],
      };
}

class Description {
  final String type;

  Description({
    required this.type,
  });

  Description copyWith({
    String? type,
  }) =>
      Description(
        type: type ?? this.type,
      );

  factory Description.fromJson(Map<String, dynamic> json) => Description(
        type: json["type"],
      );

  Map<String, dynamic> toJson() => {
        "type": type,
      };
}

class EnumValues<T> {
  Map<String, T> map;
  late Map<T, String> reverseMap;

  EnumValues(this.map);

  Map<T, String> get reverse {
    reverseMap = map.map((k, v) => MapEntry(v, k));
    return reverseMap;
  }
}