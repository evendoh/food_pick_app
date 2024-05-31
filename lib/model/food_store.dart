/// 맛집 정보 모델 클래스
class FoodStoreModel {
  int? id;
  String storeName; // 맛집명
  String storeAddress; // 맛집 주소
  String storeComment; // 맛집 상세내용
  String? storeImgUrl; // 맛집 이미지 url
  String uid; // 수퍼베이스 회원 고유 값
  double latitude; // 위도
  double longitude; // 경도
  DateTime? createdAt;

  FoodStoreModel({
    this.id,
    required this.storeName,
    required this.storeAddress,
    required this.storeComment,
    this.storeImgUrl,
    required this.uid,
    required this.latitude,
    required this.longitude,
    this.createdAt,
  });
  Map<String, dynamic> toMap() {
    return {
      'store_name': storeName,
      'store_address': storeAddress,
      'store_comment': storeComment,
      'store_img_url': storeImgUrl,
      'uid': uid,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory FoodStoreModel.fromJson(Map<dynamic, dynamic> json) {
    // null 값 체크 및 로그 출력
    if (json['id'] == null) print('id is null');
    if (json['store_name'] == null) print('store_name is null');
    if (json['store_address'] == null) print('store_address is null');
    if (json['store_comment'] == null) print('store_comment is null');
    if (json['store_img_url'] == null) print('store_img_url is null');
    if (json['uid'] == null) print('uid is null');
    if (json['latitude'] == null) print('latitude is null');
    if (json['longitude'] == null) print('longitude is null');
    if (json['created_at'] == null)
      print('createdAt is null. ${json['created_at']}');

    return FoodStoreModel(
        id: json['id'],
        storeName: json['store_name'],
        storeAddress: json['store_address'],
        storeComment: json['store_comment'],
        storeImgUrl: json['store_img_url'],
        uid: json['uid'],
        latitude: json['latitude'],
        longitude: json['longitude'],
        createdAt: DateTime.parse(json['created_at']));
  }
}
