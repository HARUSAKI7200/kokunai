import 'dart:convert';

enum PackageStyle { pallet, wooden, bare, other }

String packageStyleLabel(PackageStyle s) {
  switch (s) {
    case PackageStyle.pallet:
      return 'パレ';
    case PackageStyle.wooden:
      return '木箱';
    case PackageStyle.bare:
      return '裸';
    case PackageStyle.other:
      return 'その他';
  }
}

class ComponentSpec {
  /// 有無
  bool enabled;

  /// 幅(mm)
  double? widthMm;

  /// 厚さ(mm)
  double? thicknessMm;

  /// 本数（止は箇所数として使用）
  int? count;

  /// 自由メモ（「他」用）
  String? note;

  ComponentSpec({
    this.enabled = false,
    this.widthMm,
    this.thicknessMm,
    this.count,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'widthMm': widthMm,
        'thicknessMm': thicknessMm,
        'count': count,
        'note': note,
      };

  factory ComponentSpec.fromJson(Map<String, dynamic> j) => ComponentSpec(
        enabled: j['enabled'] == true,
        widthMm: (j['widthMm'] as num?)?.toDouble(),
        thicknessMm: (j['thicknessMm'] as num?)?.toDouble(),
        count: (j['count'] as num?)?.toInt(),
        note: j['note'] as String?,
      );
}

class FormRecord {
  final String id;
  DateTime shipDate;
  String workPlace;
  String instructor; // 指示者
  String slipNo; // 例：#31 など任意

  // 明細・上段表
  String productNo; // 製番
  String productName; // 品名
  double? weightKg; // 重量
  PackageStyle packageStyle; // 荷姿
  String? packageOtherText; // その他の詳細
  int? quantity; // 数量
  int? cases; // C/S
  String? waistNo; // 腰下No

  // 寸法
  double? outerWidthMm; // 外のり幅
  double? innerHeightMm; // 内のり高
  String? contentQuality; // 内容品質量（自由記述）

  // 付属材
  ComponentSpec beam; // 梁
  ComponentSpec geta; // ゲタ
  ComponentSpec oshi; // 押
  ComponentSpec tome; // 止（count=箇所）
  ComponentSpec other; // 他（note活用）

  DateTime createdAt;
  DateTime updatedAt;

  FormRecord({
    required this.id,
    required this.shipDate,
    required this.workPlace,
    required this.instructor,
    required this.slipNo,
    required this.productNo,
    required this.productName,
    this.weightKg,
    this.packageStyle = PackageStyle.pallet,
    this.packageOtherText,
    this.quantity,
    this.cases,
    this.waistNo,
    this.outerWidthMm,
    this.innerHeightMm,
    this.contentQuality,
    ComponentSpec? beam,
    ComponentSpec? geta,
    ComponentSpec? oshi,
    ComponentSpec? tome,
    ComponentSpec? other,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : beam = beam ?? ComponentSpec(),
        geta = geta ?? ComponentSpec(),
        oshi = oshi ?? ComponentSpec(),
        tome = tome ?? ComponentSpec(),
        other = other ?? ComponentSpec(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'shipDate': shipDate.toIso8601String(),
        'workPlace': workPlace,
        'instructor': instructor,
        'slipNo': slipNo,
        'productNo': productNo,
        'productName': productName,
        'weightKg': weightKg,
        'packageStyle': packageStyle.index,
        'packageOtherText': packageOtherText,
        'quantity': quantity,
        'cases': cases,
        'waistNo': waistNo,
        'outerWidthMm': outerWidthMm,
        'innerHeightMm': innerHeightMm,
        'contentQuality': contentQuality,
        'beam': beam.toJson(),
        'geta': geta.toJson(),
        'oshi': oshi.toJson(),
        'tome': tome.toJson(),
        'other': other.toJson(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory FormRecord.fromJson(Map<String, dynamic> j) => FormRecord(
        id: j['id'] as String,
        shipDate: DateTime.parse(j['shipDate'] as String),
        workPlace: j['workPlace'] as String? ?? '',
        instructor: j['instructor'] as String? ?? '',
        slipNo: j['slipNo'] as String? ?? '',
        productNo: j['productNo'] as String? ?? '',
        productName: j['productName'] as String? ?? '',
        weightKg: (j['weightKg'] as num?)?.toDouble(),
        packageStyle:
            PackageStyle.values[(j['packageStyle'] as num? ?? 0).toInt()],
        packageOtherText: j['packageOtherText'] as String?,
        quantity: (j['quantity'] as num?)?.toInt(),
        cases: (j['cases'] as num?)?.toInt(),
        waistNo: j['waistNo'] as String?,
        outerWidthMm: (j['outerWidthMm'] as num?)?.toDouble(),
        innerHeightMm: (j['innerHeightMm'] as num?)?.toDouble(),
        contentQuality: j['contentQuality'] as String?,
        beam: ComponentSpec.fromJson(j['beam'] as Map<String, dynamic>),
        geta: ComponentSpec.fromJson(j['geta'] as Map<String, dynamic>),
        oshi: ComponentSpec.fromJson(j['oshi'] as Map<String, dynamic>),
        tome: ComponentSpec.fromJson(j['tome'] as Map<String, dynamic>),
        other: ComponentSpec.fromJson(j['other'] as Map<String, dynamic>),
        createdAt: DateTime.parse(j['createdAt'] as String),
        updatedAt: DateTime.parse(j['updatedAt'] as String),
      );
}

class RecordList {
  final List<FormRecord> items;
  RecordList(this.items);

  String encode() => jsonEncode(items.map((e) => e.toJson()).toList());

  static RecordList decode(String? src) {
    if (src == null || src.isEmpty) return RecordList([]);
    final list = (jsonDecode(src) as List<dynamic>)
        .map((e) => FormRecord.fromJson(e as Map<String, dynamic>))
        .toList();
    return RecordList(list);
  }
}
