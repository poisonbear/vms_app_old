import 'package:flutter/material.dart';
import '../../model/CmdModel.dart';
import '../../repository/CmdRepository.dart';

// 이용약관 데이터 Load
class CmdLocationViewModel with ChangeNotifier {
  late final CmdRepository _CmdRepository;
  List<CmdModel>? _CmdList;  // nullable 리스트로 변경
  List<CmdModel>? get CmdList => _CmdList;

  CmdLocationViewModel() {
    _CmdRepository = CmdRepository();
    getCmdList();
  }

  Future<void> getCmdList() async {
    List<CmdModel> fetchedList = await _CmdRepository.getCmdList();
    if (fetchedList.length > 2) {
      _CmdList = [fetchedList[2]];
    } else {
      _CmdList = [];
    }
    notifyListeners();
  }
}

