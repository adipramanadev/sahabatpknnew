class LoginModel {
  bool? ok;
  int? status;
  String? message;
  User? user;

  LoginModel({this.ok, this.status, this.message, this.user});

  LoginModel.fromJson(Map<String, dynamic> json) {
    ok = json['ok'];
    status = json['status'];
    message = json['message'];
    user = json['user'] != null ? new User.fromJson(json['user']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['ok'] = this.ok;
    data['status'] = this.status;
    data['message'] = this.message;
    if (this.user != null) {
      data['user'] = this.user!.toJson();
    }
    return data;
  }
}

class User {
  String? userID;
  String? username;
  String? email;

  User({this.userID, this.username, this.email});

  User.fromJson(Map<String, dynamic> json) {
    userID = json['userID'];
    username = json['username'];
    email = json['email'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['userID'] = this.userID;
    data['username'] = this.username;
    data['email'] = this.email;
    return data;
  }
}