import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:food_pick_app/model/favorite.dart';
import 'package:food_pick_app/model/food_store.dart';
import 'package:food_pick_app/model/user.dart';
import 'package:food_pick_app/widget/appbars.dart';
import 'package:food_pick_app/widget/buttons.dart';
import 'package:food_pick_app/widget/texts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DetailScreen extends StatefulWidget {
  FoodStoreModel foodStoreModel;
  DetailScreen({super.key, required this.foodStoreModel});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  String? _uploaderName; // 맛집 공유자 이름
  bool isFavorite = false; // 현재 로그인한 유저가 해당 게시글에 찜하기를 했는지 여부
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    _getUploaderName(); // 게시글 작성자 정보
    _getFavorite(); // 현재 찜하기 상태 확인
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        // 백버튼 클릭, 안드로이드 지원하는 제스처 백, 가상 백버튼 감지
        Navigator.pop(context, 'back_from_result');
        return Future.value(true);
      },
      child: Scaffold(
        appBar: CommonAppbar(
          title: widget.foodStoreModel.storeName,
          isLeading: true,
          onTapBackButton: () {
            Navigator.pop(context, 'back_from_result');
          },
        ),
        body: Container(
          margin: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 이미지 표시
              _buildStoreImg(),
              const SizedBox(height: 16),

              /// 맛집 위치
              SectionText(text: '맛집 위치 (도로명 주소)', textColor: Colors.black),
              const SizedBox(height: 8),
              ReadOnlyText(title: widget.foodStoreModel.storeAddress),
              const SizedBox(height: 16),

              /// 맛집 공유자
              SectionText(text: '맛집 공유자', textColor: Colors.black),
              const SizedBox(height: 8),
              ReadOnlyText(title: _uploaderName ?? ''),
              const SizedBox(height: 16),

              /// 메모
              SectionText(text: '메모', textColor: Colors.black),
              const SizedBox(height: 8),
              Expanded(
                  child:
                      ReadOnlyText(title: widget.foodStoreModel.storeComment)),
              const SizedBox(height: 16),

              /// 찜하기 / 취소
              isFavorite
                  ? Container(
                      width: double.infinity,
                      height: 69,
                      child: ElevatedButtonCustom(
                          text: '찜하기 취소',
                          backgroundColor: Color(0xff979797),
                          textColor: Colors.white,
                          onPressed: () async {
                            // 찜하기 취소
                            await supabase
                                .from('favorite')
                                .delete()
                                .eq('food_store_id', widget.foodStoreModel.id!)
                                .eq('favorite_uid',
                                    supabase.auth.currentUser!.id);

                            // refresh favorite table
                            _getFavorite();
                          }),
                    )
                  : Container(
                      width: double.infinity,
                      height: 69,
                      child: ElevatedButtonCustom(
                          text: '찜하기 ',
                          backgroundColor: Colors.black,
                          textColor: Colors.white,
                          onPressed: () async {
                            // 찜하기
                            await supabase.from('favorite').upsert(
                                  FavoriteModel(
                                          foodStoreId:
                                              widget.foodStoreModel.id!,
                                          favoriteUid:
                                              supabase.auth.currentUser!.id)
                                      .toMap(),
                                );
                            // refresh favorite table
                            _getFavorite();
                          }),
                    )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoreImg() {
    // 맛집 정보 사진
    if (widget.foodStoreModel.storeImgUrl == null) {
      // default image
      return Container(
        width: double.infinity,
        height: 140,
        decoration: ShapeDecoration(
          color: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        child: const Icon(
          Icons.image_search,
          size: 96,
          color: Colors.white,
        ),
      );
    } else {
      // food store image
      return Container(
        width: double.infinity,
        height: 140,
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            side: BorderSide(width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        child: Image.network(
          widget.foodStoreModel.storeImgUrl!,
          fit: BoxFit.cover,
        ),
      );
    }
  }

  void _getUploaderName() async {
    // 게시글 업로드 한사람 닉네임 가져오기
    final userMap = await supabase
        .from('user')
        .select()
        .eq('uid', widget.foodStoreModel.uid);
    UserModel userModel = userMap.map((e) => UserModel.fromJson(e)).single;
    // 닉네임 전역변수에 할당
    setState(() {
      _uploaderName = userModel.name;
    });
  }

  Future _getFavorite() async {
    // 현재 찜하기 정보 가져오기 (현재 내가 게시글에 찜했는지 체크 )
    final favoriteMap = await supabase
        .from('favorite')
        .select()
        .eq('food_store_id', widget.foodStoreModel.id!)
        .eq('favorite_uid', supabase.auth.currentUser!.id);
// 즐겨찾기 히스토리가 남아있다면
    setState(() {
      favoriteMap.isNotEmpty ? isFavorite = true : isFavorite = false;
    });
  }
}
