class PartNote {
  String id;
  String partid;
  String text;
  String added;
  String from_member;
  String from_user;
  String last_update;
  String live;

  PartNote({
    this.id,
    this.partid,
    this.text,
    this.added,
    this.from_member,
    this.from_user,
    this.last_update,
    this.live
  });

  factory PartNote.fromJson(Map<String, dynamic> json) {
    var response = PartNote(
        id: json['id'],
        partid: json['partid'],
        text: json['text'],
        added: json['added'],
        from_member: json['from_member'],
        last_update: json['last_update'],
        live: json['live']
    );

    return response;
  }
}