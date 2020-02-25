import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:auto_glass_crm/code/global.dart';
import 'package:auto_glass_crm/classes/gallery_item.dart';
import 'package:auto_glass_crm/views/gallery_photo_view_wrapper.dart';
import 'package:auto_glass_crm/services/upload_service.dart';
import 'package:auto_glass_crm/models/part_note.dart';


import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:html_unescape/html_unescape.dart';

import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:path/path.dart' as path;

class SearchView extends StatefulWidget {
  _SearchViewState state;
  @override
  _SearchViewState createState() {
    state = new _SearchViewState();
    return state;
  }
}

class _SearchViewState extends State<SearchView> with AutomaticKeepAliveClientMixin{
  BuildContext _scaffoldContext;
  var unescape = new HtmlUnescape();
  final scaffoldKey = new GlobalKey<ScaffoldState>();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = new GlobalKey<RefreshIndicatorState>();

  bool _dataLoaded = false;
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMsg = "";


  List<GalleryItem> galleryItems = new List<GalleryItem>();
  String _partNum = "";
  TextEditingController _partNumController = new TextEditingController(text:"");

  bool _isPlayerReady = false;
  YoutubePlayerController _youtubePlayerController = null;
  String _description = "";
  String _glasstype = "";
  String _dealer_part_nums = "";
  String _accessories = "";
  List<PartNote> noteItems = new List<PartNote>();

  ScrollController _scrollController;
  Color color_bg = Color(0xFFCCCCCC);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }


  /* Get Data */
  loadData() async {
    if ( _isLoading == true ){
      return;
    }


    if ( _partNumController.text.trim().length == 0 ){
      final snackBar = SnackBar(
        content: Text("Please type part number."),
      );
      Scaffold.of(_scaffoldContext).showSnackBar(snackBar);
      return;
    }

    _isLoading = true;
    _dataLoaded = false;
    _hasError = false;
    setState(() {});

    _errorMsg = "Error has occurred.";
    galleryItems.clear();
    noteItems.clear();
    _youtubePlayerController = null;

    _description = "";
    _glasstype = "";
    _dealer_part_nums = "";
    _accessories = "";

    _partNum = _partNumController.text.trim();
    var response = await UploadService.getPartData( _partNum );
    if ( response != null ){
      try{
        var json_response = json.decode(response);
        if ( json_response.containsKey("success") && json_response["success"] == 0 ){
          _hasError = true;
          _errorMsg = json_response["message"];
        }
        else{
          _glasstype = json_response["glass"];
          _description = json_response["description"];

          for(var i=0;i<json_response["dealer_part_nums"].length;i++){
            if ( _dealer_part_nums == "" ){
              _dealer_part_nums = json_response["dealer_part_nums"][i];
            }
            else{
              _dealer_part_nums += ", " + json_response["dealer_part_nums"][i];
            }
          }

          for(var i=0;i<json_response["accessories"].length;i++){
            var tmp = "";
            if ( json_response["accessories"][i]["part_number"] != null && json_response["accessories"][i]["type"] != null ){
              var tmp_type = json_response["accessories"][i]["type"].toString().replaceAll("_", " ");
              tmp = json_response["accessories"][i]["part_number"] + "/" + tmp_type;
            }

            if ( _accessories == "" ){
              _accessories = tmp;
            }
            else{
              _accessories += "\n" + tmp;
            }
          }

          for(var i=0;i<json_response["photos"].length;i++){
            var photo = json_response["photos"][i];
            galleryItems.add(GalleryItem(
                id: photo["id"], isVideo: false, resource: Global.amazon_prefix + "/" +  photo["url"]
            ));
          }

          for(var i=0;i<json_response["notes"].length;i++){
            PartNote note = PartNote.fromJson(json_response["notes"][i]);
            noteItems.add(note);
          }


          if ( json_response["videos"].length > 0 ) {
            var video_url = json_response["videos"][0]["url"];
            var video_id = path.basename(video_url);
            _youtubePlayerController = YoutubePlayerController(
              initialVideoId: video_id,
              flags: YoutubePlayerFlags(
                autoPlay: false,
                mute: true,
              ),
            );
          }
        }

      }catch (e) {
        _hasError = true;
        print("load data error=" + e.toString());
      }
    }

    _isLoading = false;
    _dataLoaded = true;
    if ( this.mounted ) {
      setState(() {});
    }
  }

  openPhoto(index){
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GalleryPhotoViewWrapper(
          galleryItems: galleryItems,
          backgroundDecoration: const BoxDecoration(
            color: Colors.black,
          ),
          initialIndex: index,
          scrollDirection: Axis.horizontal,

        ),
      ),
    );
  }

  _resetScreen(){
    galleryItems.clear();
    noteItems.clear();
    _youtubePlayerController = null;

    _description = "";
    _glasstype = "";
    _dealer_part_nums = "";
    _accessories = "";
    _partNum = "";
    _partNumController.text = "";

    setState(() {
    });
  }

  /*
  openVideo(){
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoViewWrapper(
          backgroundDecoration: const BoxDecoration(
            color: Colors.black,
          ),
          videoPath: _videoPath,
        ),
      ),
    );
  }
  */

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

  _buildWidget(BuildContext context) {
    const Color bgColor = Color(0xFFCCCCCC);
    const Color boxBorderColor = Colors.black54;
    double headerFontSize = 14.0;
    double bodyFontSize = 11.0;

    Widget widget;
    List<Widget> widgets = new List();
    double screenWidth = MediaQuery.of(context).size.width;
    double imageWidth = (screenWidth - 30 )/3;

    widgets.add(
        Container(
            padding: EdgeInsets.only(left: 5, top: 20, right: 5, bottom: 5),
            child: TextField(
              controller: _partNumController,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                  contentPadding: const EdgeInsets.only(left: 4.0, bottom: 7.0, top: 7.0, right: 4.0),
                  border: OutlineInputBorder(
                      borderRadius: const BorderRadius.all(
                          const Radius.circular(0.0)
                      ),
                      borderSide: const BorderSide(color: boxBorderColor, width: 1.0)
                  ),
                  hintText: 'Part Number',
                  hintStyle: TextStyle(color: Colors.grey),
                  suffixIcon: IconButton(icon: Icon(Icons.search), onPressed: (){
                    loadData();
                  })
              ),
              onSubmitted: (newValue){
                loadData();
              },
            )
        )
    );



    if ( _isLoading ){
      widgets.add(
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
      );

      widget = Column(
          children: widgets
      );
      return widget;
    }
    else if ( _dataLoaded && _hasError  ){
      widgets.add(
        Container(
          padding: EdgeInsets.only(left: 10, right: 10, top: 20),
          child:
            Center(
              child: Text(
                _errorMsg,
                style: TextStyle(
                  fontSize: 14,
                ),
              ),
            )
        )
      );

      widget = Column(
          children: widgets
      );
      return widget;
    }
    else if ( _dataLoaded == false && _isLoading == false ){
    }
    else if (_dataLoaded && !_hasError) {
    }
    else{
      widget = Column(
          children: widgets
      );
      return widget;
    }


    // glass type
    widgets.add(
        Container(
          padding: EdgeInsets.only(left: 5.0, top: 10.0),
          child: Text("Glass Type:",
            style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold
            ),
          ),
          alignment: Alignment.bottomLeft,
        )
    );

    widgets.add(
        Container(
          padding: EdgeInsets.only(left: 5.0, top: 5.0),
          child: Text( _glasstype,
            style: TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
                color: Colors.grey
            ),
          ),
          alignment: Alignment.bottomLeft,
        )
    );

    // description
    widgets.add(
        Container(
          padding: EdgeInsets.only(left: 5.0, top: 10.0),
          child: Text("Description:",
            style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold
            ),
          ),
          alignment: Alignment.bottomLeft,
        )
    );

    widgets.add(
        Container(
          padding: EdgeInsets.only(left: 5.0, top: 5.0),
          child: Text( _description,
            style: TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
                color: Colors.grey
            ),
          ),
          alignment: Alignment.bottomLeft,
        )
    );

    // dealer part num
    widgets.add(
        Container(
          padding: EdgeInsets.only(left: 5.0, top: 10.0),
          child: Text("Dealer Part #:",
            style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold
            ),
          ),
          alignment: Alignment.bottomLeft,
        )
    );

    widgets.add(
        Container(
          padding: EdgeInsets.only(left: 5.0, top: 5.0),
          child: Text( _dealer_part_nums,
            style: TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
                color: Colors.grey
            ),
          ),
          alignment: Alignment.bottomLeft,
        )
    );

    // accessories
    widgets.add(
        Container(
          padding: EdgeInsets.only(left: 5.0, top: 10.0),
          child: Text("Accessories:",
            style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold
            ),
          ),
          alignment: Alignment.bottomLeft,
        )
    );

    widgets.add(
        Container(
          padding: EdgeInsets.only(left: 5.0, top: 5.0),
          child: Text( _accessories,
            style: TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
                color: Colors.grey
            ),
          ),
          alignment: Alignment.bottomLeft,
        )
    );


    widgets.add(
      Container(
        padding: EdgeInsets.only(left: 5.0, top: 10.0),
        child: Text("Photos:",
          style: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.bold
          ),
        ),
        alignment: Alignment.bottomLeft,
      )
    );



    List<Widget> photoWidgets = new List<Widget>();
    for(var i=0;i<galleryItems.length;i++){
      photoWidgets.add(
        GalleryItemThumbnail(
          galleryItem: galleryItems[i],
          width: imageWidth,
          onTap: () {
            openPhoto(i);
          },
        )
      );
    }

    widgets.add(
      Container(
        child: Wrap(
          children: photoWidgets
        )
      )
    );


    widgets.add(
        Container(
          padding: EdgeInsets.only(left: 5.0, top: 10.0),
          child: Text("Video:",
            style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold
            ),
          ),
          alignment: Alignment.bottomLeft,
        )
    );

    widgets.add(
      Container(
        padding: EdgeInsets.only(left: 5.0, right: 5.0, top: 5.0, bottom: 10),
        child: Stack(
          children: <Widget>[
            _youtubePlayerController != null ?
            YoutubePlayer(
              controller: _youtubePlayerController,
              showVideoProgressIndicator: true,
              liveUIColor: Colors.amber,
              onReady: (){
                _isPlayerReady = true;
              },
            )
            : Container(),
          ]
        )
      )
    );


    // Notes
    widgets.add(
        Container(
          padding: EdgeInsets.only(left: 5.0, top: 10.0),
          child: Text("Notes:",
            style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold
            ),
          ),
          alignment: Alignment.bottomLeft,
        )
    );

    List<Widget> noteWidget = new List();

    noteWidget.add(
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
                          child: Text( "Last update",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontWeight: FontWeight.bold),
                          ),
                        )
                    ),
                  ),
                  Expanded(
                    flex: 6,
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
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontWeight: FontWeight.bold
                            ),
                          ),
                        )
                    ),
                  ),
                ]
            )
        )
    );

    for(var i=0;i<noteItems.length;i++){
      var noteItem = noteItems[i];

      var last_update = noteItem.last_update;
      try {
        DateTime tmp = DateTime.parse(noteItem.last_update);
        if ( tmp != null ){
          last_update = tmp.month.toString() + "/" + tmp.day.toString() + "/" + tmp.year.toString();
        }
      }catch(e){
        print("Parse Date Time error=" + e.toString());
      }

      noteWidget.add(
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
                      child: Text( last_update,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontWeight: FontWeight.bold),
                      ),
                    )
                ),
              ),
              Expanded(
                flex: 6,
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
                    child: Center(
                      child: Text(noteItem.text,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontWeight: FontWeight.bold
                        ),
                      ),
                    )
                ),
              ),
            ]
          )
        )
      );
    }
    widgets.add(
      Container(
        padding: EdgeInsets.only(left: 5.0, right: 5.0, bottom: 10.0),
        child: Column(
          children: noteWidget,
        )
      )
    );

    widgets.add(
      Container(
        padding: EdgeInsets.only(bottom: 20.0),
        child: Center(
          child: MaterialButton(
              onPressed: (){
                _resetScreen();
                _scrollController.jumpTo(0);
              },
              color: Color(0xFF027BFF),
              child: Padding(
                  padding: EdgeInsets.only(left: 15,right: 15, top: 0, bottom: 0),
                  child: Text(
                    "Clear",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  )
              ),
          )
        )
      )
    );

    widget = Column(
        children: widgets
    );

    return widget;
  }

  @override
  void dispose() {
    super.dispose();

  }

  @override
  Widget build(BuildContext context) {
    print(_partNum);
    _partNumController.text = _partNum;

    FutureBuilder fbBody = new FutureBuilder<bool>(
        builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
          _scaffoldContext = context;

          Widget widgets = _buildWidget(context);

          return ListView(
              controller: _scrollController,
              children: <Widget>[
                widgets
              ]
          );
        });

    return Scaffold(
        key: scaffoldKey,
        body: fbBody
    );
  }
}
