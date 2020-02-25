import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:path/path.dart' as path;

class YoutubeVideoView extends StatefulWidget {
  YoutubeVideoView({
    @required this.videoUrl,
  });

  final String videoUrl;

  @override
  State<StatefulWidget> createState() {
    return _YoutubeVideoViewState();
  }
}

class _YoutubeVideoViewState extends State<YoutubeVideoView>{

  YoutubePlayerController _youtubePlayerController = null;

  @override
  void initState() {
    super.initState();

    var videoID = path.basename(widget.videoUrl);
    _youtubePlayerController = YoutubePlayerController(
      initialVideoId: videoID,
      flags: YoutubePlayerFlags(
        autoPlay: false,
        mute: true,
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.black,
        constraints: BoxConstraints.expand(
          height: MediaQuery.of(context).size.height,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            _youtubePlayerController != null ?
            YoutubePlayer(
              controller: _youtubePlayerController,
              showVideoProgressIndicator: true,
              liveUIColor: Colors.amber,
              onReady: (){
              },
            )
            : Container()
            ,
            Container(
              alignment: Alignment.topLeft,
              margin: EdgeInsets.only(top: 20, left: 0),
              child: new IconButton(
                  icon: new Icon(Icons.arrow_back),
                  color: Colors.white,
                  onPressed: () => Navigator.of(context).pop(),
              ),

            )
          ],
        ),
      ),
    );
  }
}