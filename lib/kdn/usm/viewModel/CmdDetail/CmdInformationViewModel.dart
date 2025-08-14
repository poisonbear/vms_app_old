import 'package:flutter/material.dart';
import '../../model/CmdModel.dart';
import '../../repository/CmdRepository.dart';

// 이용약관 데이터 Load
class CmdInformationViewModel with ChangeNotifier {
  late final CmdRepository _CmdRepository;
  List<CmdModel>? _CmdList;  // nullable 리스트로 변경
  List<CmdModel>? get CmdList => _CmdList;

  CmdInformationViewModel() {
    _CmdRepository = CmdRepository();
    getCmdList();
  }

  Future<void> getCmdList() async {
    List<CmdModel> fetchedList = await _CmdRepository.getCmdList();
    if (fetchedList.length > 1) {
      _CmdList = [fetchedList[1]];
    } else {
      _CmdList = [];
    }
    notifyListeners();
  }


}

