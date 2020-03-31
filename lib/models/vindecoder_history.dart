class VindecoderHistoryData{
  String id;
  String vin;
  String user;
  String whenrun;
  String partnumber;
}

class VindecoderHistory {
  List<VindecoderHistoryData> history;
  VindecoderHistory({
    this.history
  });

  factory VindecoderHistory.fromJson(List<dynamic> json) {
    VindecoderHistory response = VindecoderHistory(
    );
    response.history = List<VindecoderHistoryData>();

    for(var i=0;i<json.length;i++) {
      VindecoderHistoryData part = new VindecoderHistoryData();
      part.id = json[i]['id'];
      part.vin = json[i]['search'];
      part.user = json[i]['user'];
      part.whenrun = json[i]['first_run'];
      part.partnumber = json[i]['part_number'];
      response.history.add(part);
    }

    return response;
  }
}

class VindecoderAnswer {
  String id;
  String search;
  String when_run;
  String user;
  String part_number;
  String note;
  String admin_name;
  String glass;
  String glassId;
  String glassOptionId;
  String errorTime;
  String errorUser;

  VindecoderAnswer({
    this.id,
    this.search,
    this.when_run,
    this.user,
    this.part_number,
    this.note,
    this.admin_name,
    this.glass,
    this.glassId,
    this.glassOptionId,
    this.errorTime,
    this.errorUser
  });

  factory VindecoderAnswer.fromJson(Map<String, dynamic> json) {
    VindecoderAnswer response = VindecoderAnswer();
    response.id = json['id'];
    response.search = json['search'];
    response.when_run = json['when_run'];
    response.user = json['user'];
    response.part_number = json['part_number'];
    response.note = json['note'];
    response.admin_name = json['admin_name'];
    response.glass = json['glass'];
    response.glassId = json['glassId'];
    response.glassOptionId = json['glassOptionId'];

    if ( response.glassId == null ){
      response.glassId = "";
    }

    if ( response.glassOptionId == null ){
      response.glassOptionId = "";
    }

    response.errorTime = null;
    response.errorUser = null;
    if ( json.containsKey("errorTime") ){
      response.errorTime = json["errorTime"];
    }

    if ( json.containsKey("errorUser") ){
      response.errorUser = json["errorUser"];
    }

    return response;
  }
}