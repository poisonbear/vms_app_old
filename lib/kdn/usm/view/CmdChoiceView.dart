
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:vms_app/kdn/usm/view/MembershipView.dart';
import 'package:vms_app/kdn/usm/viewModel/CmdDetail/CmdInformationViewModel.dart';
import 'package:vms_app/kdn/usm/viewModel/CmdDetail/CmdLocationViewModel.dart';
import 'package:vms_app/kdn/usm/viewModel/CmdDetail/CmdMarkettingViewModel.dart';
import 'package:vms_app/kdn/usm/viewModel/CmdDetail/CmdServiceViewModel.dart';
import 'package:vms_app/kdn/usm/view/CmdDetail/CmdServiceView.dart';
import 'package:vms_app/kdn/usm/view/CmdDetail/CmdInformationView.dart';
import 'package:vms_app/kdn/usm/view/CmdDetail/CmdLocationView.dart';
import 'package:vms_app/kdn/usm/view/CmdDetail/CmdMarkettingView.dart';
import 'package:vms_app/kdn/cmm/common_action.dart';
import 'package:vms_app/kdn/cmm_widget/common_widget.dart';
import 'package:vms_app/kdn/cmm_widget/common_style_widget.dart';
import 'package:vms_app/kdn/cmm_widget/common_size_widget.dart';
import 'package:vms_app/kdn/usm/view/layer/AppBarLayerView.dart';


class CmdChoiceView extends StatefulWidget { // 상태관리를 위해 선언
  const CmdChoiceView({super.key});
  @override
  _CmdChoiceViewState createState() => _CmdChoiceViewState();
}

class _CmdChoiceViewState extends State<CmdChoiceView> {

  // 기본값 선택 누르기 전
  bool _serviceAgreement = false;  // 서비스 이용약관 선택 유무 상태
  bool _privacyAgreement = false;  // 위치기반 서비스 이용약관 섭택 유무 상태
  bool _locationAgreement = false; // 개인정보 수집 이용약관 선택 유무 상태
  bool _marketAgreement = false;   // 마케팅 활용 동의 이용약관 선택 유무 상태
  bool _allAgreement = false;      // 약관 전체 동의 선택 유무 상태

  // 서비스, 위치기반, 개인정보, 마케팅 이용약관이 선택이 되었는지 찾기
  bool get _isAllChecked => _serviceAgreement && _privacyAgreement && _locationAgreement;


  // 이벤트 발생
  // 약관 전체 동의하기 버튼를 눌렀다면 전체 적용
  // 예를 들어 버튼 한번 누르면 전체 선택 , 두번 누르면 전체 취소
  void _toggleAllAgreements(bool? value) {
    setState(() {
      _allAgreement = value ?? false;
      _serviceAgreement = _allAgreement;
      _privacyAgreement = _allAgreement;
      _locationAgreement = _allAgreement;
      _marketAgreement = _allAgreement;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        FutureProvider(
          create: (_) async {
            final viewModel = CmdServiceViewModel();
            await viewModel.getCmdList();
            return viewModel;
          },
          initialData: CmdServiceViewModel(),
        ),
        FutureProvider(
          create: (_) async {
            final viewModel = CmdInformationViewModel();
            await viewModel.getCmdList();
            return viewModel;
          },
          initialData: CmdInformationViewModel(),
        ),
        FutureProvider(
          create: (_) async {
            final viewModel = CmdLocationViewModel();
            await viewModel.getCmdList();
            return viewModel;
          },
          initialData: CmdLocationViewModel(),
        ),
        FutureProvider(
          create: (_) async {
            final viewModel = CmdMarkettingViewModel();
            await viewModel.getCmdList();
            return viewModel;
          },
          initialData: CmdMarkettingViewModel(),
        ),
      ],
      builder: (context, child) {
        final serviceVM = Provider.of<CmdServiceViewModel>(context);
        final infoVM = Provider.of<CmdInformationViewModel>(context);
        final locationVM = Provider.of<CmdLocationViewModel>(context);
        final marketVM = Provider.of<CmdMarkettingViewModel>(context);

        final allDataLoaded = serviceVM.CmdList != null &&
            infoVM.CmdList != null &&
            locationVM.CmdList != null &&
            marketVM.CmdList != null;

        return Scaffold(
          appBar: AppBar(
            title: const AppBarLayerView('회원가입'),
            centerTitle: true,
          ),
          body: Padding(
            padding: EdgeInsets.all(getSize20().toDouble()),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(bottom: getSize20().toDouble()),
                  child: Row(
                    children: [
                      const Spacer(),
                      svgload('assets/kdn/usm/img/Frame_one_on.svg', getSize32().toDouble(), getSize32().toDouble()),
                      svgload('assets/kdn/usm/img/Frame_two_off.svg', getSize32().toDouble(), getSize32().toDouble()),
                      svgload('assets/kdn/usm/img/Frame_three_off.svg', getSize32().toDouble(), getSize32().toDouble()),
                    ],
                  ),
                ),
                TextWidgetString('K-VMS', getTextcenter(), getSize32(), getText700(), getColorblack_type2()),
                TextWidgetString('약관동의', getTextcenter(), getSize32(), getText700(), getColorblack_type2()),
                Padding(
                  padding: EdgeInsets.only(top: getSize12().toDouble(), bottom: getSize60().toDouble()),
                  child: TextWidgetString(
                    '회원가입을 위해 필수항목 및 선택항목 약관에 동의 해주시기 바랍니다.',
                    getTextcenter(),
                    getSize12(),
                    getText700(),
                    getColorgray_Type2(),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: getSize12().toDouble()),
                  child: TextWidgetString(
                    '약관 거부 시 회원가입에 제한이 있을 수 있습니다.',
                    getTextcenter(),
                    getSize12(),
                    getText700(),
                    getColorred_type1(),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: getSize20().toDouble()),
                  child: Container(
                    padding: EdgeInsets.only(top: getSize14().toDouble(), bottom: getSize14().toDouble(), left: getSize20().toDouble()),
                    decoration: BoxDecoration(
                      border: Border.all(color: getColorgray_Type4(), width: getSize1().toDouble()),
                      borderRadius: BorderRadius.circular(getSize4().toDouble()),
                    ),
                    child: Row(
                      children: [
                        Transform.scale(
                          scale: getSize1_333(),
                          child: Checkbox(
                            value: _allAgreement,
                            onChanged: _toggleAllAgreements,
                            activeColor: getColorsky_Type2(),
                            checkColor: getColorwhite_type1(),
                            shape: CircleBorder(),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: const VisualDensity(horizontal: VisualDensity.minimumDensity, vertical: VisualDensity.minimumDensity),
                            side: BorderSide(color: getColorgray_Type7(), width: getSize1().toDouble()),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(left: getSize12().toDouble()),
                          child: RichText(
                            text: TextSpan(
                              text: "약관 전체 동의하기",
                              style: TextStyle(fontSize: getSize16().toDouble(), fontWeight: getTextbold(), color: getColorblack_type1()),
                              children: [
                                TextSpan(
                                  text: " (선택사항 포함)",
                                  style: TextStyle(fontSize: getSize16().toDouble(), fontWeight: getTextbold(), color: getColorgray_Type13()),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ✅ 이 부분만 수정
                if (!allDataLoaded)
                  Expanded(
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                else ...[
                  Padding(
                    padding: EdgeInsets.only(left: getSize20().toDouble()),
                    child: _buildAgreementRow_Service(
                      context,
                      TextWidgetString('${serviceVM.CmdList![0].terms_nm}', getTextcenter(), getSize16(), getText700(), getColorblack_type2()),
                      _serviceAgreement,
                          (value) {
                        setState(() {
                          _serviceAgreement = value ?? false;
                          _allAgreement = _isAllChecked;
                        });
                      },
                      viewModel: CmdServiceViewModel(),
                      page: () => const CmdServiceView(),
                      choicestring: TextWidgetString('필수', getTextcenter(), getSize10(), getText700(), getColorsky_Type2()),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: getSize20().toDouble(), left: getSize20().toDouble()),
                    child: _buildAgreementRow_Service(
                      context,
                      TextWidgetString('${infoVM.CmdList![0].terms_nm}', getTextcenter(), getSize16(), getText700(), getColorblack_type2()),
                      _privacyAgreement,
                          (value) {
                        setState(() {
                          _privacyAgreement = value ?? false;
                          _allAgreement = _isAllChecked;
                        });
                      },
                      viewModel: CmdInformationViewModel(),
                      page: () => const CmdInformationView(),
                      choicestring: TextWidgetString('필수', getTextcenter(), getSize10(), getText700(), getColorsky_Type2()),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: getSize20().toDouble(), left: getSize20().toDouble()),
                    child: _buildAgreementRow_Service(
                      context,
                      TextWidgetString('${locationVM.CmdList![0].terms_nm}', getTextcenter(), getSize16(), getText700(), getColorblack_type2()),
                      _locationAgreement,
                          (value) {
                        setState(() {
                          _locationAgreement = value ?? false;
                          _allAgreement = _isAllChecked;
                        });
                      },
                      viewModel: CmdLocationViewModel(),
                      page: () => const CmdLocationView(),
                      choicestring: TextWidgetString('필수', getTextcenter(), getSize10(), getText700(), getColorsky_Type2()),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: getSize20().toDouble(), left: getSize20().toDouble()),
                    child: _buildAgreementRow_Service(
                      context,
                      TextWidgetString('${marketVM.CmdList![0].terms_nm}', getTextcenter(), getSize16(), getText700(), getColorblack_type2()),
                      _marketAgreement,
                          (value) {
                        setState(() {
                          _marketAgreement = value ?? false;
                          _allAgreement = _isAllChecked;
                        });
                      },
                      viewModel: CmdMarkettingViewModel(),
                      page: () => const CmdMarkettingview(),
                      choicestring: TextWidgetString('선택', getTextcenter(), getSize10(), getText700(), getColorgray_Type6()),
                    ),
                  ),
                ],

                const Spacer(),

                Center(
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isAllChecked
                          ? () async {
                        final selectedAgreements = [
                          if (_serviceAgreement) "서비스 이용약관",
                          if (_privacyAgreement) "개인정보수집/이용 동의",
                          if (_locationAgreement) "위치기반 서비스 이용약관",
                          if (_marketAgreement) "마케팅 활용 동의",
                        ];

                        debugPrint("버튼 클릭 시간: ${getCurrentDateDateTime()}");
                        debugPrint("선택된 약관: $selectedAgreements");

                        Navigator.push(
                          context,
                          createSlideTransition(
                            Membershipview(nowTime: getCurrentDateDateTime()),
                          ),
                        );
                      }
                          : null,
                      child: TextWidgetString('약관에 동의하고 계속하기', getTextcenter(), getSize16(), getText700(), getColorwhite_type1()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: getColorsky_Type2(),
                        shape: getTextradius6(),
                        elevation: 0,
                        padding: EdgeInsets.all(getSize18().toDouble()),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

}

//이용약관 레이어
Widget _buildAgreementRow_Service<T extends ChangeNotifier>(BuildContext context,Widget title,bool value,ValueChanged<bool?> onChanged,{required T viewModel,required Widget Function() page,required Widget choicestring}) {
  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        createSlideTransition(
          ChangeNotifierProvider.value(
            value: viewModel, // 기존 ViewModel을 유지
            child: page(),
          ),
          begin: const Offset(1.0, 0.0),
        ),
      );
    },
    child: Row(
      children: [
        Transform.scale(
          scale: 1.333,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: getColorsky_Type3(),
            checkColor: getColorwhite_type1(),
            shape: CircleBorder(),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: const VisualDensity(
              horizontal: VisualDensity.minimumDensity,
              vertical: VisualDensity.minimumDensity,
            ),
            side: BorderSide(
              color: getColorgray_Type7(),
              width: getSize1().toDouble(),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(left: getSize12().toDouble()),
          child: Container(
            padding: EdgeInsets.all(getSize4().toDouble()),
            decoration: BoxDecoration(
              color: getColorsky_Type1(),
              borderRadius: BorderRadius.circular(getSize4().toDouble()),
            ),
            child: choicestring,

          ),
        ),
        Padding(
          padding: EdgeInsets.only(left: getSize12().toDouble()),
          child: title,
        ),
        const Spacer(),
        Padding(
          padding: EdgeInsets.only(right: getSize20().toDouble()),
          child: SvgPicture.asset(
            'assets/kdn/usm/img/chevron-right.svg',
            height: getSize24().toDouble(),
            width: getSize24().toDouble(),
            fit: BoxFit.contain,
          ),
        ),
      ],
    ),
  );
}
