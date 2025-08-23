import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';

enum PackageStyle { yokoshita, sukashi, mekura, tatebako }

String packageStyleLabel(PackageStyle s) {
  switch (s) {
    case PackageStyle.yokoshita:
      return '腰下';
    case PackageStyle.sukashi:
      return 'スカシ';
    case PackageStyle.mekura:
      return 'メクラ';
    case PackageStyle.tatebako:
      return '立箱';
  }
}

enum ProductMaterialType { domestic, heatTreatment, lvl }

String productMaterialTypeLabel(ProductMaterialType s) {
  switch (s) {
    case ProductMaterialType.domestic:
      return '国内材';
    case ProductMaterialType.heatTreatment:
      return '熱処理材';
    case ProductMaterialType.lvl:
      return 'LVL材';
  }
}

enum FloorPlateType { none, mekura, nineMmVeneer, fifteenMmVeneer }

String floorPlateTypeLabel(FloorPlateType s) {
  switch (s) {
    case FloorPlateType.none:
      return 'なし';
    case FloorPlateType.mekura:
      return '地メクラ';
    case FloorPlateType.nineMmVeneer:
      return '9mmべニア';
    case FloorPlateType.fifteenMmVeneer:
      return '15mmべニア';
  }
}

enum GetaOrSuriType { geta, suri }

String getaOrSuriTypeLabel(GetaOrSuriType s) {
  switch (s) {
    case GetaOrSuriType.geta:
      return 'ゲタ';
    case GetaOrSuriType.suri:
      return 'すり材';
  }
}

enum Yobisun { gobu, hachibu, sho, goju, nisun, sansun, issun }

String yobisunLabel(Yobisun s) {
  switch (s) {
    case Yobisun.gobu:
      return '5分';
    case Yobisun.hachibu:
      return '8分';
    case Yobisun.sho:
      return '小';
    case Yobisun.goju:
      return '50';
    case Yobisun.nisun:
      return '二寸';
    case Yobisun.sansun:
      return '三寸';
    case Yobisun.issun:
      return '一寸';
  }
}

class ComponentSpec {
  double? widthMm;
  double? thicknessMm;
  int? count;
  String? partName;
  double? lengthMm;
  Yobisun? yobisun;

  ComponentSpec({
    this.widthMm,
    this.thicknessMm,
    this.count,
    this.partName,
    this.lengthMm,
    this.yobisun,
  });

  Map<String, dynamic> toJson() => {
        'widthMm': widthMm,
        'thicknessMm': thicknessMm,
        'count': count,
        'partName': partName,
        'lengthMm': lengthMm,
        'yobisun': yobisun?.index,
      };

  factory ComponentSpec.fromJson(Map<String, dynamic> j) => ComponentSpec(
        widthMm: (j['widthMm'] as num?)?.toDouble(),
        thicknessMm: (j['thicknessMm'] as num?)?.toDouble(),
        count: (j['count'] as num?)?.toInt(),
        partName: j['partName'] as String?,
        lengthMm: (j['lengthMm'] as num?)?.toDouble(),
        yobisun: j['yobisun'] != null && j['yobisun'] < Yobisun.values.length ? Yobisun.values[(j['yobisun'] as num).toInt()] : null,
      );
}

class DrawingData {
  final List<Map<String, dynamic>> elements;
  final String imageKey;
  final double? sourceWidth;
  final double? sourceHeight;
  dynamic? previewBytes;


  DrawingData(this.elements, {
    required this.imageKey,
    this.previewBytes,
    this.sourceWidth,
    this.sourceHeight,
  });

  Map<String, dynamic> toJson() => {
        'elements': elements,
        'imageKey': imageKey,
        'sourceWidth': sourceWidth,
        'sourceHeight': sourceHeight,
      };

  factory DrawingData.fromJson(Map<String, dynamic> j) {
    return DrawingData(
      (j['elements'] as List<dynamic>? ?? [])
          .map((e) => e as Map<String, dynamic>)
          .toList(),
      imageKey: j['imageKey'] as String,
      sourceWidth: (j['sourceWidth'] as num?)?.toDouble(),
      sourceHeight: (j['sourceHeight'] as num?)?.toDouble(),
    );
  }
}


class FormRecord {
  final String id;
  DateTime shipDate;
  String workPlace;
  String instructor;
  String slipNo;

  String productNo;
  String productName;
  double? weightKg;
  double? weightGrossKg; // 👈 【追加】Gross重量
  PackageStyle packageStyle;
  ProductMaterialType materialType;
  int? quantity;

  String? insideLength;
  String? insideWidth;
  String? insideHeight;
  String? outsideLength;
  String? outsideWidth;
  String? outsideHeight;

  ComponentSpec subzai;
  FloorPlateType floorPlate;
  ComponentSpec h;
  ComponentSpec fukazai1;
  ComponentSpec fukazai2;
  GetaOrSuriType getaOrSuri;
  ComponentSpec getaOrSuriSpec;
  ComponentSpec nedome1;
  ComponentSpec nedome2;
  ComponentSpec nedome3;
  ComponentSpec nedome4;
  ComponentSpec osae;
  ComponentSpec ryo;
  ComponentSpec other1;
  ComponentSpec other2;

  DrawingData? subzaiDrawing;
  DrawingData? yokoshitaDrawing;
  DrawingData? hiraichiDrawing;

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
    this.weightGrossKg, // 👈 【追加】
    this.packageStyle = PackageStyle.yokoshita,
    this.materialType = ProductMaterialType.domestic,
    this.floorPlate = FloorPlateType.none,
    this.getaOrSuri = GetaOrSuriType.geta,
    this.quantity,
    this.insideLength,
    this.insideWidth,
    this.insideHeight,
    this.outsideLength,
    this.outsideWidth,
    this.outsideHeight,
    ComponentSpec? subzai,
    ComponentSpec? h,
    ComponentSpec? fukazai1,
    ComponentSpec? fukazai2,
    ComponentSpec? getaOrSuriSpec,
    ComponentSpec? nedome1,
    ComponentSpec? nedome2,
    ComponentSpec? nedome3,
    ComponentSpec? nedome4,
    ComponentSpec? osae,
    ComponentSpec? ryo,
    ComponentSpec? other1,
    ComponentSpec? other2,
    this.subzaiDrawing,
    this.yokoshitaDrawing,
    this.hiraichiDrawing,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : subzai = subzai ?? ComponentSpec(),
        h = h ?? ComponentSpec(),
        fukazai1 = fukazai1 ?? ComponentSpec(),
        fukazai2 = fukazai2 ?? ComponentSpec(),
        getaOrSuriSpec = getaOrSuriSpec ?? ComponentSpec(),
        nedome1 = nedome1 ?? ComponentSpec(),
        nedome2 = nedome2 ?? ComponentSpec(),
        nedome3 = nedome3 ?? ComponentSpec(),
        nedome4 = nedome4 ?? ComponentSpec(),
        osae = osae ?? ComponentSpec(),
        ryo = ryo ?? ComponentSpec(),
        other1 = other1 ?? ComponentSpec(),
        other2 = other2 ?? ComponentSpec(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  FormRecord copyWith({
    String? id,
    DateTime? shipDate,
    String? workPlace,
    String? instructor,
    String? slipNo,
    String? productNo,
    String? productName,
    double? weightKg,
    double? weightGrossKg, // 👈 【追加】
    PackageStyle? packageStyle,
    ProductMaterialType? materialType,
    int? quantity,
    String? insideLength,
    String? insideWidth,
    String? insideHeight,
    String? outsideLength,
    String? outsideWidth,
    String? outsideHeight,
    FloorPlateType? floorPlate,
    GetaOrSuriType? getaOrSuri,
    ComponentSpec? subzai,
    ComponentSpec? h,
    ComponentSpec? fukazai1,
    ComponentSpec? fukazai2,
    ComponentSpec? getaOrSuriSpec,
    ComponentSpec? nedome1,
    ComponentSpec? nedome2,
    ComponentSpec? nedome3,
    ComponentSpec? nedome4,
    ComponentSpec? osae,
    ComponentSpec? ryo,
    ComponentSpec? other1,
    ComponentSpec? other2,
    DrawingData? subzaiDrawing,
    DrawingData? yokoshitaDrawing,
    DrawingData? hiraichiDrawing,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FormRecord(
      id: id ?? this.id,
      shipDate: shipDate ?? this.shipDate,
      workPlace: workPlace ?? this.workPlace,
      instructor: instructor ?? this.instructor,
      slipNo: slipNo ?? this.slipNo,
      productNo: productNo ?? this.productNo,
      productName: productName ?? this.productName,
      weightKg: weightKg ?? this.weightKg,
      weightGrossKg: weightGrossKg ?? this.weightGrossKg, // 👈 【追加】
      packageStyle: packageStyle ?? this.packageStyle,
      materialType: materialType ?? this.materialType,
      quantity: quantity ?? this.quantity,
      insideLength: insideLength ?? this.insideLength,
      insideWidth: insideWidth ?? this.insideWidth,
      insideHeight: insideHeight ?? this.insideHeight,
      outsideLength: outsideLength ?? this.outsideLength,
      outsideWidth: outsideWidth ?? this.outsideWidth,
      outsideHeight: outsideHeight ?? this.outsideHeight,
      floorPlate: floorPlate ?? this.floorPlate,
      getaOrSuri: getaOrSuri ?? this.getaOrSuri,
      subzai: subzai ?? this.subzai,
      h: h ?? this.h,
      fukazai1: fukazai1 ?? this.fukazai1,
      fukazai2: fukazai2 ?? this.fukazai2,
      getaOrSuriSpec: getaOrSuriSpec ?? this.getaOrSuriSpec,
      nedome1: nedome1 ?? this.nedome1,
      nedome2: nedome2 ?? this.nedome2,
      nedome3: nedome3 ?? this.nedome3,
      nedome4: nedome4 ?? this.nedome4,
      osae: osae ?? this.osae,
      ryo: ryo ?? this.ryo,
      other1: other1 ?? this.other1,
      other2: other2 ?? this.other2,
      subzaiDrawing: subzaiDrawing ?? this.subzaiDrawing,
      yokoshitaDrawing: yokoshitaDrawing ?? this.yokoshitaDrawing,
      hiraichiDrawing: hiraichiDrawing ?? this.hiraichiDrawing,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'shipDate': shipDate.toIso8601String(),
        'workPlace': workPlace,
        'instructor': instructor,
        'slipNo': slipNo,
        'productNo': productNo,
        'productName': productName,
        'weightKg': weightKg,
        'weightGrossKg': weightGrossKg, // 👈 【追加】
        'packageStyle': packageStyle.index,
        'materialType': materialType.index,
        'floorPlate': floorPlate.index,
        'getaOrSuri': getaOrSuri.index,
        'quantity': quantity,
        'insideLength': insideLength,
        'insideWidth': insideWidth,
        'insideHeight': insideHeight,
        'outsideLength': outsideLength,
        'outsideWidth': outsideWidth,
        'outsideHeight': outsideHeight,
        'subzai': subzai.toJson(),
        'h': h.toJson(),
        'fukazai1': fukazai1.toJson(),
        'fukazai2': fukazai2.toJson(),
        'getaOrSuriSpec': getaOrSuriSpec.toJson(),
        'nedome1': nedome1.toJson(),
        'nedome2': nedome2.toJson(),
        'nedome3': nedome3.toJson(),
        'nedome4': nedome4.toJson(),
        'osae': osae.toJson(),
        'ryo': ryo.toJson(),
        'other1': other1.toJson(),
        'other2': other2.toJson(),
        'subzaiDrawing': subzaiDrawing?.toJson(),
        'yokoshitaDrawing': yokoshitaDrawing?.toJson(),
        'hiraichiDrawing': hiraichiDrawing?.toJson(),
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
        weightGrossKg: (j['weightGrossKg'] as num?)?.toDouble(), // 👈 【追加】
        packageStyle: PackageStyle.values[(j['packageStyle'] as num).toInt()],
        materialType: ProductMaterialType.values[(j['materialType'] as num).toInt()],
        floorPlate: FloorPlateType.values[(j['floorPlate'] as num).toInt()],
        getaOrSuri: GetaOrSuriType.values[(j['getaOrSuri'] as num).toInt()],
        quantity: (j['quantity'] as num?)?.toInt(),
        insideLength: j['insideLength'] as String?,
        insideWidth: j['insideWidth'] as String?,
        insideHeight: j['insideHeight'] as String?,
        outsideLength: j['outsideLength'] as String?,
        outsideWidth: j['outsideWidth'] as String?,
        outsideHeight: j['outsideHeight'] as String?,
        subzai: ComponentSpec.fromJson(j['subzai'] as Map<String, dynamic>),
        h: ComponentSpec.fromJson(j['h'] as Map<String, dynamic>),
        fukazai1: ComponentSpec.fromJson(j['fukazai1'] as Map<String, dynamic>),
        fukazai2: ComponentSpec.fromJson(j['fukazai2'] as Map<String, dynamic>),
        getaOrSuriSpec: ComponentSpec.fromJson(j['getaOrSuriSpec'] as Map<String, dynamic>),
        nedome1: ComponentSpec.fromJson(j['nedome1'] as Map<String, dynamic>),
        nedome2: ComponentSpec.fromJson(j['nedome2'] as Map<String, dynamic>),
        nedome3: ComponentSpec.fromJson(j['nedome3'] as Map<String, dynamic>),
        nedome4: ComponentSpec.fromJson(j['nedome4'] as Map<String, dynamic>),
        osae: ComponentSpec.fromJson(j['osae'] as Map<String, dynamic>),
        ryo: ComponentSpec.fromJson(j['ryo'] as Map<String, dynamic>),
        other1: ComponentSpec.fromJson(j['other1'] as Map<String, dynamic>),
        other2: ComponentSpec.fromJson(j['other2'] as Map<String, dynamic>),
        subzaiDrawing: j['subzaiDrawing'] != null
            ? DrawingData.fromJson(j['subzaiDrawing'] as Map<String, dynamic>)
            : null,
        yokoshitaDrawing: j['yokoshitaDrawing'] != null
            ? DrawingData.fromJson(j['yokoshitaDrawing'] as Map<String, dynamic>)
            : null,
        hiraichiDrawing: j['hiraichiDrawing'] != null
            ? DrawingData.fromJson(j['hiraichiDrawing'] as Map<String, dynamic>)
            : null,
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