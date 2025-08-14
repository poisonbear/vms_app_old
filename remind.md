## 폴더 구조


# 20241029 낙월해상풍력 운영시스템 2종 개발표준정의서_v1.9 를 참조함

kdn

---cmm [공통코드 관리]
   --- common_action.dart [어떤한 액션이 일어날 때는 해당 폴더에 꺼내서 사용을 하시거나 추가를 하시면 됩니다.]
---cmm_widget
   --- common_size_widget.dart [어떤 크기를 키우고 싶을때는 여기서]
   --- common_style_widget.dart [어떤 색상이나 스타일 변경이 필요 할 때는]
   --- common_utill.dart [위치권한 관리 , 알람권한 관리]
   --- common_widget.dart [어떤 액션이 일어나지는 않지만, 단순한 글자나 , 파일 불러오기 등등 관리 할 때는 여기서 추가를 하시면 됩니다.  ]


---usm [회원관련기능] 
   ---DataSourec
      ---CmdSource.dart[서비스 이용약관 , 개인정보수집/이둉동의, 위치기반 서비스 이용약관 데이터 가져오기]
   ---model
      ---CmdModel.dart[이용약관 모델관리]
   ---repository
      ---CmdRepository.dart[약관 데이터 저장]
   ---view
      ---Cmddetail
         ---CmdInformationView.dart [개인정보수집/이용동의 화면]
         ---CmdLocationView.dart    [위치기반 서비스동의 화면]
         ---CmdServiceView.dart     [서비스 이용약관 동의 화면]
         ---CmdMarkettingView.dart  [마케팅 활용 동의 화면]
      ---layer
         ---AppBarLayerView.dart [상단 제목]
      ---CmdChoiceView.dart[정보 제공 동의서 선택 화면]
      ---LoginView.dart[로그인 화면]
      ---Membership.dart[회원가입 화면]
      ---MembershipClearView.dart[회원가입 완료화면]
      ---MemberInformationView.dart[마이페이지]
      ---MemberInformationChange.dart[회원정보수정]
   ---viewModel
      ---detail
         ---CmdInformationViewModel.dart [개인정보수집/이용동의 컨트롤러]
         ---CmdLocationViewModel.dart    [위치기반 서비스동의 컨트롤러]
         ---CmdServiceViewModel.dart     [서비스 이용약관 동의 컨트롤러]
         ---CmdMarkettingViewModel.dart  [마케팅 활용 동의 컨트롤러]


---ros [항행이력]
   ---DataSourec
   ---model
   ---repository
   ---view
      ---mainView.dart[메인화면]
      ---mainView_navigationTap.dart[항행이력 탭]
      ---mainView_navigationTap_date.dart[항행이력 달력]
      ---mainView_windyTap.dart[기상탭]
      ---mainView_windyTap_date.dart[기상탭 달력]
   ---viewModel
      ---mainViewModel.dart[메인화면 컨트롤러]




## 빌드하기 
flutter build apk --release --obfuscate --split-debug-info=/<debug-symbols-directory>

## jdk 변경
flutter config --jdk-dir="C:\Program Files\Java\jdk-11"
flutter config --jdk-dir="C:\Program Files\jdk-11.0.0.2"



### 업데이트 데스트 확인



