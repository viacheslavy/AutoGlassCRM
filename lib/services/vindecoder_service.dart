import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:auto_glass_crm/code/global.dart';
import 'package:auto_glass_crm/models/vindecoder.dart';
import 'package:auto_glass_crm/models/vindecoder_history.dart';
import 'dart:async';
import 'package:servicestack/client.dart';
import 'package:http/http.dart' as http;

import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as Path;

class VindecoderService {
  static Future<dynamic> getVindecoder(String s, String type, String option) async {
    var url = Global.domainFirst + Global.domainPrefix + Global.domainSurfix + "/vindecoder/search?s=${Uri.encodeComponent(s)}&type=${Uri.encodeComponent(type)}&opt=${Uri.encodeComponent(option)}";
    print(url);
    try {
      var client = Global.theHttpClient();
      Global.setAuthorizationToJsonServiceClient(client, Global.userToken);
      var response = await client.getAs(url);
      print(response);
      return response;
    } on WebServiceException catch (e) {
      print("error1=" + e.message.toString());
      if ( e.message.toString().trim() == "Invalid authentication" ){
        return "Invalid authentication";
      }
      return "network_error";
    } catch (e) {
      print("error2=" + e.toString());
      return "error";
    }
  }


  static Future<dynamic> getVindecoderHistory(String s, int pnum, int psize) async {
    var url = Global.domainFirst + Global.domainPrefix + Global.domainSurfix + "/vindecoder/apphistory?s=${Uri.encodeComponent(s)}&pnum=" + pnum.toString() + "&psize=" + psize.toString();
    print(url);
    try {
      var client = Global.theHttpClient();
      Global.setAuthorizationToJsonServiceClient(client, Global.userToken);
      var response = await client.getAs(url);
      print(response);

      return response;
    } on WebServiceException catch (e) {
      print(e.message.toString());
      return null;
    } catch (e) {
      print(e);
      return null;
    }
  }

  static Future<String> sendHelpRequest(String user, String search, String searchid, String glass, String option, String other) async {
    var url = Global.domainFirst + Global.domainPrefix + Global.domainSurfix + "/vindecoder/requesthelp";
    print(url);
    try {
      var uri = Uri.parse(url);
      var request = new http.MultipartRequest("POST", uri);
      Map<String, String> h = {"Authorization": Global.userToken};
      request.headers.addAll(h);

      Map<String, String> params = {};
      params['user'] = user;
      params['search'] = search;
      if ( searchid == null ){
        params['searchid'] = "0";
      }else {
        params['searchid'] = searchid;
      }
      params['glass'] = glass;
      params['option'] = option;
      params['other'] = other;

      request.fields.addAll(params);
      print(params);

      var response = await request.send().then((response) async {
        String responseData = await response.stream.transform(utf8.decoder).join(); // decodes on response data using UTF8.decoder
        return responseData;
      });
      print(response);
      return response;
    } on WebServiceException catch (e) {
      print("sendHelpRequest error1=" + e.message.toString());
      return null;
    } catch (e) {
      print("sendHelpRequest error2=" + e.toString());
      return null;
    }
  }

  static Future<Map<String, dynamic>> checkAnswer(String id) async {
    var url = Global.domainFirst + Global.domainPrefix + Global.domainSurfix + "/vindecoder/checkresponse/" + id;
    print(url);
    try {
      var client = Global.theHttpClient();
      Global.setAuthorizationToJsonServiceClient(client, Global.userToken);
      var response = await client.getAs(url);
      print(response);

      return response;
    } on WebServiceException catch (e) {
      print(e.message.toString());
      return null;
    } catch (e) {
      print(e);
      return null;
    }
  }

  static Future<VindecoderAnswer> getVindecoderAnswer(String id) async {
    var url = Global.domainFirst + Global.domainPrefix + Global.domainSurfix + "/vindecoder/appanswer/" + id;
    print(url);
    try {
      var client = Global.theHttpClient();
      Global.setAuthorizationToJsonServiceClient(client, Global.userToken);
      var response = await client.getAs(url);
      print(response);
      if (response == null ) return null;
      var result = VindecoderAnswer.fromJson(response);
      return result;
    } on WebServiceException catch (e) {
      print(e.message.toString());
      return null;
    } catch (e) {
      print(e);
      return null;
    }
  }


  static Future<bool> validateVIN(String _vin) async{
    try {
      var url = "https://www.decodethis.com/webservices/decodes/" + _vin + "/_vSxUkWSvHaDnxUcsaAs/0.jsonp";
      var uri = Uri.parse(url);
      print(uri);

      JsonServiceClient client = JsonServiceClient();
      var response = await client.getAs(url);
      print(response);

      if (response["decode"]["status"] == "SUCCESS") {
        return true;
      }
      else{
        return false;
      }
    }on WebServiceException catch (e) {
      print("validate vin error1=" + e.message.toString());
    } catch (e) {
      print("validate vin error2=" + e.toString());
    }
    return false;
  }


  static Future<String> sendVideoHelpRequest(File file, String vinNum, String glassType, String glassOption, String other) async {
    String uploadedFileURL = "";
    try {

      StorageReference storageReference = FirebaseStorage.instance.ref().child("uploads/" + vinNum + "_" + new DateTime.now().millisecondsSinceEpoch.toString() + "." +  Path.extension(file.path));
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
        var url = "https://" + Global.domainPrefix + Global.domainSurfix +
            "/vindecoder/vinvideoquery";
        var uri = Uri.parse(url);
        print(uri);

        var request = new http.MultipartRequest("POST", uri);
        Map<String, String> h = {
          "Authorization": Global.userToken,
        };
        request.headers.addAll(h);

        Map<String, String> params = {
          "vin": vinNum,
          "glass": glassType,
          "option": glassOption,
          "other": other,
          "video": uploadedFileURL
        };
        request.fields.addAll(params);

        var response = await request.send().then((response) async {
          String responseData = await response.stream.transform(utf8.decoder)
              .join(); // decodes on response data using UTF8.decoder
          return responseData;
        });
        print(response);

        if ( response == "true" )
          return "upload_success";

        var jsonResponse = json.decode(response);
        if (jsonResponse["success"] == 1) {
          return "upload_success";
        }
        else{
          return jsonResponse["message"];
        }

      }on WebServiceException catch (e) {
        print("video upload error1=" + e.message.toString());
      } catch (e) {
        print("video upload error2=" + e.toString());
      }
    }

    return "upload_fail";
  }







  static bool checkMake(String _make){
    var make = "";
    if ( _make != null )
      make = _make.toUpperCase();
    if ( make == "MACK" ||
        make == "FREIGHTLINER" ||
        make == "PETERBILT" ||
        make == "INTERNATIONAL" ||
        make == "NAVISTAR" ||
        make == "AUTOCAR" ||
        make == "KENWORTH" ||
        make == "STERLING" ||
        make == "VOLVO VN" ||
        make == "WESTERN STAR TRUCKS" ||
        make == "WHITEGMC"
    ){
      return true;
    }

    return false;
  }
}
