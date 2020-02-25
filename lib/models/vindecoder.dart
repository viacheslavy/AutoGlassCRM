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
  List<PartNote> notes;
  String video;

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

    part.photo_count = 0;
    part.video_count = 0;
    part.note_count = 0;
    part.photos = List<GalleryItem>();
    part.notes = List<PartNote>();
    part.video = "";
    if ( p.containsKey("photo_count") ){
      part.photo_count = int.tryParse(p["photo_count"])??0;
    }
    if ( p.containsKey("video_count")){
      part.video_count = int.tryParse(p["video_count"])??0;
    }
    if ( p.containsKey("note_count")){
      part.note_count = int.tryParse(p["note_count"])??0;
    }

    /*
    if ( p.containsKey("photos") && p["photos"] is List<dynamic>) {
      for (var i = 0; i < p["photos"].length; i++) {
        var photo = p["photos"][i];
        part.photos.add(GalleryItem(
            id: photo["id"],
            isVideo: false,
            resource: Global.amazon_prefix + "/" + photo["url"]
        ));
      }
    }


    if ( p.containsKey("notes") && p["notes"] is List<dynamic>) {
      for (var i = 0; i < p["notes"].length; i++) {
        PartNote note = PartNote.fromJson(p["notes"][i]);
        part.notes.add(note);
      }
    }

    if ( p.containsKey("videos") && p["videos"] is List<dynamic> && p["videos"].length > 0 ){
      part.video = p["videos"][0]["url"];
    }
    */

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








