import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:auto_glass_crm/code/global.dart';
import 'package:auto_glass_crm/services/upload_service.dart';

import 'package:flutter/material.dart';
import 'package:flutter_native_image/flutter_native_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class UploadView extends StatefulWidget {
  _UploadViewState state;
  @override
  _UploadViewState createState() {
    state = new _UploadViewState();
    return state;
  }
}

class PhotoData {
  List<int> photoBytes = new List<int>();
}

class _UploadViewState extends State<UploadView> with AutomaticKeepAliveClientMixin{
  BuildContext _scaffoldContext;
  final scaffoldKey = new GlobalKey<ScaffoldState>();


  TextEditingController _partNumController = new TextEditingController(text:"");
  TextEditingController _noteController = new TextEditingController(text:"");
  List<PhotoData> mPhotoData = new List<PhotoData>();
  File videoFile;
  var thumbnailFilePath;
  bool _isUploading = false;

  String videoUploadStatus = "";
  String photoUploadStatus = "";
  String noteUploadStatus = "";

  FocusNode nodeOne = FocusNode();
  FocusNode focusNodeNote = FocusNode();

  @override
  bool get wantKeepAlive => true;


  @override
  void initState() {
    super.initState();
  }

  Future<File> getImage(bool fromCamera) async {
    var image = await ImagePicker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery);
    return image;
  }

  Future<File> getVideo(bool fromCamera) async {
    File video = await ImagePicker.pickVideo(source: fromCamera ? ImageSource.camera: ImageSource.gallery);
    return video;
  }

  // Choose photo function
  choosePhoto() {
    if ( _isUploading ){
      return;
    }

    // show picker options
    showModalBottomSheet<void>(
        context: _scaffoldContext,
        builder: (BuildContext context) {
          return Container(
            color: Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                InkWell(
                  child: ListTile(
                    leading: Icon(Icons.camera_alt),
                    title: Text('TAKE PHOTO'),
                    onTap: () async {
                      getImage(true).then((image) async {
                        Navigator.of(context).pop();

                        ImageProperties properties = await FlutterNativeImage.getImageProperties(image.path);

                        int width = properties.width;
                        int height = properties.height;

                        if ( properties.width > properties.height ){
                          if ( properties.width > 800 ){
                            width = 800;
                            height = width * properties.height ~/ properties.width;
                          }
                        }
                        else{
                          if ( properties.height > 800 ){
                            height = 800;
                            width = height * properties.width ~/ properties.height;
                          }
                        }

                        File compressedFile =
                        await FlutterNativeImage.compressImage(image.path, quality: 70, targetWidth: width, targetHeight: height);

                        PhotoData _photo = new PhotoData();
                        _photo.photoBytes = compressedFile.readAsBytesSync();
                        mPhotoData.add(_photo);

                        setState(() {
                        });
                      });
                    },
                  ),
                ),
                InkWell(
                  child: ListTile(
                    leading: Icon(Icons.photo_album),
                    title: Text('CHOOSE EXISTING'),
                    onTap: () {
                      getImage(false).then((image) async {
                        Navigator.of(context).pop();

                        if ( image != null ) {
                          ImageProperties properties = await FlutterNativeImage.getImageProperties(image.path);

                          int width = properties.width;
                          int height = properties.height;

                          if ( properties.width > properties.height ){
                            if ( properties.width > 800 ){
                              width = 800;
                              height = width * properties.height ~/ properties.width;
                            }
                          }
                          else{
                            if ( properties.height > 800 ){
                              height = 800;
                              width = height * properties.width ~/ properties.height;
                            }
                          }

                          File compressedFile =
                          await FlutterNativeImage.compressImage(image.path, quality: 70, targetWidth: width, targetHeight: height);

                          PhotoData _photo = new PhotoData();
                          _photo.photoBytes = compressedFile.readAsBytesSync();
                          mPhotoData.add(_photo);

                          setState(() {
                          });
                        }
                      });
                    },
                  ),
                ),
                InkWell(
                  child: ListTile(
                    leading: Icon(Icons.cancel),
                    title: Text('CANCEL'),
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          );
        });
  }

  // Remove photo function
  removePhoto(nIndex){
    if ( _isUploading ){
      return;
    }

    if ( mPhotoData.length > nIndex && nIndex >= 0 ){
      mPhotoData[nIndex].photoBytes = List<int>();
      mPhotoData.removeAt(nIndex);
    }

    setState(() {
    });
  }

  // Choose Video
  chooseVideo(){
    if ( _isUploading ){
      return;
    }

    // show picker options
    showModalBottomSheet<void>(
        context: _scaffoldContext,
        builder: (BuildContext context) {
          return Container(
            color: Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                InkWell(
                  child: ListTile(
                    leading: Icon(Icons.camera_alt),
                    title: Text('TAKE VIDEO'),
                    onTap: () async {
                      getVideo(true).then((video) async {
                        Navigator.of(context).pop();

                        videoFile = video;

                        print(videoFile.path);
                        thumbnailFilePath = await VideoThumbnail.thumbnailFile(
                          video: videoFile.path,
                          thumbnailPath: (await getTemporaryDirectory()).path,
                          imageFormat: ImageFormat.PNG,
                          maxHeight: 300,
                          quality: 75,
                        );
                        print(thumbnailFilePath);
                        if ( thumbnailFilePath == null )
                          videoFile = null;

                        setState(() {});
                      });
                    },
                  ),
                ),
                InkWell(
                  child: ListTile(
                    leading: Icon(Icons.photo_album),
                    title: Text('CHOOSE EXISTING'),
                    onTap: () {
                      getVideo(false).then((video) async {
                        Navigator.of(context).pop();
                        videoFile = video;
                        print(videoFile.path);

                        print(videoFile.path);
                        thumbnailFilePath = await VideoThumbnail.thumbnailFile(
                          video: videoFile.path,
                          thumbnailPath: (await getTemporaryDirectory()).path,
                          imageFormat: ImageFormat.PNG,
                          maxHeight: 300,
                          quality: 75,
                        );
                        print(thumbnailFilePath);
                        if ( thumbnailFilePath == null )
                          videoFile = null;

                        setState(() {});
                      });
                    },
                  ),
                ),
                InkWell(
                  child: ListTile(
                    leading: Icon(Icons.cancel),
                    title: Text('CANCEL'),
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          );
        });
  }

  // Remove Video
  removeVideo(){
    if ( _isUploading ){
      return;
    }
    videoFile = null;
    setState(() {
    });
  }

  resetScreen(){
    noteUploadStatus  = "";
    photoUploadStatus = "";
    videoUploadStatus = "";

    mPhotoData.clear();
    _noteController.text = "";
    videoFile = null;
    thumbnailFilePath = null;

    _partNumController.text = "";
  }

  _buildWidget() {
    print("buildwidget");


    const Color bgColor = Color(0xFFCCCCCC);
    const Color boxBorderColor = Colors.black54;
    double headerFontSize = 14.0;
    double bodyFontSize = 11.0;
    double screenWidth = MediaQuery.of(_scaffoldContext).size.width;
    double imageWidth = (screenWidth - 30 )/3;

    Widget widget;
    List<Widget> widgets = new List();

    // PartNum Field
    widgets.add(
        Container(
            padding: EdgeInsets.only(left: 5.0, right: 5.0, top: 20.0),
            alignment: Alignment.topLeft,
            child: Text('Part Number:')
        )
    );
    widgets.add(
        Container(
            padding: EdgeInsets.only(left: 5, top: 5, right: 5, bottom: 5),
            child: TextField(
              controller: _partNumController,
              keyboardType: TextInputType.text,
              maxLines: 1,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.only(left: 5.0, bottom: 0.0, top: 0.0, right: 5.0),
                border: OutlineInputBorder(
                    borderRadius: const BorderRadius.all(
                        const Radius.circular(0.0)
                    ),
                    borderSide: const BorderSide(color: boxBorderColor, width: 1.0)
                ),
                hintText: 'Part Number',
                hintStyle: TextStyle(color: Colors.grey),
              ),

            )
        )
    );
    widgets.add(
        Container(
            padding: EdgeInsets.only(left: 5.0, right: 5.0, top: 0.0),
            alignment: Alignment.topLeft,
            child: Text('Example part number: DW02040', style: TextStyle(fontSize: 12.0, color: Colors.grey))
        )
    );

    widgets.add(
        Container(
            padding: EdgeInsets.only(left: 5.0, right: 5.0, top: 20.0),
            alignment: Alignment.topLeft,
            child: Wrap(
              children: <Widget>[
                MaterialButton(
                    color: Color(0xFF027BFF),
                    height: 30,
                    child: Padding(
                      padding: EdgeInsets.only(top: 0, bottom: 0, left: 10, right: 10),
                      child: Text("Choose Photo", style: TextStyle(color: Colors.white),),
                    ),
                    onPressed: () {
                      if ( mPhotoData.length < 4 ) {
                        choosePhoto();
                      }
                    }
                )
              ],
            )
        )
    );

    widgets.add(
        Container(
            padding: EdgeInsets.only(left: 5.0, right: 5.0, top: 0.0),
            alignment: Alignment.topLeft,
            child: Text('Add photos that clearly show features on the windshield.', style: TextStyle(fontSize: 12.0, color: Colors.grey))
        )
    );

    List<Widget> photoWidgets = new List();
    for(var i=0;i<mPhotoData.length;i++){
      photoWidgets.add(
          Container(
              padding: EdgeInsets.only(left: 5.0, right: 5.0, top: 5.0),
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  Image.memory(mPhotoData[i].photoBytes, fit: BoxFit.contain, width: imageWidth,),
                  GestureDetector(
                      onTap: (){
                        removePhoto(i);
                      },
                      child: Stack(
                        children: <Widget>[
                          Icon(Icons.remove_circle, color: Colors.red, size: 30),
                          Icon(Icons.remove_circle_outline, color: Colors.black, size: 30)
                        ],
                      )
                  )

                ],
              )

          )
      );
    }

    widgets.add(
        Container(
            alignment: Alignment.topLeft,
            padding: EdgeInsets.only(top: 5.0),
            child: Wrap(
              children: photoWidgets,
            )
        )
    );


    widgets.add(
        Container(
            padding: EdgeInsets.only(left: 5.0, right: 5.0, top: 20.0),
            alignment: Alignment.topLeft,
            child: Wrap(

              children: <Widget>[
                MaterialButton(
                    color: Color(0xFF027BFF),
                    height: 30,
                    child: Padding(
                      padding: EdgeInsets.only(top: 0, bottom: 0, left: 10, right: 10),
                      child: Text("Choose Video", style: TextStyle(color: Colors.white),),
                    ),
                    onPressed: () {
                      if ( videoFile == null ) {
                        chooseVideo();
                      }
                    }
                )
              ],
            )
        )

    );

    widgets.add(
        Container(
            padding: EdgeInsets.only(left: 5.0, right: 5.0, top: 0.0),
            alignment: Alignment.topLeft,
            child: Text('Video should be less than 30 seconds and in landscape only.', style: TextStyle(fontSize: 12.0, color: Colors.grey))
        )
    );



    widgets.add(
        Container(
            padding: EdgeInsets.only(left: 5.0, right: 5.0, top: 10.0),
            child:
            Stack(
              alignment: Alignment.center,
              children: <Widget>[
                videoFile != null && thumbnailFilePath != null ?
                Image.file(File(thumbnailFilePath))
                    :
                Container(),

                videoFile != null && thumbnailFilePath != null?
                GestureDetector(
                    onTap: (){
                      removeVideo();
                    },
                    child: Stack(
                      children: <Widget>[
                        Icon(Icons.remove_circle, color: Colors.red, size: 30),
                        Icon(Icons.remove_circle_outline, color: Colors.black, size: 30)
                      ],
                    )
                )
                    :
                Container()
              ],
            )

        )
    );

    // Note Field
    widgets.add(
        Container(
            padding: EdgeInsets.only(left: 5.0, right: 5.0, top: 20.0),
            alignment: Alignment.topLeft,
            child: Text("Install instruction / notes:")
        )
    );
    widgets.add(
        Container(
            padding: EdgeInsets.only(left: 5, top: 5, right: 5, bottom: 5),
            child: TextField(
              controller: _noteController,
              keyboardType: TextInputType.text,
              maxLines: 5,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.only(left: 5.0, bottom: 5.0, top: 5.0, right: 5.0),
                border: OutlineInputBorder(
                    borderRadius: const BorderRadius.all(
                        const Radius.circular(0.0)
                    ),
                    borderSide: const BorderSide(color: boxBorderColor, width: 1.0)
                ),
                hintText: '',
                hintStyle: TextStyle(color: Colors.grey),
              ),
              focusNode: focusNodeNote,

            )
        )
    );



    // UploadButton
    widgets.add(
        Container(
            margin: EdgeInsets.only(top: 10.0, bottom: 20.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                RaisedButton(
                  onPressed: (){
                    resetScreen();
                  },
                  child: Text("Clear"),
                ),
                SizedBox(width: 10),
                RaisedButton(
                  onPressed: (){
                    upload();
                  },
                  child: _isUploading?Text("Uploading..."):Text("Upload"),
                ),

              ],
            )
        )
    );




    widget = Column(
        children: widgets
    );

    return widget;
  }

  upload() async{
    if ( _isUploading ){
      return;
    }

    String partNum = _partNumController.text.trim();
    if ( partNum.length == 0 ){
      final snackBar = SnackBar(
        content: Text("Please type part number."),
      );
      Scaffold.of(_scaffoldContext).showSnackBar(snackBar);
      return;
    }

    final regexPartNum = RegExp(r'^[A-Za-z]{2}[0-9]{4,5}$');
    if ( regexPartNum.hasMatch(partNum) == false ){
      final snackBar = SnackBar(
        content: Text("Please enter the full aftermarket part number, like DW02040"),
      );
      Scaffold.of(_scaffoldContext).showSnackBar(snackBar);
      return;
    }



    if ( videoFile == null && mPhotoData.length == 0 ) {
      final snackBar = SnackBar(
        content: Text("Please select photos or video."),
      );
      Scaffold.of(_scaffoldContext).showSnackBar(snackBar);
      return;
    }

    _isUploading = true;

    noteUploadStatus  = "";
    photoUploadStatus = "";
    videoUploadStatus = "";

    Global.asyncAlertDialogUploading(_scaffoldContext, "Upload in Progress", "You will get a notification once your upload has been finished");
    setState(() {
    });


    int photoUploadedNum = 0;
    int videoUploadedNum = 0;
    int noteUploadedNum = 0;
    for(var i=0;i<mPhotoData.length;i++) {
      var ret = await UploadService.uploadPhoto(
          mPhotoData[i].photoBytes, partNum,
          "image_" + i.toString() + ".jpg");
      if ( ret == "upload_success"){
        photoUploadedNum++;
      }
    }

    if ( mPhotoData.length > 0 ){
      photoUploadStatus = photoUploadedNum.toString() + "/" + mPhotoData.length.toString() + " photos uploaded.";
    }

    if ( videoFile != null ) {
      String videoRet = "";
      print(videoFile.path);
      videoRet = await UploadService.uploadVideo(videoFile, partNum);

      if ( videoRet == "upload_success") {
        videoUploadedNum = 1;
        videoUploadStatus = "Video file uploaded.";
      }
      else{
        videoUploadStatus = "Video file upload failed.";
      }
    }

    if ( _noteController.text.trim().length > 0 ){
      String noteRet = await UploadService.uploadNote(_noteController.text.trim(), partNum);
      if ( noteRet == "upload_success"){
        noteUploadedNum = 1;
        noteUploadStatus = "Note uploaded.";
      }
      else{
        noteUploadStatus = "Note upload failed.";
      }
    }

    if ( (photoUploadedNum + videoUploadedNum + noteUploadedNum) > 0 ){
      UploadService.endMetaUpload(partNum, videoUploadedNum.toString(), photoUploadedNum.toString(), noteUploadedNum.toString());
    }

    String reportStatus = "";
    if ( photoUploadStatus.length > 0 ){
      reportStatus = photoUploadStatus;
    }

    if ( videoUploadStatus.length > 0 ){
      if ( reportStatus == "" ){
        reportStatus = videoUploadStatus;
      }
      else{
        reportStatus += "\n" + videoUploadStatus;
      }
    }

    if ( noteUploadStatus.length > 0 ){
      if ( reportStatus == "" ){
        reportStatus = noteUploadStatus;
      }
      else{
        reportStatus += "\n" + noteUploadStatus;
      }
    }



    _isUploading = false;

    if ( this.mounted ) {
      resetScreen();
      setState(() {});
    }

    Global.asyncAlertDialog(Global.homePageState.context, "Upload Confirmation", reportStatus);

    if ( Global.homePageState.appLifeCycle != AppLifecycleState.resumed ) {
      Global.homePageState.showNotification(
          "AutoGlassCRM", "Upload completed.", "upload");
    }
  }



  @override
  Widget build(BuildContext context) {
    FutureBuilder fbBody = new FutureBuilder<bool>(
        builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
          _scaffoldContext = context;
          Widget widgets = _buildWidget();

          return ListView(
              children: <Widget>[
                widgets
              ]
          );

        }
    );

    return Scaffold(
        key: scaffoldKey,
        body: fbBody
    );
  }
}
