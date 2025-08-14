class CmdModel {
  int? terms_dt;
  String? terms_nm;
  int? id;
  String? terms_ctt;

  CmdModel({this.terms_dt, this.terms_nm, this.id,this.terms_ctt});

  factory CmdModel.fromJson(Map<String, dynamic> json) {
    return CmdModel(terms_dt: json['terms_dt'], terms_nm: json['terms_nm'], id: json['id'], terms_ctt: json['terms_ctt']);
  }
}