import 'dart:convert';
import 'dart:io';

import 'package:auto_glass_crm/code/global.dart';
import 'dart:async';
import 'package:servicestack/client.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:path/path.dart' as Path;

import 'package:firebase_storage/firebase_storage.dart';


class UploadService {
  static Future<dynamic> getPartData(String partNum) async {
    var url = "https://" + Global.vinderPrefix + Global.domainSurfix + "/api/partdata";
    print(url);
    try {
      var uri = Uri.parse(url);
      var request = new http.MultipartRequest("POST", uri);
      Map<String, String> h = {"Authorization": Global.vindecoderAuth};
      request.headers.addAll(h);

      Map<String, String> params = {};
      params['part'] = partNum;

      request.fields.addAll(params);
      print(params);

      var response = await request.send().then((response) async {
        String responseData = await response.stream.transform(utf8.decoder).join(); // decodes on response data using UTF8.decoder
        return responseData;
      });
      print(response);
      return response;
    } on WebServiceException catch (e) {
      print("getPartData error1=" + e.message.toString());
      return null;
    } catch (e) {
      print("getPartData error2=" + e.toString());
      return null;
    }
  }

  static Future<String> uploadNote(String note, String partNum) async {
    var url = "https://" + Global.vinderPrefix + Global.domainSurfix + "/api/notetopart";

    try {
      var uri = Uri.parse(url);
      print(uri);

      var request = new http.MultipartRequest("POST", uri);
      Map<String, String> h = {
        "Authorization": Global.vindecoderAuth, //"9ffe506cf4efb2a41d2198998c9ee5a9"
      };
      request.headers.addAll(h);

      Map<String, String> params = {
        "user": Global.userID, // "9",
        "part": partNum,
        "note": note
      };
      request.fields.addAll(params);

      var response = await request.send().then((response) async {
        String responseData = await response.stream.transform(utf8.decoder).join(); // decodes on response data using UTF8.decoder
        return responseData;
      });
      print(response);

      var json_response = json.decode(response);
      if ( json_response["success"] == 1 ){
        return "upload_success";
      }
    } on WebServiceException catch (e) {
      print(e.message.toString());
    } catch (e) {
      print(e.message.toString());
    }

    return "upload_fail";
  }

  static Future<String> uploadPhoto(List<int> photoBytes, String partNum, String filename) async {
    var url = "https://" + Global.vinderPrefix + Global.domainSurfix + "/api/phototopart";

    try {
      var uri = Uri.parse(url);
      print(uri);

      var request = new http.MultipartRequest("POST", uri);
      Map<String, String> h = {
        "Authorization": Global.vindecoderAuth, //"9ffe506cf4efb2a41d2198998c9ee5a9"
      };
      request.headers.addAll(h);

      Map<String, String> params = {
        "part": partNum,
        "caption": "",
        "user": Global.userID
      };
      request.fields.addAll(params);

      print(params);


      var multipartFile = new http.MultipartFile.fromBytes('photo', photoBytes, filename: '$filename.jpg');
      request.files.add(multipartFile);

      var response = await request.send().then((response) async {
        String responseData = await response.stream.transform(utf8.decoder).join(); // decodes on response data using UTF8.decoder
        return responseData;
      });
      print(response);

      var json_response = json.decode(response);
      if ( json_response["success"] == 1 ){
        return "upload_success";
      }
    } on WebServiceException catch (e) {
      print(e.message.toString());
    } catch (e) {
      print(e.message.toString());
    }

    return "upload_fail";
  }

  static Future<String> uploadVideo(File file, String partNum) async {
    String uploadedFileURL = "";

    try {
      StorageReference storageReference = FirebaseStorage.instance.ref().child("uploads/" + partNum + "_" + new DateTime.now().millisecondsSinceEpoch.toString() + "." +  Path.extension(file.path));
      StorageUploadTask uploadTask = storageReference.putFile(file);


      uploadTask.events.listen((event){
        print(event.snapshot.bytesTransferred.toString() + "/" + event.snapshot.totalByteCount.toString());
      }).onError((error){
        print("upload video: " + error.toString());
      });


      await uploadTask.onComplete;
      print('Firebase File Upload completed');

      await storageReference.getDownloadURL().then((fileURL) {
        uploadedFileURL = fileURL;
      });

    }catch(e){
      print("firebase upload file error=" + e.message.toString());
    }

    if ( uploadedFileURL != "" ) {
      try {
        var url = "https://" + Global.vinderPrefix + Global.domainSurfix +
            "/api/videotopart";
        var uri = Uri.parse(url);
        print(uri);

        var request = new http.MultipartRequest("POST", uri);
        Map<String, String> h = {
          "Authorization": Global.vindecoderAuth,
        };
        request.headers.addAll(h);

        Map<String, String> params = {
          "user": Global.userID,
          "part": partNum,
          "url": uploadedFileURL
        };
        request.fields.addAll(params);

        var response = await request.send().then((response) async {
          String responseData = await response.stream.transform(utf8.decoder)
              .join(); // decodes on response data using UTF8.decoder
          return responseData;
        });
        print(response);

        var jsonResponse = json.decode(response);
        if (jsonResponse["success"] == 1) {
          return "upload_success";
        }
      }on WebServiceException catch (e) {
        print("video upload error1=" + e.message.toString());
      } catch (e) {
        print("video upload error2=" + e.message.toString());
      }
    }

    return "upload_fail";
  }

  static Future<String> endMetaUpload(String part, String countVideo, String countPhoto, String countNote) async {
    var url = "https://" + Global.vinderPrefix + Global.domainSurfix + "/api/endmetatopart";

    try {
      var uri = Uri.parse(url);
      print(uri);

      var request = new http.MultipartRequest("POST", uri);
      Map<String, String> h = {
        "Authorization": Global.vindecoderAuth, //"9ffe506cf4efb2a41d2198998c9ee5a9"
      };
      request.headers.addAll(h);

      Map<String, String> params = {
        "user": Global.userID, // "9",
        "part": part,
        "count_video": countVideo,
        "count_photo": countPhoto,
        "count_note": countNote
      };
      request.fields.addAll(params);

      var response = await request.send().then((response) async {
        String responseData = await response.stream.transform(utf8.decoder).join(); // decodes on response data using UTF8.decoder
        return responseData;
      });
      print(response);
    } on WebServiceException catch (e) {
      print("error1=" + e.message.toString());
    } catch (e) {
      print("error2=" + e.message.toString());
    }

    return "";
  }
}
