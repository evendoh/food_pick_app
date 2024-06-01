import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:food_pick_app/model/food_store.dart';
import 'package:food_pick_app/widget/appbars.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/favorite.dart';

/// 검색 결과 화면
class SearchResultScreen extends StatefulWidget {
  List<FoodStoreModel> lstFoodStore;
  SearchResultScreen({super.key, required this.lstFoodStore});

  @override
  State<SearchResultScreen> createState() => _SearchResultScreenState();
}

class _SearchResultScreenState extends State<SearchResultScreen> {
  List<FavoriteModel> lstMyFavorite = [];
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    _getMyFavorite();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppbar(title: "검색 결과", isLeading: true),
      body: ListView.builder(
        itemCount: widget.lstFoodStore.length,
        itemBuilder: (context, index) {
          FoodStoreModel foodStoreModel = widget.lstFoodStore[index];
          return GestureDetector(
            child: _buildListItemFoodStore(foodStoreModel),
            onTap: () async {
              // 상세 보기 화면으로 이동
              var result = await Navigator.pushNamed(context, '/detail',
                  arguments: foodStoreModel);
              if (result != null) {
                if (result == 'back_from_detail') {
                  _getMyFavorite();
                }
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildListItemFoodStore(FoodStoreModel foodStoreModel) {
    // 맛집 리스트 아이템

    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(8),
      decoration: ShapeDecoration(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
              side: const BorderSide(width: 2, color: Colors.black))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
// 제목과 찜하기 여부
          Row(
            children: [
              Expanded(
                child: Text(
                  foodStoreModel.storeName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                      fontWeight: FontWeight.bold),
                ),
              ),
              _buildFavoriteIcon(foodStoreModel),
            ],
          ),

          /// 메모
          Text(
            foodStoreModel.storeComment,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
            ),
          ),

          /// 주소
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              foodStoreModel.storeAddress,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteIcon(FoodStoreModel foodStoreModel) {
    // 찜하기 UI 아이콘
    bool isFavorite = false;
    for (FavoriteModel favoriteModel in lstMyFavorite) {
      // 찜하기 대상의 맛집 id와 검색 결과의 맛집 id가 서로 일치되는 데이터가 있는지 검사
      if (favoriteModel.foodStoreId == foodStoreModel.id) {
        isFavorite = true;
        break;
      }
    }

    if (!isFavorite) {
      /// 비어 있는 별로  UI 반환
      return const Icon(
        Icons.star_border_outlined,
        size: 32,
      );
    } else {
      return const Icon(
        Icons.star,
        size: 32,
      );
    }
  }

  Future _getMyFavorite() async {
    // 현재 내 찜하기 이력 가져오기
    final myFavoriteMap = await supabase
        .from('favorite')
        .select()
        .eq('favorite_uid', supabase.auth.currentUser!.id);

    setState(() {
      lstMyFavorite =
          myFavoriteMap.map((e) => FavoriteModel.fromJson(e)).toList();
    });
  }
}
