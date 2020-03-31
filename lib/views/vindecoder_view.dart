import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:auto_glass_crm/code/global.dart';
import 'package:auto_glass_crm/models/vindecoder.dart';
import 'package:auto_glass_crm/models/vindecoder_history.dart';
import 'package:auto_glass_crm/services/vindecoder_service.dart';
import 'package:auto_glass_crm/services/upload_service.dart';
import 'package:auto_glass_crm/classes/gallery_item.dart';
import 'package:auto_glass_crm/models/part_note.dart';
import 'package:auto_glass_crm/views/gallery_photo_view_wrapper.dart';
import 'package:auto_glass_crm/views/youtube_video_view.dart';
import 'package:auto_glass_crm/views/vin_detection_page.dart';

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_device_type/flutter_device_type.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class JobTypeDropDownItem{
  String id;
  String text;
  JobTypeDropDownItem(this.id, this.text);
}

class JobGlassOptionDropDownItem{
  String id;
  String text;
  JobGlassOptionDropDownItem(this.id, this.text);
}

class VindecoderView extends StatefulWidget {
  _VindecoderViewState state;
  @override
  _VindecoderViewState createState() {
    state = new _VindecoderViewState();
    return state;
  }
}

class _VindecoderViewState extends State<VindecoderView> {
  final scaffoldKey = new GlobalKey<ScaffoldState>();
  bool _dataLoaded = false;
  bool  _isLoading = false;
  bool _hasError = false;
  bool _showExtraOption = false;

  Color color_bg = Color(0xFFCCCCCC);
  VindecoderData _vindecoder = new VindecoderData();

  String topAlertText = "";
  String _searchKey = "";
  String _errorMsg = "";

  bool _isSendingHelpRequest = false;
  bool _isSentHelpRequest = false;
  bool _hasHelpRequestError = false;

  List<JobTypeDropDownItem> jobTypeItems = new List();
  String _selectedJobType = "4";

  List<JobGlassOptionDropDownItem> backGlassOptions = new List();
  List<JobGlassOptionDropDownItem> doorGlassOptions = new List();
  List<JobGlassOptionDropDownItem> heavyGlassOptions = new List();
  List<JobGlassOptionDropDownItem> quarterGlassOptions = new List();
  List<JobGlassOptionDropDownItem> ventGlassOptions = new List();
  String _selectedJobOption = "1";

  TextEditingController _otherOptionController = new TextEditingController(text: "");
  String _otherOption = "";


  TextEditingController _vinNumController = new TextEditingController(text: "");
  String _vinNum = "";

  String _selectedPartNum = "";


  @override
  void initState() {
    super.initState();


    /* Job Glass */
    jobTypeItems.add(JobTypeDropDownItem("1", "Back Glass"));
    jobTypeItems.add(JobTypeDropDownItem("2", "Door Glass"));
    jobTypeItems.add(JobTypeDropDownItem("21", "Partition Glass"));
    jobTypeItems.add(JobTypeDropDownItem("3", "Quarter Glass"));
    jobTypeItems.add(JobTypeDropDownItem("19", "Roof Glass"));
    jobTypeItems.add(JobTypeDropDownItem("22", "Vent Glass"));
    jobTypeItems.add(JobTypeDropDownItem("4", "Windshield Glass"));
    jobTypeItems.add(JobTypeDropDownItem("23", "Heavy Duty Truck Windshield"));

    /* Back Option */
    backGlassOptions.add(JobGlassOptionDropDownItem("1", "1 Piece (Car / SUV / Truck)"));
    backGlassOptions.add(JobGlassOptionDropDownItem("2", "Rear Left (Van only)"));
    backGlassOptions.add(JobGlassOptionDropDownItem("3", "Rear Right (Van only)"));

    /* Door Option */
    doorGlassOptions.add(JobGlassOptionDropDownItem("1", "Front Left"));
    doorGlassOptions.add(JobGlassOptionDropDownItem("2", "Front Right"));
    doorGlassOptions.add(JobGlassOptionDropDownItem("3", "Rear Left"));
    doorGlassOptions.add(JobGlassOptionDropDownItem("4", "Rear Right"));
    doorGlassOptions.add(JobGlassOptionDropDownItem("5", "Other"));

    /* Heavy Option */
    heavyGlassOptions.add(JobGlassOptionDropDownItem("1", "1 Piece"));
    heavyGlassOptions.add(JobGlassOptionDropDownItem("2", "Left Side"));
    heavyGlassOptions.add(JobGlassOptionDropDownItem("3", "Right Side"));
    heavyGlassOptions.add(JobGlassOptionDropDownItem("4", "Both Sides"));

    /* Quarter Option */
    quarterGlassOptions.add(JobGlassOptionDropDownItem("1", "Rear Left"));
    quarterGlassOptions.add(JobGlassOptionDropDownItem("2", "Rear Right"));
    quarterGlassOptions.add(JobGlassOptionDropDownItem("3", "Other"));

    /* Vent Option */
    ventGlassOptions.add(JobGlassOptionDropDownItem("1", "Front Left"));
    ventGlassOptions.add(JobGlassOptionDropDownItem("2", "Front Right"));
  }

  clickedSearch(){
    if ( _isLoading ){
      return;
    }

    _vinNum = _vinNumController.text.trim();
    if ( _vinNum.length == 0 ){
      final snackBar = SnackBar(
        content: Text("Please type part number."),
      );
      Scaffold.of(context).showSnackBar(snackBar);
      return;
    }

    if ( _selectedJobType == "2" && _selectedJobOption == "5" || _selectedJobType == "3" && _selectedJobOption == "3" ){
      if ( _otherOptionController.text.trim().length == 0 ){
        final snackBar = SnackBar(
          content: Text(
            'Please type other option.',
          ),
        );
        Scaffold.of(context).showSnackBar(snackBar);
        setState(() {});
        return;
      }
    }

    if ( _selectedJobType == "4" || _selectedJobType == "19" || _selectedJobType == "21" ){
      _selectedJobOption = "";
      _otherOptionController.text = "";
    }

    if ( _selectedJobType == "1" || _selectedJobType == "23" || _selectedJobType == "22") {
      _otherOptionController.text = "";
    }

    loadData(_vinNum, _selectedJobType, _selectedJobOption, _otherOptionController.text.trim());
  }

  clickedReset(){
    _vinNumController.text = "";
    _vinNum = "";
    _selectedJobType = "4";
    _selectedJobOption = "1";
    _otherOption = "";
    _otherOptionController.text = "";
    _selectedPartNum = "";

    setState(() {
    });
  }

  Future<VindecoderData> loadData(s, type, option, other_option) async {
    if ( _isSendingHelpRequest ){
      return null;
    }
    _isLoading = true;
    _dataLoaded = false;
    topAlertText = "";
    _hasHelpRequestError = false;
    _isSentHelpRequest = false;
    _errorMsg = "";
    _selectedPartNum = "";
    _showExtraOption = false;

    setState(() {});

    _vindecoder = null;
    var response = await VindecoderService.getVindecoder(s, type, option);

    if ( response == null){
      _errorMsg = "No results for this search";
    }
    else if ( response == "error"){
      _errorMsg = "Error has occurred";
    }
    else if ( response == "Invalid authentication"){
      _errorMsg = "Invalid authentication.";
    }
    else if ( response == "network_error"){
      _errorMsg = "Network error has occured.";
    }
    else{
      if ( response.containsKey("success") && response["success"] == 0 ){
        Global.checkResponse(context, response["message"]);
      }
      else if ( response.containsKey("error") ) {
        _vindecoder = VindecoderData.fromJson(response);
        _errorMsg = response["error"];
        _vindecoder = null;
      }
      else{
        _vindecoder = VindecoderData.fromJson(response);

        if ( _vindecoder == null ){
          _errorMsg = "Error has occurred";
        }
        else if ( _vindecoder.squishvin == null && (_vindecoder.parts == null || _vindecoder.parts.length == 0 ) ){
          _vindecoder = null;
          _errorMsg = "Your search returned no results. Please search again by VIN. If you were trying to search by VIN, your entry was invalid, so please double-check your VIN's numbers and letters so we can get your matching results!";
        }
      }
    }

    _isLoading = false;
    if (_vindecoder != null ) {
      _dataLoaded = true;
      _searchKey = s;

      if ( VindecoderService.checkMake(_vindecoder.make) && type == "4" ){
        _showExtraOption = true;
        _selectedJobType = "23";
        _selectedJobOption = "1";
        _otherOption = "";
        _otherOptionController.text = "";
      }

      bool showMessage = false;
      var windShieldCount = 0;
      for (var i = 0; i < _vindecoder.parts.length; i++) {
          if ( _vindecoder.parts[i].glass_type_id == "1" ){
            windShieldCount++;
          }
      }
      if ( windShieldCount > 1 ){
        showMessage = true;
      }


      if ( showMessage && topAlertText == ""){
        if ( _vindecoder.squishvin == null && (_vindecoder.parts != null && _vindecoder.parts.length > 0 ) ) {

        }
        else{
          topAlertText =
          "This VIN number has multiple windshield options, ask customer which trim they have, or description of windshield";
        }
      }

      _hasError = false;
    } else {
      _hasError = true;
    }






    if ( this.mounted ) {
      setState(() {});
    }

    return _vindecoder;
  }

  Widget _buildBodySkeleton([double opacity = 0.45]) {
    return Opacity(
      opacity: opacity,
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300],
        highlightColor: Colors.grey[100],
        child: Container(
          padding: EdgeInsets.fromLTRB(10.0, 0.0, 10.0, 0.0),
          child: Container(
            height: 100,
            decoration: new BoxDecoration(
              image: new DecorationImage(
                image: new AssetImage("assets/skele.png"),
                fit: BoxFit.contain,
                //colorFilter: new ColorFilter.mode(Colors.white.withOpacity(opacity), BlendMode.dstATop)
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
            ),
          ),
        ),
      ),
    );
  }

  sendHelpRequest() async{
    if ( _isSendingHelpRequest || _vindecoder == null ){
      return;
    }

    if ( _searchKey.length != 17 ){
      final snackBar = SnackBar(
        content: Text(
          'Your VIN is not 17 characters. Please correct the VIN before requesting help.',
        ),
      );
      Scaffold.of(context).showSnackBar(snackBar);
      setState(() {});
      return;
    }

    if ( _selectedJobType == "2" && _selectedJobOption == "5" || _selectedJobType == "3" && _selectedJobOption == "3" ){
      if ( _otherOptionController.text.trim().length == 0 ){
        final snackBar = SnackBar(
          content: Text(
            'Please type other option.',
          ),
        );
        Scaffold.of(context).showSnackBar(snackBar);
        setState(() {});
        return;
      }
    }

    if ( _selectedJobType == "4" || _selectedJobType == "19" || _selectedJobType == "21" ){
      _selectedJobOption = "";
      _otherOptionController.text = "";
    }

    if ( _selectedJobType == "1" || _selectedJobType == "23" || _selectedJobType == "22") {
      _otherOptionController.text = "";
    }



    _isSendingHelpRequest = true;
    _isSentHelpRequest = false;
    _hasHelpRequestError = false;

    setState(() {});

    String ret = await VindecoderService.sendHelpRequest(Global.userID, _searchKey, _vindecoder.searchid, _selectedJobType, _selectedJobOption, _otherOptionController.text.trim());
    if ( ret != null ){
      if ( ret == "true" ) {
        _hasHelpRequestError = false;
      }
      else if ( ret == "false" ){
        _hasHelpRequestError = true;
      }
      else {
        if ( ret != null ){
          ret = ret.replaceAll('"', '');
        }
        var value = int.tryParse(ret, radix: 10);
        if ( value != null )
          showAnswer(value);
      }
    }

    _isSentHelpRequest = true;
    _isSendingHelpRequest = false;
    setState(() {});
  }


  bool isGettingAnswer = false;

  showAnswer(_id) async{
    if ( isGettingAnswer ){
      return;
    }
    Color colorBg = Color(0xFFCCCCCC);
    double fontSize = 11.0;

    isGettingAnswer = true;
    setState(() {
    });

    var snackBarLoading = SnackBar(
      duration: Duration(seconds: 300),
      content: new Row(
        children: <Widget>[
          new CircularProgressIndicator(),
          new Text("  Loading...")
        ],
      ),
    );

    Scaffold.of(context).showSnackBar(snackBarLoading);
    VindecoderAnswer ret = await VindecoderService.getVindecoderAnswer(_id.toString());
    Scaffold.of(context).hideCurrentSnackBar();

    if ( ret != null ){
      showDialog<ConfirmAction>(
        context: context,
        barrierDismissible: false, // user must tap button for close dialog!
        builder: (BuildContext context) {
          Container mContainer = new Container(
              child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Column(
                      children: <Widget>[
                        /* VIN */
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              Expanded(
                                child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: color_bg,
                                      border: Border(
                                        top: BorderSide(width: 1.0,
                                            color: Colors.black54),
                                        left: BorderSide(width: 1.0,
                                            color: Colors.black54),
                                        right: BorderSide(width: 1.0,
                                            color: Colors.black54),
                                        bottom: BorderSide(width: 1.0,
                                            color: Colors.black54),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text('VIN',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: fontSize
                                        ),
                                      ),
                                    )
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 5),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        top: BorderSide(width: 1.0,
                                            color: Colors.black54),
                                        right: BorderSide(width: 1.0,
                                            color: Colors.black54),
                                        bottom: BorderSide(width: 1.0,
                                            color: Colors.black54),
                                      ),
                                    ),
                                    child: Text(ret.search==null?"":ret.search,
                                      textAlign: TextAlign.start,
                                      style: TextStyle(
                                          fontSize: fontSize
                                      ),
                                    )
                                ),
                              ),
                            ],
                          ),
                        ),

                        /* Requested By */
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              Expanded(
                                child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: color_bg,
                                      border: Border(
                                        left: BorderSide(width: 1.0,
                                            color: Colors.black54),
                                        right: BorderSide(width: 1.0,
                                            color: Colors.black54),
                                        bottom: BorderSide(width: 1.0,
                                            color: Colors.black54),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text('Requested By',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: fontSize
                                        ),
                                      ),
                                    )
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 5),
                                    decoration: BoxDecoration(

                                      border: Border(
                                        right: BorderSide(width: 1.0,
                                            color: Colors.black54),
                                        bottom: BorderSide(width: 1.0,
                                            color: Colors.black54),
                                      ),
                                    ),
                                    child: Text(ret.user==null?"":ret.user,
                                        textAlign: TextAlign.justify,
                                        style: TextStyle(
                                            fontSize: fontSize
                                        )
                                    )
                                ),
                              ),
                            ],
                          ),
                        ),

                        /* Submitted */
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              Expanded(
                                child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: color_bg,
                                      border: Border(
                                        left: BorderSide(width: 1.0,
                                            color: Colors.black54),
                                        right: BorderSide(width: 1.0,
                                            color: Colors.black54),
                                        bottom: BorderSide(width: 1.0,
                                            color: Colors.black54),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text('Submitted',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: fontSize
                                        ),
                                      ),
                                    )
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 5),
                                    decoration: BoxDecoration(

                                      border: Border(
                                        right: BorderSide(width: 1.0,
                                            color: Colors.black54),
                                        bottom: BorderSide(width: 1.0,
                                            color: Colors.black54),
                                      ),
                                    ),
                                    child: Text(ret.when_run==null?"":ret.when_run,
                                      textAlign: TextAlign.justify,
                                      style: TextStyle(
                                          fontSize: fontSize
                                      ),
                                    )
                                ),
                              ),
                            ],
                          ),
                        ),

                        /* Glass Type */
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              Expanded(
                                child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: color_bg,
                                      border: Border(
                                        left: BorderSide(width: 1.0,
                                            color: Colors.black54),
                                        right: BorderSide(width: 1.0,
                                            color: Colors.black54),
                                        bottom: BorderSide(width: 1.0,
                                            color: Colors.black54),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text('Glass Type',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: fontSize
                                        ),
                                      ),
                                    )
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 5),
                                    decoration: BoxDecoration(

                                      border: Border(
                                        right: BorderSide(width: 1.0,
                                            color: Colors.black54),
                                        bottom: BorderSide(width: 1.0,
                                            color: Colors.black54),
                                      ),
                                    ),
                                    child: Text(ret.glass==null?"":ret.glass,
                                      textAlign: TextAlign.justify,
                                      style: TextStyle(
                                          fontSize: fontSize
                                      ),
                                    )
                                ),
                              ),
                            ],
                          ),
                        ),

                        /* Part Number */
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              Expanded(
                                child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: color_bg,
                                      border: Border(
                                        left: BorderSide(width: 1.0,
                                            color: Colors.black54),
                                        right: BorderSide(width: 1.0,
                                            color: Colors.black54),
                                        bottom: BorderSide(width: 1.0,
                                            color: Colors.black54),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text("Part Number",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: fontSize
                                        ),
                                      ),
                                    )
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 5),
                                    decoration: BoxDecoration(

                                      border: Border(
                                        right: BorderSide(width: 1.0,
                                            color: Colors.black54),
                                        bottom: BorderSide(width: 1.0,
                                            color: Colors.black54),
                                      ),
                                    ),
                                    child: Text(ret.part_number==null?"":ret.part_number,
                                        textAlign: TextAlign.justify,
                                        style: TextStyle(
                                            fontSize: fontSize
                                        )
                                    )
                                ),
                              ),
                            ],
                          ),
                        ),

                        /* Note */
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              Expanded(
                                child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: color_bg,
                                      border: Border(
                                        left: BorderSide(width: 1.0,
                                            color: Colors.black54),
                                        right: BorderSide(width: 1.0,
                                            color: Colors.black54),
                                        bottom: BorderSide(width: 1.0,
                                            color: Colors.black54),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text("Note",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: fontSize
                                        ),
                                      ),
                                    )
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 5),
                                    decoration: BoxDecoration(

                                      border: Border(
                                        right: BorderSide(width: 1.0,
                                            color: Colors.black54),
                                        bottom: BorderSide(width: 1.0,
                                            color: Colors.black54),
                                      ),
                                    ),
                                    child: Text(ret.note==null?"":ret.note,
                                        textAlign: TextAlign.justify,
                                        style: TextStyle(
                                            fontSize: fontSize
                                        )
                                    )
                                ),
                              ),
                            ],
                          ),
                        ),

                        /* Answered by */
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              Expanded(
                                child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: color_bg,
                                      border: Border(
                                        left: BorderSide(width: 1.0,
                                            color: Colors.black54),
                                        right: BorderSide(width: 1.0,
                                            color: Colors.black54),
                                        bottom: BorderSide(width: 1.0,
                                            color: Colors.black54),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text('Answered by',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: fontSize
                                        ),
                                      ),
                                    )
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 5),
                                    decoration: BoxDecoration(

                                      border: Border(
                                        right: BorderSide(width: 1.0,
                                            color: Colors.black54),
                                        bottom: BorderSide(width: 1.0,
                                            color: Colors.black54),
                                      ),
                                    ),
                                    child: Text(ret.admin_name==null?"":ret.admin_name,
                                        textAlign: TextAlign.justify,
                                        style: TextStyle(
                                            fontSize: fontSize
                                        )
                                    )
                                ),
                              ),
                            ],
                          ),
                        ),
                      ]
                  )
              )
          );

          return AlertDialog(
            contentPadding: EdgeInsets.all(5.0),
            title: Text('Answer Detail'),
            content: SingleChildScrollView(
                child: mContainer
            ),
            actions: <Widget>[
              FlatButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop(ConfirmAction.CANCEL);
                },
              )
            ],
          );
        },
      );
    }
    else{
      final snackBar = SnackBar(
        content: Text(
          'Something went wrong. Please try again!',
        ),
      );
      Scaffold.of(context).showSnackBar(snackBar);
    }

    isGettingAnswer = false;

    setState(() {
    });
  }

  _buildDivider() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: Divider(
        color: Colors.grey,
      ),
    );
  }

  _buildTrims(){
    List<Widget> trimsWidget = new List();

    if ( _vindecoder != null ) {
      if (_vindecoder.parts.length == 0) {
        trimsWidget.add(
            Container(
                child: Center(
                    child: Text("Sorry, no validated results for your search",
                      textAlign: TextAlign.center,)
                )
            )
        );
      }


      if ( Device.get().isTablet ) {
        List<Widget> partsWidgets = new List();


        partsWidgets.add(
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  flex: 2,
                  child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 5, vertical: 5),
                      decoration: BoxDecoration(
                        color: color_bg,
                        border: Border(
                          top: BorderSide(width: 1.0,
                              color: Colors.black54),
                          left: BorderSide(width: 1.0,
                              color: Colors.black54),
                          right: BorderSide(width: 1.0,
                              color: Colors.black54),
                          bottom: BorderSide(width: 1.0,
                              color: Colors.black54),
                        ),
                      ),
                      child: Center(
                        child: Text('Glass Type',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontWeight: FontWeight.bold),
                        ),
                      )
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 5, vertical: 5),
                      decoration: BoxDecoration(
                        color: color_bg,
                        border: Border(
                          top: BorderSide(width: 1.0,
                              color: Colors.black54),
                          right: BorderSide(width: 1.0,
                              color: Colors.black54),
                          bottom: BorderSide(width: 1.0,
                              color: Colors.black54),
                        ),
                      ),
                      child: Center(
                        child: Text("Part #",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontWeight: FontWeight.bold
                          ),
                        ),
                      )
                  ),
                ),

                Expanded(
                  flex: 1,
                  child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 5, vertical: 5),
                      decoration: BoxDecoration(
                        color: color_bg,
                        border: Border(
                          top: BorderSide(width: 1.0,
                              color: Colors.black54),
                          right: BorderSide(width: 1.0,
                              color: Colors.black54),
                          bottom: BorderSide(width: 1.0,
                              color: Colors.black54),
                        ),
                      ),
                      child: Text("Times Used",
                        textAlign: TextAlign.start,
                        style: TextStyle(
                            fontWeight: FontWeight.bold
                        ),
                      )
                  ),
                ),

                Expanded(
                  flex: 3,
                  child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 5, vertical: 5),
                      decoration: BoxDecoration(
                        color: color_bg,
                        border: Border(
                          top: BorderSide(width: 1.0,
                              color: Colors.black54),
                          right: BorderSide(width: 1.0,
                              color: Colors.black54),
                          bottom: BorderSide(width: 1.0,
                              color: Colors.black54),
                        ),
                      ),
                      child: Center(
                        child: Text("Description",
                          textAlign: TextAlign.start,
                          style: TextStyle(
                              fontWeight: FontWeight.bold
                          ),
                        )
                      )
                  ),
                ),

                Expanded(
                  flex: 2,
                  child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 5, vertical: 5),
                      decoration: BoxDecoration(
                        color: color_bg,
                        border: Border(
                          top: BorderSide(width: 1.0,
                              color: Colors.black54),
                          right: BorderSide(width: 1.0,
                              color: Colors.black54),
                          bottom: BorderSide(width: 1.0,
                              color: Colors.black54),
                        ),
                      ),
                      child: Center(
                        child:Text("Dealer Part #",
                          textAlign: TextAlign.start,
                          style: TextStyle(
                              fontWeight: FontWeight.bold
                          ),
                        )
                      )
                  ),
                ),

                Expanded(
                  flex: 2,
                  child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 5, vertical: 5),
                      decoration: BoxDecoration(
                        color: color_bg,
                        border: Border(
                          top: BorderSide(width: 1.0,
                              color: Colors.black54),
                          right: BorderSide(width: 1.0,
                              color: Colors.black54),
                          bottom: BorderSide(width: 1.0,
                              color: Colors.black54),
                        ),
                      ),
                      child: Center(
                        child: Text("Accessories",
                          textAlign: TextAlign.start,
                          style: TextStyle(
                              fontWeight: FontWeight.bold
                          ),
                        )
                      )
                  )
                ),

                Expanded(
                  flex: 2,
                  child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 5, vertical: 5),
                      decoration: BoxDecoration(
                        color: color_bg,
                        border: Border(
                          top: BorderSide(width: 1.0,
                              color: Colors.black54),
                          right: BorderSide(width: 1.0,
                              color: Colors.black54),
                          bottom: BorderSide(width: 1.0,
                              color: Colors.black54),
                        ),
                      ),
                      child: Center(
                          child: Text("Photos",
                            textAlign: TextAlign.start,
                            style: TextStyle(
                                fontWeight: FontWeight.bold
                            ),
                          )
                      )
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 5, vertical: 5),
                      decoration: BoxDecoration(
                        color: color_bg,
                        border: Border(
                          top: BorderSide(width: 1.0,
                              color: Colors.black54),
                          right: BorderSide(width: 1.0,
                              color: Colors.black54),
                          bottom: BorderSide(width: 1.0,
                              color: Colors.black54),
                        ),
                      ),
                      child: Center(
                          child: Text("Video",
                            textAlign: TextAlign.start,
                            style: TextStyle(
                                fontWeight: FontWeight.bold
                            ),
                          )
                      )
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 5, vertical: 5),
                      decoration: BoxDecoration(
                        color: color_bg,
                        border: Border(
                          top: BorderSide(width: 1.0,
                              color: Colors.black54),
                          right: BorderSide(width: 1.0,
                              color: Colors.black54),
                          bottom: BorderSide(width: 1.0,
                              color: Colors.black54),
                        ),
                      ),
                      child: Center(
                          child: Text("Notes",
                            textAlign: TextAlign.start,
                            style: TextStyle(
                                fontWeight: FontWeight.bold
                            ),
                          )
                      )
                  ),
                )
              ],
            ),
          ),
        );



        for (var i = 0; i < _vindecoder.parts.length; i++) {
          var part = _vindecoder.parts[i];
          String trim_seris = "";
          String glass = "";
          String part_number = "";
          String count = "";
          String description = "";

          String dealerPartNum = "";
          String accessories = "";

          String notes = "";
          String video_url = "";
          String videoThumbnailUrl = "";

          if ((part.trim != null && part.trim.length > 0) &&
              (part.series != null && part.series.length > 0)) {
            trim_seris = part.trim + "/" + part.series;
          }
          else if (part.trim != null && part.trim.length > 0) {
            trim_seris = part.trim;
          }
          else if (part.series != null && part.series.length > 0) {
            trim_seris = part.series;
          }

          if (part.glass != null) {
            glass = part.glass;
          }

          if (part.part_number != null) {
            part_number = part.part_number;
          }

          if (part.count != null) {
            count = part.count;
          }

          if (part.description != null) {
            description = part.description;
          }

          if (part.dealer_part_nums != null) {
            for (var j = 0; j < part.dealer_part_nums.length; j++) {
              if (dealerPartNum == "") {
                if (part.dealer_part_nums[j] != null)
                  dealerPartNum = part.dealer_part_nums[j];
              }
              else {
                if (part.dealer_part_nums[j] != null)
                  dealerPartNum += "\n" + part.dealer_part_nums[j];
              }
            }
          }

          if (part.accessories != null) {
            for (var j = 0; j < part.accessories.length; j++) {
              if (part.accessories[j].part_number != null &&
                  part.accessories[j].type != null) {
                var tmp = part.accessories[j].part_number + "(" +
                    part.accessories[j].type + ")";
                if (accessories == "") {
                  accessories = tmp;
                }
                else {
                  accessories += "\n" + tmp;
                }
              }
            }
          }

          if ( part.notes != null ){
            for(var j=0; j<part.notes.length;j++){
              if ( notes == "" ){
                notes = part.notes[j];
              }
              else{
                notes += "\n\n" + part.notes[j];
              }
            }
          }

          List<Widget> photosWidget = new List();
          if ( part.photos != null ){
            for(var j=0;j<part.photos.length;j++){
              photosWidget.add(
                  Padding(
                      padding: EdgeInsets.only(right: 5, bottom: 5),
                      child: GestureDetector(
                        onTap: (){
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GalleryPhotoViewWrapper(
                                galleryItems: part.photos,
                                backgroundDecoration: const BoxDecoration(
                                  color: Colors.black,
                                ),
                                initialIndex: j,
                                scrollDirection: Axis.horizontal,

                              ),
                            ),
                          );
                        },
                        child: Image.network(part.photos[j].resource, width: 30,height: 30, fit: BoxFit.fill),
                      )
                  )
              );
            }
          }

          if ( part.videos != null && part.videos.length > 0 ){
            video_url = part.videos[0];
            var videoID = path.basename(video_url);
            videoThumbnailUrl = "https://img.youtube.com/vi/" + videoID.toString() + "/0.jpg";
          }

          //video_url = "https://youtu.be/WggixOP6cF0";

          partsWidgets.add(
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Expanded(
                    flex: 2,
                    child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 5, vertical: 5),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(width: 0.0,
                                color: Colors.black54),
                            left: BorderSide(width: 1.0,
                                color: Colors.black54),
                            right: BorderSide(width: 1.0,
                                color: Colors.black54),
                            bottom: BorderSide(width: 1.0,
                                color: Colors.black54),
                          ),
                        ),
                        child: Center(
                          child: Text(glass,
                            textAlign: TextAlign.start,
                          ),
                        )
                    ),
                  ),

                  Expanded(
                    flex: 2,
                    child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 5, vertical: 5),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(width: 0.0,
                                color: Colors.black54),
                            left: BorderSide(width: 0.0,
                                color: Colors.black54),
                            right: BorderSide(width: 1.0,
                                color: Colors.black54),
                            bottom: BorderSide(width: 1.0,
                                color: Colors.black54),
                          ),
                        ),
                        child: Center(
                          child: Text(part_number,
                            textAlign: TextAlign.start,
                          ),
                        )
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 5, vertical: 5),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(width: 0.0,
                                color: Colors.black54),
                            left: BorderSide(width: 0.0,
                                color: Colors.black54),
                            right: BorderSide(width: 1.0,
                                color: Colors.black54),
                            bottom: BorderSide(width: 1.0,
                                color: Colors.black54),
                          ),
                        ),
                        child: Center(
                          child: Text(count,
                            textAlign: TextAlign.start,
                          ),
                        )
                    ),
                  ),

                  Expanded(
                    flex: 3,
                    child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 5, vertical: 5),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(width: 0.0,
                                color: Colors.black54),
                            left: BorderSide(width: 0.0,
                                color: Colors.black54),
                            right: BorderSide(width: 1.0,
                                color: Colors.black54),
                            bottom: BorderSide(width: 1.0,
                                color: Colors.black54),
                          ),
                        ),
                        child: Center(
                          child: Text(description,
                            textAlign: TextAlign.start,
                          ),
                        )
                    ),
                  ),

                  Expanded(
                    flex: 2,
                    child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 5, vertical: 5),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(width: 0.0,
                                color: Colors.black54),
                            left: BorderSide(width: 0.0,
                                color: Colors.black54),
                            right: BorderSide(width: 1.0,
                                color: Colors.black54),
                            bottom: BorderSide(width: 1.0,
                                color: Colors.black54),
                          ),
                        ),
                        child: Center(
                          child: Text(dealerPartNum,
                            textAlign: TextAlign.start,
                          ),
                        )
                    ),
                  ),

                  // Accessories
                  Expanded(
                    flex: 2,
                    child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 5, vertical: 5),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(width: 0.0,
                                color: Colors.black54),
                            left: BorderSide(width: 0.0,
                                color: Colors.black54),
                            right: BorderSide(width: 1.0,
                                color: Colors.black54),
                            bottom: BorderSide(width: 1.0,
                                color: Colors.black54),
                          ),
                        ),
                        child: Center(
                          child: Text(accessories,
                            textAlign: TextAlign.start,
                          ),
                        )
                    ),
                  ),

                  // Photos
                  Expanded(
                    flex: 2,
                    child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 5, vertical: 5),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(width: 0.0,
                                color: Colors.black54),
                            left: BorderSide(width: 0.0,
                                color: Colors.black54),
                            right: BorderSide(width: 1.0,
                                color: Colors.black54),
                            bottom: BorderSide(width: 1.0,
                                color: Colors.black54),
                          ),
                        ),
                        child: Wrap(
                          children: photosWidget
                        )
                    ),
                  ),

                  // Video
                  Expanded(
                    flex: 2,
                    child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 5, vertical: 5),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(width: 0.0,
                                color: Colors.black54),
                            left: BorderSide(width: 0.0,
                                color: Colors.black54),
                            right: BorderSide(width: 1.0,
                                color: Colors.black54),
                            bottom: BorderSide(width: 1.0,
                                color: Colors.black54),
                          ),
                        ),
                        child: Center(
                          child: video_url==""?Text("---"):
                          GestureDetector(
                              onTap: (){
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => YoutubeVideoView(
                                      videoUrl: video_url,
                                    ),
                                  ),
                                );
                              },
                              child: videoThumbnailUrl!=null?Image.network(videoThumbnailUrl, width: 100, height: 50, alignment: Alignment.centerLeft)
                                  :Text(video_url, style: TextStyle(decoration: TextDecoration.underline),)
                          ) ,
                        )
                    ),
                  ),

                  // Notes
                  Expanded(
                    flex: 2,
                    child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 5, vertical: 5),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(width: 0.0,
                                color: Colors.black54),
                            left: BorderSide(width: 0.0,
                                color: Colors.black54),
                            right: BorderSide(width: 1.0,
                                color: Colors.black54),
                            bottom: BorderSide(width: 1.0,
                                color: Colors.black54),
                          ),
                        ),
                        child: Center(
                          child: Text(notes,
                            textAlign: TextAlign.start,
                          ),
                        )
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        trimsWidget.add(
            Container(
              child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Column(
                      children: partsWidgets
                  )
              )
            )
        );
      }
      else{

        List<DropdownMenuItem> partNumItems = new List();
        for(var i=0;i<_vindecoder.parts.length;i++){
          var part = _vindecoder.parts[i];
          if ( part.part_number != null ){
            var partNumber = part.part_number.trim();
            if ( _selectedPartNum == "" ){
              _selectedPartNum = partNumber;
            }

            partNumItems.add( DropdownMenuItem(child: new Text(partNumber, textAlign: TextAlign.center,), value: partNumber) );
          }
        }

        print(_selectedPartNum);
        if ( partNumItems.length > 0 ) {
          trimsWidget.add(
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: DropdownButton(
                    isDense: true,
                    isExpanded: true,
                    value: _selectedPartNum,
                    items: partNumItems,
                    onChanged: (newValue) {
                      setState(() {
                        _selectedPartNum = newValue;
                      });
                    }
                ),
              )
          );
        }



        for (var i = 0; i < _vindecoder.parts.length; i++)
        {
          var part = _vindecoder.parts[i];
          if ( part.part_number != null ){
            String partNum = part.part_number.trim();
            if ( partNum == _selectedPartNum ){
              String glass = "";
              String times_used = "";
              String description = "";
              String dealerPartNum = "";
              String accessories = "";
              String notes = "";
              String video_url = "";
              String videoThumbnailUrl = "";

              if ( part.glass != null ){
                glass = part.glass.trim();
              }

              if ( part.count != null ){
                times_used = part.count;
              }

              if ( part.description != null ){
                description = part.description;
              }

              if ( part.dealer_part_nums != null ){
                for( var j=0; j<part.dealer_part_nums.length;j++){
                  if ( dealerPartNum == "" ){
                    if ( part.dealer_part_nums[j] != null )
                      dealerPartNum = part.dealer_part_nums[j];
                  }
                  else{
                    if ( part.dealer_part_nums[j] != null )
                      dealerPartNum += "\n" + part.dealer_part_nums[j];
                  }
                }
              }

              if ( part.accessories != null ){
                for( var j=0; j<part.accessories.length;j++){
                  if ( part.accessories[j].part_number != null && part.accessories[j].type != null ) {
                    var tmp = part.accessories[j].part_number + "(" +
                        part.accessories[j].type + ")";
                    if (accessories == "") {
                      accessories = tmp;
                    }
                    else {
                      accessories += "\n" + tmp;
                    }
                  }
                }
              }

              if ( part.notes != null ){
                for(var j=0; j<part.notes.length;j++){
                  if ( notes == "" ){
                    notes = part.notes[j];
                  }
                  else{
                    notes += "\n\n" + part.notes[j];
                  }
                }
              }


              if ( part.videos != null && part.videos.length > 0 ){
                video_url = part.videos[0];
                var videoID = path.basename(video_url);
                videoThumbnailUrl = "https://img.youtube.com/vi/" + videoID.toString() + "/0.jpg";
              }

              List<Widget> photosWidget = new List();
              if ( part.photos != null ){
                for(var j=0;j<part.photos.length;j++){
                  photosWidget.add(
                    Padding(
                        padding: EdgeInsets.only(right: 5, bottom: 5),
                        child: GestureDetector(

                          onTap: (){
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => GalleryPhotoViewWrapper(
                                  galleryItems: part.photos,
                                  backgroundDecoration: const BoxDecoration(
                                    color: Colors.black,
                                  ),
                                  initialIndex: j,
                                  scrollDirection: Axis.horizontal,

                                ),
                              ),
                            );
                          },
                          child: Image.network(part.photos[j].resource, width: 30,height: 30, fit: BoxFit.fill),
                        )
                    )
                  );

                }
              }

              trimsWidget.add(
                  Container(
                      child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          child: Column(
                              children: <Widget>[
                                // Glass Type
                                IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: <Widget>[
                                      Expanded(
                                        child: Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 5, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: color_bg,
                                              border: Border(
                                                top: BorderSide(width: 1.0,
                                                    color: Colors.black54),
                                                left: BorderSide(width: 1.0,
                                                    color: Colors.black54),
                                                right: BorderSide(width: 1.0,
                                                    color: Colors.black54),
                                                bottom: BorderSide(width: 1.0,
                                                    color: Colors.black54),
                                              ),
                                            ),
                                            child: Center(
                                              child: Text('Glass Type',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold),
                                              ),
                                            )
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 5, vertical: 5),
                                            decoration: BoxDecoration(

                                              border: Border(
                                                top: BorderSide(width: 1.0,
                                                    color: Colors.black54),
                                                right: BorderSide(width: 1.0,
                                                    color: Colors.black54),
                                                bottom: BorderSide(width: 1.0,
                                                    color: Colors.black54),
                                              ),
                                            ),
                                            child: Text(glass,
                                              textAlign: TextAlign.justify,
                                            )
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                /* Times used # */
                                IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: <Widget>[
                                      Expanded(
                                        child: Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 5, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: color_bg,
                                              border: Border(
                                                left: BorderSide(width: 1.0,
                                                    color: Colors.black54),
                                                right: BorderSide(width: 1.0,
                                                    color: Colors.black54),
                                                bottom: BorderSide(width: 1.0,
                                                    color: Colors.black54),
                                              ),
                                            ),
                                            child: Center(
                                              child: Text('Times Used',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold),
                                              ),
                                            )
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 5, vertical: 5),
                                            decoration: BoxDecoration(
                                              border: Border(
                                                right: BorderSide(width: 1.0,
                                                    color: Colors.black54),
                                                bottom: BorderSide(width: 1.0,
                                                    color: Colors.black54),
                                              ),
                                            ),
                                            child: Text(times_used,
                                              textAlign: TextAlign.start,
                                            )
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Description
                                IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: <Widget>[
                                      Expanded(
                                        child: Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 5, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: color_bg,
                                              border: Border(
                                                left: BorderSide(width: 1.0,
                                                    color: Colors.black54),
                                                right: BorderSide(width: 1.0,
                                                    color: Colors.black54),
                                                bottom: BorderSide(width: 1.0,
                                                    color: Colors.black54),
                                              ),
                                            ),
                                            child: Center(
                                              child: Text('Description',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold),
                                              ),
                                            )
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 5, vertical: 5),
                                            decoration: BoxDecoration(
                                              border: Border(
                                                right: BorderSide(width: 1.0,
                                                    color: Colors.black54),
                                                bottom: BorderSide(width: 1.0,
                                                    color: Colors.black54),
                                              ),
                                            ),
                                            child: Text(description,
                                              textAlign: TextAlign.start,
                                            )
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Dealer Part #
                                IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: <Widget>[
                                      Expanded(
                                        child: Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 5, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: color_bg,
                                              border: Border(
                                                left: BorderSide(width: 1.0,
                                                    color: Colors.black54),
                                                right: BorderSide(width: 1.0,
                                                    color: Colors.black54),
                                                bottom: BorderSide(width: 1.0,
                                                    color: Colors.black54),
                                              ),
                                            ),
                                            child: Center(
                                              child: Text('Dealer Part #',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold),
                                              ),
                                            )
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Container(

                                            padding: EdgeInsets.symmetric(
                                                horizontal: 5, vertical: 5),
                                            decoration: BoxDecoration(
                                              border: Border(
                                                right: BorderSide(width: 1.0,
                                                    color: Colors.black54),
                                                bottom: BorderSide(width: 1.0,
                                                    color: Colors.black54),
                                              ),
                                            ),
                                            child: Text(dealerPartNum,
                                              textAlign: TextAlign.start,
                                            )
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Accessories
                                IntrinsicHeight(
                                  child: Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 5, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: color_bg,
                                              border: Border(
                                                left: BorderSide(width: 1.0,
                                                    color: Colors.black54),
                                                right: BorderSide(width: 1.0,
                                                    color: Colors.black54),
                                                bottom: BorderSide(width: 1.0,
                                                    color: Colors.black54),
                                              ),
                                            ),
                                            child: Center(
                                              child: Text('Accessories',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold),
                                              ),
                                            )
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 5, vertical: 5),
                                            decoration: BoxDecoration(
                                              border: Border(
                                                right: BorderSide(width: 1.0,
                                                    color: Colors.black54),
                                                bottom: BorderSide(width: 1.0,
                                                    color: Colors.black54),
                                              ),
                                            ),
                                            child: Text(accessories,
                                              textAlign: TextAlign.left,
                                            )
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Photos
                                IntrinsicHeight(
                                  child: Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 5, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: color_bg,
                                              border: Border(
                                                left: BorderSide(width: 1.0,
                                                    color: Colors.black54),
                                                right: BorderSide(width: 1.0,
                                                    color: Colors.black54),
                                                bottom: BorderSide(width: 1.0,
                                                    color: Colors.black54),
                                              ),
                                            ),
                                            child: Center(
                                              child: Text('Photos',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold),
                                              ),
                                            )
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 5, vertical: 5),
                                          decoration: BoxDecoration(
                                            border: Border(
                                              right: BorderSide(width: 1.0,
                                                  color: Colors.black54),
                                              bottom: BorderSide(width: 1.0,
                                                  color: Colors.black54),
                                            ),
                                          ),
                                          child: photosWidget.length==0?Container()
                                          :Wrap(
                                            children: photosWidget,
                                          )
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Video
                                IntrinsicHeight(
                                  child: Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 5, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: color_bg,
                                              border: Border(
                                                left: BorderSide(width: 1.0,
                                                    color: Colors.black54),
                                                right: BorderSide(width: 1.0,
                                                    color: Colors.black54),
                                                bottom: BorderSide(width: 1.0,
                                                    color: Colors.black54),
                                              ),
                                            ),
                                            child: Center(
                                              child: Text('Video',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),

                                              ),
                                            )
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 5, vertical: 5),
                                            decoration: BoxDecoration(
                                              border: Border(
                                                right: BorderSide(width: 1.0,
                                                    color: Colors.black54),
                                                bottom: BorderSide(width: 1.0,
                                                    color: Colors.black54),
                                              ),
                                            ),
                                            child:
                                              video_url==""?Text("---"):
                                              GestureDetector(

                                                onTap: (){
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) => YoutubeVideoView(
                                                        videoUrl: video_url,
                                                      ),
                                                    ),
                                                  );
                                                },
                                                child: videoThumbnailUrl!=null?Image.network(videoThumbnailUrl, width: 100, height: 50, alignment: Alignment.centerLeft,)
                                                    :Text(video_url, style: TextStyle(decoration: TextDecoration.underline),)
                                              ) ,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Notes
                                IntrinsicHeight(
                                  child: Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 5, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: color_bg,
                                              border: Border(
                                                left: BorderSide(width: 1.0,
                                                    color: Colors.black54),
                                                right: BorderSide(width: 1.0,
                                                    color: Colors.black54),
                                                bottom: BorderSide(width: 1.0,
                                                    color: Colors.black54),
                                              ),
                                            ),
                                            child: Center(
                                              child: Text('Notes',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold),
                                              ),
                                            )
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 5, vertical: 5),
                                            decoration: BoxDecoration(
                                              border: Border(
                                                right: BorderSide(width: 1.0,
                                                    color: Colors.black54),
                                                bottom: BorderSide(width: 1.0,
                                                    color: Colors.black54),
                                              ),
                                            ),
                                            child: Text(notes,
                                              textAlign: TextAlign.left,
                                            )
                                        ),
                                      ),
                                    ],
                                  ),
                                )

                              ]
                          )
                      )
                  )
              );

              break;
            }
          }




        }
      }
    }



    trimsWidget.add(
      Container(
        padding: EdgeInsets.only(left: 10, right: 10, top: 20.0, bottom: 20.0),
        child: Text(
          "Please note: Our results are carefully curated and reviewed for accuracy, but we advise that you confirm as much as possible with your customer before ordering the glass.",
          style: TextStyle(
            fontStyle: FontStyle.italic
          ),
        )
      )
    );


    if ( _vindecoder.squishvin == null && (_vindecoder.parts != null && _vindecoder.parts.length > 0 ) ){

    }
    else {
      if (_vindecoder != null &&
          (_vindecoder.error == null || _vindecoder.error == "")) {
        Container _extraJobOption = Container();

        if (_showExtraOption) {
          List<DropdownMenuItem> _jobOptionMenuItems = new List();
          for (var i = 0; i < heavyGlassOptions.length; i++) {
            _jobOptionMenuItems.add(DropdownMenuItem(child: new Text(
              heavyGlassOptions[i].text, textAlign: TextAlign.center,),
                value: heavyGlassOptions[i].id));
          }
          _extraJobOption = Container(
            padding: const EdgeInsets.only(left: 0.0, right: 0.0, bottom: 5.0),
            child: DropdownButton(
                isDense: true,
                isExpanded: true,
                value: _selectedJobOption,
                items: _jobOptionMenuItems,
                onChanged: (newValue) {
                  setState(() {
                    _selectedJobOption = newValue;
                    _otherOptionController.text = "";
                  });
                }
            ),
          );
        }


        trimsWidget.add(
            Container(
                padding: EdgeInsets.only(
                    top: 10, bottom: 0, left: 10, right: 10),
                child: Container(
                    padding: EdgeInsets.all(10),
                    color: Color(0xffdae2ed),
                    child: Column(
                      children: <Widget>[
                        Center(
                            child: Text(
                                "aggregate" == "aggregate"
                                    ?
                                "These parts have been used for AutoGlassCRM jobs on vehicles of this year, make, model, and body. The correct part may vary depending on trim or other features. If you need help narrowing it down, click the button below for assistance from Vindecoder staff!"
                                    :
                                "These parts have been verified as matching vehicles of this year, make, model, and body. The correct part may vary depending on trim or other features. If you need help narrowing it down, click the button below for assistance from Vindecoder staff!",
                                style: TextStyle(
                                )
                            )
                        ),
                        SizedBox(height: 10,),
                        _extraJobOption,
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: OutlineButton(
                                  color: Colors.white,
                                  borderSide: BorderSide(
                                      color: Color(0xFF027BFF)
                                  ),
                                  child: Padding(
                                      padding: EdgeInsets.all(5),
                                      child: Text(
                                        _isSendingHelpRequest ?
                                        "Sending..." :
                                        "Tell me the exact part number",
                                        style: TextStyle(
                                          color: Color(0xFF027BFF),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      )
                                  ),
                                  onPressed: () {
                                    sendHelpRequest();
                                  }),
                            ),
                          ],
                        ),
                      ],
                    )
                )
            )

        );
      }


      if (_isSentHelpRequest == true) {
        trimsWidget.add(
            Container(
                padding: EdgeInsets.only(left: 10.0, right: 10.0, bottom: 10.0),
                child: Center(
                    child: Text(
                        _hasHelpRequestError == true
                            ?
                        "We're sorry.  We couldn't send your request.  Please try again!"
                            :
                        "Request submitted! Once we've checked on this VIN search for you, you will be notified by push notification (if you've enabled them) or email.",
                        style: TextStyle(
                        )
                    )
                )
            )
        );
      }
    }



    trimsWidget.add(
        Container(
          padding: const EdgeInsets.only(top: 10, left: 10.0, right: 10.0, bottom: 20.0),
          child: Row(
            children: <Widget>[
              MaterialButton(
                  color: Color(0xFF027BFF),
                  child: Padding(
                      padding: EdgeInsets.all(5),
                      child: Text(
                        "New Search",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                  ),
                  onPressed: () {
                    _dataLoaded = false;
                    _isLoading = false;

                    clickedReset();
                  }
              ),

              Container(
                padding: const EdgeInsets.only(left: 10.0),
                child: MaterialButton(
                    color: Color(0xFF027BFF),
                    child: Padding(
                        padding: EdgeInsets.all(5),
                        child: Text(
                          "Search History",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                    ),
                    onPressed: () {
                      Global.homePageState.onSelectItem2(4);
                    }
                ),
              )


            ],
          ),
        )
    );
    return trimsWidget;
  }


  @override
  Widget build(BuildContext context) {
    FutureBuilder fbBody = new FutureBuilder<bool>(
        builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {


          if (_dataLoaded && !_hasError) {
            List<Widget> widgets = new List();
            List<Widget> trimsWidget = _buildTrims();

            widgets.add(
              Container(
                  padding: EdgeInsets.only(top:10, bottom: 0, left:10, right:10),
                  child:Center(
                      child:Text(topAlertText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontWeight: FontWeight.normal,
                            color: Colors.red
                        ),
                      )
                  )
              ),
            );

            if ( _vindecoder.squishvin == null && (_vindecoder.parts != null && _vindecoder.parts.length > 0 ) ){

            }else {
              widgets.add(
                Container(
                    padding: EdgeInsets.only(
                        top: 10, bottom: 0, left: 10, right: 10),
                    child: Center(
                        child: Text("Vehicle Data for " + _searchKey,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontWeight: FontWeight.bold
                          ),
                        )
                    )
                ),
              );

              if (Device
                  .get()
                  .isTablet) {
                List<Widget> headerWidget = new List();
                headerWidget.add(
                    IntrinsicHeight(
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              Expanded(
                                flex: 2,
                                child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: color_bg,
                                      border: Border(
                                        top: BorderSide(width: 1.0,
                                            color: Colors.black54),
                                        left: BorderSide(width: 1.0,
                                            color: Colors.black54),
                                        right: BorderSide(width: 1.0,
                                            color: Colors.black54),
                                        bottom: BorderSide(width: 1.0,
                                            color: Colors.black54),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text('Year',
                                        textAlign: TextAlign.start,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    )
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: color_bg,
                                      border: Border(
                                        top: BorderSide(width: 1.0,
                                            color: Colors.black54),
                                        left: BorderSide(width: 1.0,
                                            color: Colors.black54),
                                        right: BorderSide(width: 1.0,
                                            color: Colors.black54),
                                        bottom: BorderSide(width: 1.0,
                                            color: Colors.black54),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text('Make',
                                        textAlign: TextAlign.start,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    )
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: color_bg,
                                      border: Border(
                                        top: BorderSide(width: 1.0,
                                            color: Colors.black54),
                                        left: BorderSide(width: 1.0,
                                            color: Colors.black54),
                                        right: BorderSide(width: 1.0,
                                            color: Colors.black54),
                                        bottom: BorderSide(width: 1.0,
                                            color: Colors.black54),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text('Model',
                                        textAlign: TextAlign.start,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    )
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: color_bg,
                                      border: Border(
                                        top: BorderSide(width: 1.0,
                                            color: Colors.black54),
                                        left: BorderSide(width: 1.0,
                                            color: Colors.black54),
                                        right: BorderSide(width: 1.0,
                                            color: Colors.black54),
                                        bottom: BorderSide(width: 1.0,
                                            color: Colors.black54),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text('Body',
                                        textAlign: TextAlign.start,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    )
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: color_bg,
                                      border: Border(
                                        top: BorderSide(width: 1.0,
                                            color: Colors.black54),
                                        left: BorderSide(width: 1.0,
                                            color: Colors.black54),
                                        right: BorderSide(width: 1.0,
                                            color: Colors.black54),
                                        bottom: BorderSide(width: 1.0,
                                            color: Colors.black54),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text('Trim',
                                        textAlign: TextAlign.start,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    )
                                ),
                              ),
                            ]
                        )
                    )
                );

                headerWidget.add(
                    IntrinsicHeight(
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              Expanded(
                                flex: 2,
                                child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 5),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        top: BorderSide(width: 0.0,
                                            color: Colors.black54),
                                        left: BorderSide(width: 1.0,
                                            color: Colors.black54),
                                        right: BorderSide(width: 1.0,
                                            color: Colors.black54),
                                        bottom: BorderSide(width: 1.0,
                                            color: Colors.black54),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        _vindecoder.year != null ? _vindecoder
                                            .year : "",
                                        textAlign: TextAlign.start,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    )
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 5),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        top: BorderSide(width: 0.0,
                                            color: Colors.black54),
                                        left: BorderSide(width: 1.0,
                                            color: Colors.black54),
                                        right: BorderSide(width: 1.0,
                                            color: Colors.black54),
                                        bottom: BorderSide(width: 1.0,
                                            color: Colors.black54),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        _vindecoder.make != null ? _vindecoder
                                            .make : "",
                                        textAlign: TextAlign.start,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    )
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 5),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        top: BorderSide(width: 0.0,
                                            color: Colors.black54),
                                        left: BorderSide(width: 1.0,
                                            color: Colors.black54),
                                        right: BorderSide(width: 1.0,
                                            color: Colors.black54),
                                        bottom: BorderSide(width: 1.0,
                                            color: Colors.black54),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        _vindecoder.model != null ? _vindecoder
                                            .model : "",
                                        textAlign: TextAlign.start,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    )
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 5),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        top: BorderSide(width: 0.0,
                                            color: Colors.black54),
                                        left: BorderSide(width: 1.0,
                                            color: Colors.black54),
                                        right: BorderSide(width: 1.0,
                                            color: Colors.black54),
                                        bottom: BorderSide(width: 1.0,
                                            color: Colors.black54),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        _vindecoder.body != null ? _vindecoder
                                            .body : "",
                                        textAlign: TextAlign.start,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    )
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 5),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        top: BorderSide(width: 0.0,
                                            color: Colors.black54),
                                        left: BorderSide(width: 1.0,
                                            color: Colors.black54),
                                        right: BorderSide(width: 1.0,
                                            color: Colors.black54),
                                        bottom: BorderSide(width: 1.0,
                                            color: Colors.black54),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text('',
                                        textAlign: TextAlign.start,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    )
                                ),
                              ),
                            ]
                        )
                    )
                );

                widgets.add(
                    Container(
                        child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 10, vertical: 10),
                            child: Column(
                                children: headerWidget
                            )
                        )
                    )
                );
              }
              else {
                widgets.add(
                    Container(
                        child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 10, vertical: 10),
                            child: Column(
                                children: <Widget>[
                                  // Year
                                  IntrinsicHeight(
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment
                                          .stretch,
                                      children: <Widget>[
                                        Expanded(
                                          flex: 1,
                                          child: Container(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 5, vertical: 5),
                                              decoration: BoxDecoration(
                                                color: color_bg,
                                                border: Border(
                                                  top: BorderSide(width: 1.0,
                                                      color: Colors.black54),
                                                  left: BorderSide(width: 1.0,
                                                      color: Colors.black54),
                                                  right: BorderSide(width: 1.0,
                                                      color: Colors.black54),
                                                  bottom: BorderSide(width: 0.0,
                                                      color: Colors.black54),
                                                ),
                                              ),
                                              child: Text('Year',
                                                textAlign: TextAlign.start,
                                                style: TextStyle(
                                                    fontWeight: FontWeight
                                                        .bold),

                                              )
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Container(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 5, vertical: 5),
                                              decoration: BoxDecoration(
                                                border: Border(
                                                  top: BorderSide(width: 1.0,
                                                      color: Colors.black54),
                                                  right: BorderSide(width: 1.0,
                                                      color: Colors.black54),
                                                  bottom: BorderSide(width: 0.0,
                                                      color: Colors.black54),
                                                ),
                                              ),
                                              child: Text(
                                                _vindecoder.year != null
                                                    ? _vindecoder.year
                                                    : "",
                                                textAlign: TextAlign.start,
                                              )
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),


                                  // Make
                                  IntrinsicHeight(
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment
                                          .stretch,
                                      children: <Widget>[
                                        Expanded(
                                          child: Container(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 5, vertical: 5),
                                              decoration: BoxDecoration(
                                                color: color_bg,
                                                border: Border(
                                                  top: BorderSide(width: 0.0,
                                                      color: Colors.black54),
                                                  left: BorderSide(width: 1.0,
                                                      color: Colors.black54),
                                                  right: BorderSide(width: 1.0,
                                                      color: Colors.black54),
                                                  bottom: BorderSide(width: 0.0,
                                                      color: Colors.black54),
                                                ),
                                              ),
                                              child: Text('Make',
                                                textAlign: TextAlign.start,
                                                style: TextStyle(
                                                    fontWeight: FontWeight
                                                        .bold),

                                              )
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Container(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 5, vertical: 5),
                                              decoration: BoxDecoration(
                                                border: Border(
                                                  top: BorderSide(width: 0.0,
                                                      color: Colors.black54),
                                                  right: BorderSide(width: 1.0,
                                                      color: Colors.black54),
                                                  bottom: BorderSide(width: 0.0,
                                                      color: Colors.black54),
                                                ),
                                              ),
                                              child: Text(
                                                _vindecoder.make != null
                                                    ? _vindecoder.make
                                                    : "",
                                                textAlign: TextAlign.start,
                                              )
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),


                                  //Model
                                  IntrinsicHeight(
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment
                                          .stretch,
                                      children: <Widget>[
                                        Expanded(
                                          child: Container(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 5, vertical: 5),
                                              decoration: BoxDecoration(
                                                color: color_bg,
                                                border: Border(
                                                  top: BorderSide(width: 0.0,
                                                      color: Colors.black54),
                                                  left: BorderSide(width: 1.0,
                                                      color: Colors.black54),
                                                  right: BorderSide(width: 1.0,
                                                      color: Colors.black54),
                                                  bottom: BorderSide(width: 0.0,
                                                      color: Colors.black54),
                                                ),
                                              ),
                                              child: Text('Model',
                                                textAlign: TextAlign.start,
                                                style: TextStyle(
                                                    fontWeight: FontWeight
                                                        .bold),

                                              )
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Container(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 5, vertical: 5),
                                              decoration: BoxDecoration(
                                                border: Border(
                                                  top: BorderSide(width: 0.0,
                                                      color: Colors.black54),
                                                  right: BorderSide(width: 1.0,
                                                      color: Colors.black54),
                                                  bottom: BorderSide(width: 0.0,
                                                      color: Colors.black54),
                                                ),
                                              ),
                                              child: Text(
                                                _vindecoder.model != null
                                                    ? _vindecoder.model
                                                    : "",
                                                textAlign: TextAlign.start,
                                              )
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),


                                  // body
                                  IntrinsicHeight(
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment
                                          .stretch,
                                      children: <Widget>[
                                        Expanded(
                                          child: Container(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 5, vertical: 5),
                                              decoration: BoxDecoration(
                                                color: color_bg,
                                                border: Border(
                                                  top: BorderSide(width: 0.0,
                                                      color: Colors.black54),
                                                  left: BorderSide(width: 1.0,
                                                      color: Colors.black54),
                                                  right: BorderSide(width: 1.0,
                                                      color: Colors.black54),
                                                  bottom: BorderSide(width: 0.0,
                                                      color: Colors.black54),
                                                ),
                                              ),
                                              child: Text('Body',
                                                textAlign: TextAlign.start,
                                                style: TextStyle(
                                                    fontWeight: FontWeight
                                                        .bold),

                                              )
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Container(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 5, vertical: 5),
                                              decoration: BoxDecoration(
                                                border: Border(
                                                  top: BorderSide(width: 0.0,
                                                      color: Colors.black54),
                                                  right: BorderSide(width: 1.0,
                                                      color: Colors.black54),
                                                  bottom: BorderSide(width: 0.0,
                                                      color: Colors.black54),
                                                ),
                                              ),
                                              child: Text(
                                                _vindecoder.body != null
                                                    ? _vindecoder.body
                                                    : "",
                                                textAlign: TextAlign.start,
                                              )
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),


                                  // Trim
                                  IntrinsicHeight(
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment
                                          .stretch,
                                      children: <Widget>[
                                        Expanded(
                                          child: Container(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 5, vertical: 5),
                                              decoration: BoxDecoration(
                                                color: color_bg,
                                                border: Border(
                                                  top: BorderSide(width: 0.0,
                                                      color: Colors.black54),
                                                  left: BorderSide(width: 1.0,
                                                      color: Colors.black54),
                                                  right: BorderSide(width: 1.0,
                                                      color: Colors.black54),
                                                  bottom: BorderSide(width: 1.0,
                                                      color: Colors.black54),
                                                ),
                                              ),
                                              child: Text('Trim',
                                                textAlign: TextAlign.start,
                                                style: TextStyle(
                                                    fontWeight: FontWeight
                                                        .bold),

                                              )
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Container(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 5, vertical: 5),
                                              decoration: BoxDecoration(
                                                border: Border(
                                                  top: BorderSide(width: 0.0,
                                                      color: Colors.black54),
                                                  right: BorderSide(width: 1.0,
                                                      color: Colors.black54),
                                                  bottom: BorderSide(width: 1.0,
                                                      color: Colors.black54),
                                                ),
                                              ),
                                              child: Text(
                                                "",
                                                textAlign: TextAlign.start,
                                              )
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),


                                ]
                            )
                        )
                    )
                );
              }
            }

            widgets.add(
              Container(
                  padding: EdgeInsets.only(top:10, bottom: 0, left:10, right:10),
                  child:Center(
                      child:Text( "Matching Parts Records",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontWeight: FontWeight.bold
                        ),
                      )
                  )
              ),
            );

            widgets.add(
              Column(
                  children: trimsWidget
              ),
            );

            return ListView(
                children: widgets
            );
          } else if ( _isLoading ){
            return ListView(children: [
              Container(
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildBodySkeleton(0.7),
                    _buildDivider(),
                    _buildBodySkeleton(0.65),
                    _buildDivider(),
                    _buildBodySkeleton(0.60),
                    _buildDivider(),
                    _buildBodySkeleton(0.55),
                    _buildDivider(),
                    _buildBodySkeleton(0.50),
                    _buildDivider(),
                    _buildBodySkeleton(0.45),
                    _buildDivider(),
                    _buildBodySkeleton(0.40),
                  ],
                ),
              ),
            ]);
          }
          else if ( _dataLoaded == false && _isLoading == false ){
            List<Widget> widgets = new List();

            if ( _hasError ){
              widgets.add(
                Container(
                  padding: EdgeInsets.only(top: 10, bottom: 0, left: 10, right: 10),
                  child: Container(
                    padding: EdgeInsets.only(top: 10, bottom: 10, left: 10, right: 10),
                    color: Color(0xfffff3cd),
                    child: Text(
                      _errorMsg,
                      style: TextStyle(
                        fontSize: 12
                      ),
                    )
                  )
                )
              );
            }



            ////// Box1 ///////////////
            List<Widget> widgetsBox1 = List();

            widgetsBox1.add(
                Container(
                    padding: EdgeInsets.only(left: 10.0, right: 10.0, top: 10.0),
                    child: MaterialButton(
                        height: 40,
                        onPressed: (){
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (BuildContext context) =>
                                  DetectionTextPage(1)
                          ));
                        },
                        color: Color(0xFF027BFF),
                        child: Text("Take Video",
                          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                        )
                    )
                )
            );

            widgetsBox1.add(
                Container(
                    padding: EdgeInsets.only(left: 10.0, right: 10.0, top: 10.0),
                    child: MaterialButton(
                        height: 40,
                        onPressed: (){
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (BuildContext context) =>
                                  DetectionTextPage(0)
                          ));
                        },
                        color: Color(0xFF027BFF),
                        child: Text("Choose Video", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                        )
                    )
                )
            );



            widgets.add(
                Container(
                    margin: EdgeInsets.only(top: 10, bottom: 10, left: 10, right: 10),
                    padding: EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                        border: Border.all(
                            color: Colors.black
                        )
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: widgetsBox1,
                    )
                )
            );
            //////////// Box1 End //////////////



            /// Box2 //////
            List<Widget> widgetsBox2 = List();
            widgetsBox2.add(
              Container(
                  padding: EdgeInsets.only(top: 10, bottom: 0, left: 10, right: 10),
                  child: Text(
                      "VIN, Dealer or Aftermarket Part Number:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      )
                  )
              ),
            );

            widgetsBox2.add(
              Container(
                padding: EdgeInsets.only(top: 10, bottom: 0, left: 10, right: 10),
                child: TextField(
                  autocorrect: false,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                  ),
                  keyboardType: TextInputType.text,
                  controller: _vinNumController,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.only(
                        left: 4.0, bottom: 3.0, top: 3.0, right: 4.0),
                    border: OutlineInputBorder(
                        borderRadius: const BorderRadius.all(
                            const Radius.circular(0.0)
                        ),
                        borderSide: BorderSide(
                            color: Colors.black54, width: 1.0)
                    ),
                    hintText: 'Search',
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                  onSubmitted: (newValue) {
                  },
                ),
              ),
            );

            widgetsBox2.add(
              Container(
                  padding: EdgeInsets.only(top: 10, bottom: 0, left: 10, right: 10),
                  child: Text(
                      "Glass Type:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      )
                  )
              ),
            );

            List<DropdownMenuItem> _jobTypeMenuItems = new List();
            for(var i=0;i<jobTypeItems.length;i++){
              _jobTypeMenuItems.add(DropdownMenuItem(child: new Text(jobTypeItems[i].text, textAlign: TextAlign.center,), value: jobTypeItems[i].id) );
            }

            widgetsBox2.add(
                SizedBox(height: 20.0)
            );

            widgetsBox2.add(
              Container(
                padding: const EdgeInsets.only(left: 10.0, right: 10.0),
                child:DropdownButton(
                    isDense: true,
                    isExpanded: true,
                    value: _selectedJobType,
                    items: _jobTypeMenuItems,
                    onChanged: (newValue){
                      setState(() {
                        _selectedJobType = newValue;
                        _selectedJobOption = "1";
                        _otherOptionController.text = "";
                      });
                    }
                ),
              ),
            );

            List<DropdownMenuItem> _jobOptionMenuItems = new List();
            if ( _selectedJobType == "1" || _selectedJobType == "2" || _selectedJobType == "23" || _selectedJobType == "3" || _selectedJobType == "22") {
              if ( _selectedJobType == "1" ){
                for(var i=0;i<backGlassOptions.length;i++){
                  _jobOptionMenuItems.add(DropdownMenuItem(child: new Text(backGlassOptions[i].text, textAlign: TextAlign.center,), value: backGlassOptions[i].id) );
                }
              }
              if ( _selectedJobType == "2" ){
                for(var i=0;i<doorGlassOptions.length;i++){
                  _jobOptionMenuItems.add(DropdownMenuItem(child: new Text(doorGlassOptions[i].text, textAlign: TextAlign.center,), value: doorGlassOptions[i].id) );
                }
              }

              if ( _selectedJobType == "23" ){
                for(var i=0;i<heavyGlassOptions.length;i++){
                  _jobOptionMenuItems.add(DropdownMenuItem(child: new Text(heavyGlassOptions[i].text, textAlign: TextAlign.center,), value: heavyGlassOptions[i].id) );
                }
              }

              if ( _selectedJobType == "3" ){
                for(var i=0;i<quarterGlassOptions.length;i++){
                  _jobOptionMenuItems.add(DropdownMenuItem(child: new Text(quarterGlassOptions[i].text, textAlign: TextAlign.center,), value: quarterGlassOptions[i].id) );
                }
              }

              if ( _selectedJobType == "22" ){
                for(var i=0;i<ventGlassOptions.length;i++){
                  _jobOptionMenuItems.add(DropdownMenuItem(child: new Text(ventGlassOptions[i].text, textAlign: TextAlign.center,), value: ventGlassOptions[i].id) );
                }
              }

              widgetsBox2.add(
                  SizedBox(height: 20.0)
              );

              widgetsBox2.add(
                Container(
                  padding: const EdgeInsets.only(left: 10.0, right: 10.0),
                  child:DropdownButton(
                      isDense: true,
                      isExpanded: true,
                      value: _selectedJobOption,
                      items: _jobOptionMenuItems,
                      onChanged: (newValue){
                        setState(() {
                          _selectedJobOption = newValue;
                          _otherOptionController.text = "";
                        });
                      }
                  ),
                ),
              );

              if ( _selectedJobType == "2" && _selectedJobOption == "5" || _selectedJobType == "3" && _selectedJobOption == "3" ){
                widgetsBox2.add(
                    SizedBox(height: 20.0)
                );

                widgetsBox2.add(
                    Container(
                      padding: const EdgeInsets.only(left: 10.0, right: 10.0),
                      child: TextField(
                        autocorrect: false,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                        ),
                        keyboardType: TextInputType.text,
                        controller: _otherOptionController,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.only(
                              left: 4.0, bottom: 3.0, top: 3.0, right: 4.0),
                          hintText: 'Other Option',
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                );
              }
            }


            widgetsBox2.add(
                Container(
                  padding: const EdgeInsets.only(top: 10, left: 10.0, right: 10.0),
                  child: Row(
                    children: <Widget>[
                      MaterialButton(
                          color: Color(0xFF027BFF),
                          child: Padding(
                              padding: EdgeInsets.all(5),
                              child: Text(
                                "Search VinDecoder",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                          ),
                          onPressed: () {
                            clickedSearch();
                          }
                      ),

                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.only(left: 10.0),
                          child: MaterialButton(
                              color: Color(0xFF027BFF),
                              child: Padding(
                                  padding: EdgeInsets.all(5),
                                  child: Text(
                                    "Reset",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )
                              ),
                              onPressed: () {
                                clickedReset();
                              }
                          ),
                        )
                      )


                    ],
                  ),
                )
            );

            widgets.add(
              Container(
                margin: EdgeInsets.only(top: 10, bottom: 10, left: 10, right: 10),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.black
                  )
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: widgetsBox2,
                )
              )
            );

            //// Box2 END----/////








            return ListView(
              children: widgets
            );

          }
          else{
            return Center(
                child: Text("")
            );
          }
        });

    return SafeArea(
      child: fbBody,
    );
  }
}

