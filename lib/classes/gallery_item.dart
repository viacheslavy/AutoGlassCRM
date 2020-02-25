import 'package:flutter/widgets.dart';

class GalleryItem {
  GalleryItem({this.id, this.resource, this.isVideo = false});

  final String id;
  final String resource;
  final bool isVideo;
}

class GalleryItemThumbnail extends StatelessWidget {
  const GalleryItemThumbnail(
      {Key key, this.galleryItem, this.width, this.onTap})
      : super(key: key);

  final GalleryItem galleryItem;
  final double width;
  final GestureTapCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5.0),
      child: GestureDetector(
        onTap: onTap,
        child: Hero(
          tag: galleryItem.id,
          child: Image.network(galleryItem.resource, width: width),
        ),
      ),
    );
  }
}