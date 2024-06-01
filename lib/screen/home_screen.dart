import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:food_pick_app/model/food_store.dart';
import 'package:food_pick_app/widget/buttons.dart';
import 'package:food_pick_app/widget/text_fields.dart';
import 'package:food_pick_app/widget/texts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 홈 화면
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late NaverMapController _mapController;
  Completer<NaverMapController> mapControllerCompleter = Completer();
  final supabase = Supabase.instance.client;
  Future<List<FoodStoreModel>>? _dataFuture;
  List<FoodStoreModel>? _lstFoodStore;

  final TextEditingController _searchController =
      TextEditingController(); // 검색바 컨트롤러

  @override
  void initState() {
    _dataFuture = fetchStoreInfo();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: FutureBuilder(
            future: _dataFuture,
            builder: (BuildContext context,
                AsyncSnapshot<List<FoodStoreModel>> snapshot) {
              // 데이터가 없을 경우
              if (snapshot.connectionState == ConnectionState.waiting) {
                // 원형 프로그레스 바(로딩 역할)
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
              // 데이터 통신 중 에러가 났을 경우
              else if (snapshot.hasError) {
                return Center(
                    child: Text(
                  'Error: ${snapshot.error}',
                  style: TextStyle(fontSize: 16),
                ));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                // 데이터가 없을 때
                return const Center(
                  child: Text(
                    'No data available',
                    style: TextStyle(fontSize: 16),
                  ),
                );
              } else {
                // 맛집 정보 리스트 데이터를 제공 받은 시점
                _lstFoodStore = snapshot.data;

                return Stack(
                  children: [
                    /// 네이버 지도
                    NaverMap(
                        options: const NaverMapViewOptions(
                          indoorEnable: true, // 실내 맵 사용 가능여부
                          locationButtonEnable: true, // 내 위치로 이동 버튼
                          consumeSymbolTapEvents: false, //심볼 탭 이벤트 소비 여부
                        ),
                        onMapReady: (controller) async {
                          _mapController = controller;
                          // 이동 하고 싶은 카메라 위치 추출 (내 위치)
                          NCameraPosition myPosition = await getMyLocation();

                          // 추출한 위치를 카메라 update
                          _mapController.updateCamera(
                              NCameraUpdate.fromCameraPosition(myPosition));
                          // 서버에 등록된 음식점 리스트 정보들을 위경도를 가지고와서 마커 찍기
                          _buildMarkers();
                          mapControllerCompleter
                              .complete(_mapController); // 지도 컨트롤러 완료 신호 전송
                        }),

                    /// 상단 검색 바
                    Container(
                      margin:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 64),
                      child: TextFormFieldCustom(
                        isPasswordField: false,
                        inReadOnly: false,
                        hintText: '맛집을 검색해주세요',
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.search,
                        validator: (value) => inputSearchValidator(value),
                        controller: _searchController,
                        onFieldSubmitted: (value) async {
                          final foodListMap = await supabase
                              .from('food_store')
                              .select()
                              .like('store_name', '%$value%');

                          List<FoodStoreModel> lstFoodStoreSearch = foodListMap
                              .map((e) => FoodStoreModel.fromJson(e))
                              .toList();
                          if (!mounted) return;
                          Navigator.pushNamed(context, '/search_result',
                              arguments: lstFoodStoreSearch);
                        },
                      ),
                    )
                  ],
                );
              }
            }),
        floatingActionButton: FloatingActionButton(
          shape: const CircleBorder(),
          backgroundColor: Colors.black,
          child: const Icon(
            Icons.add,
            color: Colors.white,
            size: 32,
          ),
          onPressed: () async {
            // 작성 화면으로 이동
            var result = Navigator.pushNamed(context, '/edit');
            if (result != null) {
              if (result == 'completed_edit') {
                // 맛집 등록을 성공적으로 하고 돌아왔을 떄 이 부분이 호출

                // 새롭게 추가된 맛집 정보로 갱신
                _lstFoodStore = await fetchStoreInfo();
                // 마커 UI를 갱신
                _buildMarkers();
                // UI Refresh
                setState(() {});
              }
            }
          },
        ));
  }

  Future<NCameraPosition> getMyLocation() async {
    // 위치 권한을 체크해서 권한 허용이 되어 있다면 내 현위치 정보 가져오기
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled');
    }

    // 위치 권한 현재 상태 체크
    permission = await Geolocator.checkPermission();
    // 만약 위치 권한 허용 팝업을 사용자가 거부했다면
    if (permission == LocationPermission.denied) {
      // 위치 권한 팝업 표시
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location services are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location services are denied forever');
    }
    // 현재 디바이스 기준 GPS 센서 값을 활용해서 현재 위치 추출
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    return NCameraPosition(
        target: NLatLng(position.latitude, position.longitude), zoom: 2);
  }

  Future<List<FoodStoreModel>> fetchStoreInfo() async {
    // 수퍼베이스 db에 접근하여 맛집 정보 리스트 추출
    final foodListMap = await supabase.from('food_store').select();
    List<FoodStoreModel> lstFoodStore = foodListMap
        .map<FoodStoreModel>((e) => FoodStoreModel.fromJson(e))
        .toList();
    return lstFoodStore;
  }

  // Future<List<FoodStoreModel>> fetchStoreInfo() async {
  //   // 수퍼베이스 db에 접근하여 맛집 정보 리스트 추출
  //   final response = await supabase.from('food_store').select('*');
  //   List<dynamic> data = response;
  //   return data.map((e) => FoodStoreModel.fromJson(e)).toList();
  // }

  void _buildMarkers() {
    // 마커들 생성

    // 맵 상의 그려놨던 UI들을 전부 clear
    _mapController.clearOverlays();
    for (FoodStoreModel foodStoreModel in _lstFoodStore!) {
      final marker = NMarker(
        id: foodStoreModel.id.toString(),
        position: NLatLng(foodStoreModel.latitude, foodStoreModel.longitude),
        caption: NOverlayCaption(text: foodStoreModel.storeName),
      );

      // 마커 클릭 기능 부여
      marker.setOnTapListener(
        (overlay) {
          // 맛집 상세 정보 표시
          _showBottomSummaryDialog(foodStoreModel);
        },
      );
      // 네이버 맵에 마커 추가
      _mapController.addOverlay(marker);
    }
  }

  inputSearchValidator(value) {
    // 검색바 필드 검증 함수
    if (value.isEmpty) {
      return '검색어를 입력해주세요';
    }
    return null;
  }

  void _showBottomSummaryDialog(FoodStoreModel foodStoreModel) {
    // 상세보기 화면 다이얼로그(팝업)
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
      ),
      builder: (context) {
        // dialog widget ui
        return Wrap(
          children: [
            Container(
              margin: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// header
                  Row(
                    children: [
                      /// 타이틀
                      SectionText(
                        text: foodStoreModel.storeName,
                        textColor: Colors.black,
                      ),
                      const Spacer(),

                      /// 닫기 버튼
                      GestureDetector(
                        child: Icon(
                          Icons.close,
                          size: 24,
                          color: Colors.black,
                        ),
                        onTap: () {
                          // 팝업 닫기
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  /// body
                  foodStoreModel.storeImgUrl?.isNotEmpty == true
                      ? CircleAvatar(
                          radius: 32,
                          backgroundImage: NetworkImage(
                            foodStoreModel.storeImgUrl!,
                          ),
                        )
                      : const Icon(
                          Icons.image_not_supported,
                          size: 32,
                        ),
                  const SizedBox(height: 8),

                  /// comment
                  Text(
                    foodStoreModel.storeComment,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButtonCustom(
                      text: '상세 보기',
                      backgroundColor: Colors.black,
                      textColor: Colors.white,
                      onPressed: () {
                        // 상세 화면으로 이동
                        Navigator.of(context).pop();
                        Navigator.pushNamed(context, '/detail',
                            arguments: foodStoreModel);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
