import 'dart:async';

import 'package:dio/dio.dart';
import 'package:auto_glass_crm/code/global.dart';
import 'package:auto_glass_crm/services/vindecoder_service.dart';
import 'package:auto_glass_crm/models/vindecoder_history.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:string_mask/string_mask.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:intl/intl.dart';

class HistoryView extends StatefulWidget {
  _HistoryViewState state;
  String answerId = "";

  @override
  _HistoryViewState createState() {
    state = new _HistoryViewState();
    return state;
  }
}

class _HistoryViewState extends State<HistoryView> {
  var unescape = new HtmlUnescape();
  final scaffoldKey = new GlobalKey<ScaffoldState>();

  bool _dataLoaded = false;
  bool  _isLoading = false;
  bool _hasError = false;
  String _searchKey = "";

  bool _isSendingHelpRequest = false;
  bool _isAnswerDlgShow = false;

  VindecoderHistory searchData;

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
  new GlobalKey<RefreshIndicatorState>();

  int curPageNum = 1;
  int pageSize = 5;
  bool _isLoadingMore = false;
  bool _needLoadMore = true;


  @override
  void initState() {
    super.initState();
    loadData("");
    /*
    if ( widget.answerId != "" ){
      new Timer(const Duration(milliseconds: 300), () {
        showAnswer(widget.answerId);
      });
    }
    */
  }

  /* Get History */
  loadData(s) async {
    if ( _isLoading == true ){
      return;
    }

    _searchKey = s;
    _isLoading = true;
    _dataLoaded = false;
    setState(() {});

    curPageNum = 1;
    _needLoadMore = false;

    var response = await VindecoderService.getVindecoderHistory(s, curPageNum, pageSize);
    if ( response != null ){
      if ( response is Map<String, dynamic> && response.containsKey("success") && response["success"] == 0 ){
        Global.checkResponse(context, response['message']);
      }
      else{
        searchData = VindecoderHistory.fromJson(response);
      }
    }

    _isLoading = false;
    if ( searchData != null ) {
      if ( searchData.history.length > 0 ) {
        _needLoadMore = true;
      }

      _searchKey = s;
      _hasError = false;
    }
    else{
      _hasError = true;
    }

    _dataLoaded = true;
    if ( this.mounted ) {
      setState(() {});
    }

    if ( widget.answerId != "" ){
      showAnswer(widget.answerId);
      widget.answerId = "";
    }
  }

  bool isGettingAnswer = false;


  sendHelpRequestAgain(VindecoderAnswer _answerDetail, Text _requestButton) async{
    if ( _isSendingHelpRequest ){
      return;
    }

    _isSendingHelpRequest = true;
    setState(() {});

    if ( _isAnswerDlgShow ) {
      _isAnswerDlgShow = false;
      Navigator.of(context).pop(ConfirmAction.CANCEL);
    }


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
    Map<String, dynamic> ret = await VindecoderService.checkAnswer(_answerDetail.id);
    Scaffold.of(context).hideCurrentSnackBar();

    if ( ret != null && ret.containsKey("success") && ret["success"] == 1){
      showAnswer(_answerDetail.id);
    }
    else{
      var err = "Please try again.";
      if ( ret != null && ret.containsKey("message")){
        err = ret["message"];
      }
      final snackBar = SnackBar(
        content: Text(err),
      );
      Scaffold.of(context).showSnackBar(snackBar);
    }
    _isSendingHelpRequest = false;
    setState(() {});
  }

  showAnswer(_id) async{
    if ( isGettingAnswer ){
      return;
    }


    Color color_bg = Color(0xFFCCCCCC);
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
      Container statusContainer = Container();
      if ( ret.errorTime != null && ret.errorUser != null ){
        statusContainer = Container(
            padding: EdgeInsets.only(top: 5, bottom: 0, left: 0, right: 0),
            child: Container(
                padding: EdgeInsets.only(top: 5, left: 5, right: 5, bottom: 5),
                color: Color(0xFFFF5964),
                child: Column(
                    children: <Widget>[
                      Center(
                          child: Text(
                              "This answer was marked wrong and resubmitted at " + ret.errorTime + " by " + ret.errorUser + ". It is currently being reviewed.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10.0,
                                color: Colors.white
                              )
                          )
                      ),
                    ]
                )
            )
        );
      }
      else{
        Text requestButton = Text(
          _isSendingHelpRequest ?
          "Sending..." :
          "Tell me the exact part number again",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF027BFF),
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        );

        statusContainer = Container(
            padding: EdgeInsets.only(top: 10, bottom: 0, left: 0, right: 0),
            child: Container(
                padding: EdgeInsets.all(10),
                color: Color(0xffdae2ed),
                child: Column(
                  children: <Widget>[
                    Center(
                        child: Text(
                            "Want us to double-check our answer? If you are not 100 percent comfortable with the response you received, let us review it for you. Click the button below to have us double-check our response.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 10.0
                            )
                        )
                    ),
                    SizedBox(height: 10,),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: OutlineButton(
                              color: Colors.white,
                              borderSide: BorderSide(
                                  color: Color(0xFF027BFF)
                              ),
                              child: Padding(
                                  padding: EdgeInsets.only(top: 0, bottom: 0),
                                  child: requestButton
                              ),
                              onPressed: () {
                                sendHelpRequestAgain(ret, requestButton);
                              }),
                        ),
                      ],
                    ),
                  ],
                )
            )
        );
      }

      var height = MediaQuery.of(context).size.height;
      var width = MediaQuery.of(context).size.width;

      showDialog<ConfirmAction>(
        context: context,
        barrierDismissible: false, // user must tap button for close dialog!
        builder: (BuildContext context) {
          Container mContainer = new Container(
              child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
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

                        statusContainer
                      ]
                  )
              )
          );

          _isAnswerDlgShow = true;

          return StatefulBuilder(
            builder: (context, setState){
              return WillPopScope(
                  onWillPop: () async => false,
                  child: AlertDialog(
                    contentPadding: EdgeInsets.all(5.0),
                    title: Text('Answer Detail'),
                    content: SingleChildScrollView(
                        child: mContainer
                    ),
                    actions: <Widget>[
                      FlatButton(
                        child: const Text('OK'),
                        onPressed: () {
                          _isAnswerDlgShow = false;
                          Navigator.of(context).pop(ConfirmAction.CANCEL);
                        },
                      )
                    ],
                  )
              );
            }
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

  loadDataMore() async {
    if (_isLoadingMore == true) {
      return;
    }

    _isLoadingMore = true;
    setState(() {});

    VindecoderHistory result;
    var response = await VindecoderService.getVindecoderHistory(_searchKey, curPageNum + 1, pageSize);
    if ( response != null ){
      if ( response is Map<String, dynamic> && response.containsKey("success") && response["success"] == 0 ){
        Global.checkResponse(context, response['message']);
      }
      else{
        result = VindecoderHistory.fromJson(response);
      }
    }

    if ( result != null && result.history != null ){
      if (searchData == null) {
        searchData = new VindecoderHistory();
        searchData.history = List<VindecoderHistoryData>();
      }

      if ( result.history.length > 0 ) {
        curPageNum++;
        for (var i = 0; i < result.history.length; i++) {
          var item = result.history[i];
          searchData.history.add(item);
        }
      }
      else{
        _needLoadMore = false;
      }
    }
    _isLoadingMore = false;
    setState(() {});
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

  _buildDivider() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: Divider(
        color: Colors.grey,
      ),
    );
  }

  _buildWidget() {
    Color bgColor = Color(0xFFCCCCCC);
    Color boxBorderColor = Colors.black54;
    double headerFontSize = 12.0;
    double bodyFontSize = 11.0;

    Widget widget;
    List<Widget> widgets = new List();

    // header
    widgets.add(
      Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(width: 1.0, color: boxBorderColor),
              left: BorderSide(width: 1.0, color: boxBorderColor),
              right: BorderSide(width: 1.0, color: boxBorderColor),
              bottom: BorderSide(width: 1.0, color: boxBorderColor),
            ),
          ),
          margin: const EdgeInsets.only(top:10.0, bottom: 0.0, left:5.0, right: 5.0),
          child: IntrinsicHeight(
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Expanded(
                      flex: 7,
                      child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(width: 1.0, color: boxBorderColor),
                            ),
                          ),
                          child: Center(
                              child: Text('VIN',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: headerFontSize),
                              )
                          )
                      ),
                    ),

                    Expanded(
                        flex: 8,
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(width: 1.0, color: boxBorderColor),
                            ),
                          ),
                          child: Center(
                              child: Text('User',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: headerFontSize),
                              )
                          ),
                        )
                    ),

                    Expanded(
                        flex: 8,
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(width: 1.0, color: boxBorderColor),
                            ),
                          ),
                          child: Center(
                              child: Text('When Run',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: headerFontSize),
                              )
                          ),
                        )
                    ),

                    Expanded(
                        flex: 8,
                        child: Container(
                            child: Center(
                              child: Text('Verified Part Number',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: headerFontSize),
                              ),
                            )
                        )
                    ),
                  ]
              )
          )
      ),
    );

    // body
    if ( searchData != null ) {
      for (var i = 0; i < searchData.history.length; i++) {
        VindecoderHistoryData item = searchData.history[i];
        widgets.add(
          Container(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(width: 1.0, color: boxBorderColor),
                  right: BorderSide(width: 1.0, color: boxBorderColor),
                  bottom: BorderSide(width: 1.0, color: boxBorderColor),
                ),
              ),
              margin: const EdgeInsets.only(
                  top: 0.0, bottom: 0.0, left: 5.0, right: 5.0),
              child: IntrinsicHeight(
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Expanded(
                            flex: 7,
                            child: Container(
                                decoration: BoxDecoration(
                                  border: Border(
                                    right: BorderSide(
                                        width: 1.0, color: boxBorderColor),
                                  ),
                                ),
                                child: Padding(
                                    padding: EdgeInsets.only(
                                        top: 2.0, bottom: 2.0),
                                    child: Center(
                                        child: Text(item.vin,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              fontSize: bodyFontSize),
                                        )
                                    )
                                )
                            )
                        ),

                        Expanded(
                            flex: 8,
                            child: Container(
                                decoration: BoxDecoration(
                                  border: Border(
                                    right: BorderSide(
                                        width: 1.0, color: boxBorderColor),
                                  ),
                                ),
                                child: Center(
                                  child: Text(item.user==null?"":item.user,
                                      style: TextStyle(fontSize: bodyFontSize)),
                                )
                            )
                        ),

                        Expanded(
                            flex: 8,
                            child: Container(
                                decoration: BoxDecoration(
                                  border: Border(
                                    right: BorderSide(
                                        width: 1.0, color: boxBorderColor),
                                  ),
                                ),
                                child: Center(
                                  child: Text(item.whenrun,
                                      style: TextStyle(fontSize: bodyFontSize)),
                                )
                            )
                        ),

                        Expanded(
                            flex: 8,
                            child: Container(
                                child: Center(
                                  child: item.partnumber==null?Text("---"):
                                      GestureDetector(
                                        onTap: () {
                                          showAnswer(item.id);
                                        },
                                        child: Text(
                                            item.partnumber==""?"See note":item.partnumber, textAlign: TextAlign.center,
                                            style: TextStyle(fontSize: bodyFontSize, decoration: TextDecoration.underline)),
                                        ),

                                      )

                            )
                        ),
                      ]
                  )
              )
          ),
        );
      }
    }


    widget = Column(
        children: widgets
    );

    return widget;
  }

  @override
  Widget build(BuildContext context) {
    FutureBuilder fbBody = new FutureBuilder<bool>(
        builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
          if (_dataLoaded && !_hasError) {
            Widget historyWidget = _buildWidget();

            return ListView(
                children: <Widget>[
                  historyWidget,
                  SizedBox(height: 20),

                  _needLoadMore?
                  _isLoadingMore?
                  Padding(
                      padding: EdgeInsets.only(left:10),
                      child:Center(
                        child: Text(
                          "Loading...",
                          style: TextStyle(
                              color: Color(0xFFD2670B),
                              fontSize: Global.fontSizeSmall
                          ),
                        )
                      )
                  ):
                  GestureDetector(
                    child:Padding(
                        padding: EdgeInsets.only(left:10),
                        child:Center(
                          child: Text(
                            "Load more",
                            style: TextStyle(
                                color: Color(0xFFD2670B),
                                fontSize: Global.fontSizeSmall,
                                decoration: TextDecoration.underline
                            ),
                          )
                        )
                    ),
                    onTap:(){
                      setState(() {
                        loadDataMore();
                      });
                    },
                  )
                  :
                  Container()
                ]
            );
          } else if (_dataLoaded && _hasError) {
            return Center(
              child: Text(
                "Error has occurred.",
                style: TextStyle(
                  fontSize: 20,
                ),
              ),
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
            return Center(
              child: Text(
                "Please search for VIN in history",
                style: TextStyle(
                  fontSize: 20,
                ),
              ),
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
