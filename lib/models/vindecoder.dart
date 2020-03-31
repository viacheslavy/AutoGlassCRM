import 'package:auto_glass_crm/classes/gallery_item.dart';
import 'package:auto_glass_crm/models/part_note.dart';
import 'package:auto_glass_crm/code/global.dart';
import 'dart:io';

class VindecoderAccessoryData{
  String type;
  String part_number;
}

class VindecoderPartData{
  String id;
  String part_number;
  String glass;
  String glass_type_id;
  String description;
  String count;
  List<String> dealer_part_nums;
  List<VindecoderAccessoryData> accessories;

  List<GalleryItem> photos;
  List<String> notes;
  List<String> videos;

  int photo_count;
  int video_count;
  int note_count;

  String trim;
  String series;
}

class VindecoderData {
  String searchid;
  String squishvin;
  String year;
  String make;
  String model;
  String body;
  String error;

  List<VindecoderPartData> parts;
  VindecoderData({
    this.searchid,
    this.squishvin,
    this.year,
    this.make,
    this.model,
    this.body
  });

  static VindecoderPartData getPart(Map<String, dynamic> p){
    VindecoderPartData part = new VindecoderPartData();
    part.id = p['id'];
    part.part_number = p['part_number'].toString();
    part.glass = p['glass'];
    part.glass_type_id = p['glass_type_id'];
    part.description = p['description'];
    part.count = p['count'];
    part.trim = p['trim'];
    part.series = p['series'];
    part.photo_count = 0;
    part.video_count = 0;
    part.note_count = 0;

    part.dealer_part_nums = List<String>();
    if ( p['dealer_part_nums'] != null && p['dealer_part_nums'] is List<dynamic> ) {
      for (var i = 0; i < p['dealer_part_nums'].length; i++) {
        part.dealer_part_nums.add(p['dealer_part_nums'][i]);
      }
    }

    part.accessories = List<VindecoderAccessoryData>();

    if ( p['accessories'] != null && p['accessories'] is List<dynamic>){
      for (var i = 0; i < p['accessories'].length; i++) {
        VindecoderAccessoryData access = new VindecoderAccessoryData();

        access.type = "";
        if ( p['accessories'][i]['type'] != null ) {
          access.type = p['accessories'][i]['type'].replaceAll("_", " ");
        }

        access.part_number = p['accessories'][i]['part_number'];

        part.accessories.add(access);
      }
    }


    part.photos = List<GalleryItem>();
    part.notes = List<String>();
    part.videos = List<String>();

    if ( p.containsKey("photos") && p["photos"] is List<dynamic>) {
      part.photo_count = p["photos"].length;
      for (var i = 0; i < p["photos"].length; i++) {
        var photo = p["photos"][i];
        part.photos.add(GalleryItem(
            id: i.toString(),
            isVideo: false,
            resource: Global.amazon_prefix + "/" + photo["url"]
        ));
      }
    }


    if ( p.containsKey("notes") && p["notes"] is List<dynamic>) {
      part.note_count = p["notes"].length;
      for (var i = 0; i < p["notes"].length; i++) {
        part.notes.add(p["notes"][i]["text"]);
      }
    }

    if ( p.containsKey("videos") && p["videos"] is List<dynamic> && p["videos"].length > 0 ){
      part.video_count = p["videos"].length;
      for (var i = 0; i < p["videos"].length; i++) {
        part.videos.add(p["videos"][i]["url"]);
      }
    }

    return part;
  }
  factory VindecoderData.fromJson(Map<String, dynamic> json) {
    VindecoderData response = VindecoderData(
        searchid: json['searchid'],
        squishvin: json['squishvin'],
        year: json['year'],
        make: json['make'],
        model: json['model'],
        body: json['body']
    );
    if ( json.containsKey("error") ){
      response.error = json["error"];
    }else{
      response.error = null;
    }

    response.parts = List<VindecoderPartData>();
    if ( json['parts'] is List<dynamic> ) {
      for(var i=0; i<json['parts'].length;i++){
        var p = json['parts'][i];
        VindecoderPartData part = VindecoderData.getPart(p);
        response.parts.add(part);
      }
    }
    else{
      json['parts'].forEach((k, v) {
        VindecoderPartData part = VindecoderData.getPart(v);
        response.parts.add(part);
      });
    }

    return response;
  }

}








