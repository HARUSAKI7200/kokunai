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

enum Yobisun { gobu, hachibu, sho, goju, nisun, sansun }

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
        yobisun: j['yobisun'] != null ? Yobisun.values[(j['yobisun'] as num).toInt()] : null,
      );
}

class DrawingData {
  // drawing_canvas.dart の DrawingElement.toJson() が返すMapのリスト
  final List<Map<String, dynamic>> elements;
  final String imageKey;

  DrawingData(this.elements, {required this.imageKey});

  Map<String, dynamic> toJson() => {
        'elements': elements,
        'imageKey': imageKey,
      };

  factory DrawingData.fromJson(Map<String, dynamic> j) {
    return DrawingData(
      (j['elements'] as List<dynamic>? ?? [])
          .map((e) => e as Map<String, dynamic>)
          .toList(),
      imageKey: j['imageKey'] as String,
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
  PackageStyle packageStyle;
  ProductMaterialType materialType;

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
    this.packageStyle = PackageStyle.yokoshita,
    this.materialType = ProductMaterialType.domestic,
    this.floorPlate = FloorPlateType.none,
    this.getaOrSuri = GetaOrSuriType.geta,
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
        'materialType': materialType.index,
        'floorPlate': floorPlate.index,
        'getaOrSuri': getaOrSuri.index,
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
        packageStyle: PackageStyle.values[(j['packageStyle'] as num).toInt()],
        materialType: ProductMaterialType.values[(j['materialType'] as num).toInt()],
        floorPlate: FloorPlateType.values[(j['floorPlate'] as num).toInt()],
        getaOrSuri: GetaOrSuriType.values[(j['getaOrSuri'] as num).toInt()],
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