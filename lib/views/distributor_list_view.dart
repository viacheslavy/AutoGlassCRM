import 'dart:async';
import 'dart:convert' show utf8;
import 'package:html_unescape/html_unescape.dart';

import 'package:auto_glass_crm/code/global.dart';
import 'package:auto_glass_crm/models/distributor_list_item.dart';
import 'package:auto_glass_crm/services/distributor_service.dart';
import 'package:auto_glass_crm/views/distributor_detail_view.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:string_mask/string_mask.dart';

import 'package:intl/intl.dart';

class DistributorListView extends StatefulWidget {
  _DistributorListViewState state;
  @override
  _DistributorListViewState createState() {
    state = new _DistributorListViewState();
    return state;
  }
}

class _DistributorListViewState extends State<DistributorListView> {
  final scaffoldKey = new GlobalKey<ScaffoldState>();
  String searchKey = "";
  bool _dataLoaded = false;
  bool _dataLoading = false;
  bool _dataLoadingMore = false;

  List<DistributorListItem> _distributors = new List<DistributorListItem>();
  var unescape = new HtmlUnescape();

  int currentPageNum = 1;
  int defaultPageSize = 15;
  bool bLoadMore = true;

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      new GlobalKey<RefreshIndicatorState>();


  @override
  void initState() {
    super.initState();

    loadData(false);
  }

  /* Get Distributor List */
  Future<List<DistributorListItem>> loadData(bool _loadMore) async {
    if ( _loadMore ){
      currentPageNum++;
      _dataLoadingMore = true;
    }else {
      currentPageNum = 1;
      _distributors.clear();
      _dataLoaded = false;
      _dataLoading = true;
    }

    if ( this.mounted ) {
      setState(() {});
    }

    var response = await DistributorService.getDistributorList(currentPageNum.toString(), defaultPageSize.toString(), searchKey);
    if ( response != null ){
      if ( response is List<dynamic>){
        var _distributorsResult = List<DistributorListItem>();
        response.forEach((o) {
          var item = DistributorListItem.fromJson(o);
          _distributorsResult.add(item);
        });

        _distributors.addAll(_distributorsResult);
        if (_distributorsResult.length == defaultPageSize) {
          bLoadMore = true;
        }
        else {
          bLoadMore = false;
        }
      }
      else if ( response.containsKey("success") && response['success'] == 0 ) {
        Global.checkResponse(context, response['message']);
        bLoadMore = false;
      }
    }else {
      bLoadMore = false;
    }

    if ( _loadMore ) {
      _dataLoadingMore = false;
    }
    else {
      _dataLoaded = true;
      _dataLoading = false;
    }

    if ( this.mounted ) {
      setState(() {});
    }
    return _distributors;
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

  Future<Null> _handleRefresh() async {
    final Completer<Null> completer = new Completer<Null>();

    await loadData(false);

    if (true) {
      completer.complete(null);
    }

    return completer.future.then((_) {
      SnackBar(
          content: const Text('Refresh complete'),
          action: new SnackBarAction(
              label: 'RETRY',
              onPressed: () {
                _refreshIndicatorKey.currentState.show();
              }));
    });
  }

  void showCreateDistributorPage(String id) async {
    final ret = await Navigator.of(context).push(MaterialPageRoute(
        builder: (BuildContext context) =>
            DistributorDetailView(distributorId: id, pageMode: 0 )));

    if ( ret == 1 ){
      loadData(false);
    }
  }

  List<Widget> _buildDistributors(BuildContext context) {
    var headerColor = Color(0xFFD2670B);
    var formatter = new StringMask("(###) ###-####");
    var items = new List<Widget>();


    _distributors.forEach((distributor) {
      items.add(GestureDetector(
        onTap: () {
          showCreateDistributorPage(distributor.id);
        },
        child: Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Container(
            color: Color(0xFFFFFFFF),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        flex: 1,
                        child: Text(
                          //"John Doe",
                          unescape.convert(distributor.name),
                          style: TextStyle(
                            fontSize: Global.fontSizeSmall,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      /*
                      new Flexible(
                        flex: 3,
                        child: new Container(
                          padding: new EdgeInsets.only(right: 0.0),
                          child: new Text(
                              distributor.email,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                              )
                          ),
                        ),
                      ),
                      */

                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 10),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        flex: 6,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              //"3025 W Christoffersen Pkwy Apt H302 Durlock CA 95382",
                              unescape.convert(distributor.location),
                              overflow: TextOverflow.clip,
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: Global.fontSizeTiny,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        //"8168358121",
                        formatter.apply(distributor.phone),
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: Global.fontSizeTiny,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ));
    });

    if ( bLoadMore ){
      if ( _dataLoadingMore ){
        items.add(
          Container(
            margin: const EdgeInsets.only(
            top: 20.0, left: 20, right: 20, bottom: 0),
            child: MaterialButton(
                color: Color(0xFF027BFF),
                child:SizedBox(
                  height: 25.0,
                  width: 25.0,
                  child: new CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEFEFEF)),
                    value: null,
                    strokeWidth: 7.0,
                  ),
                )
            )
          )
        );
      }else {
        items.add(
            Container(
                margin: const EdgeInsets.only(
                    top: 20.0, left: 20, right: 20, bottom: 0),
                child: MaterialButton(
                    color: Color(0xFF027BFF),
                    child: Center(
                        child: Text(
                          "Load More ...",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                    ),
                    onPressed: () {
                      loadData(true);
                    }
                )
            )
        );
      }
   }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    FutureBuilder fbBody = new FutureBuilder<bool>(
        builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
      if ( _dataLoading ){
        return ListView(children: [
          Container(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildBodySkeleton(0.7),
                _buildBodySkeleton(0.65),
                _buildBodySkeleton(0.60),
                _buildBodySkeleton(0.55),
                _buildBodySkeleton(0.50),
                _buildBodySkeleton(0.45),
                _buildBodySkeleton(0.40),
              ],
            ),
          ),
        ]);
      }
      else if (_dataLoaded || _dataLoadingMore) {
        var distributorList = _buildDistributors(context);

        if (distributorList.length > 0) {
          return ListView(
            children: distributorList,
          );
        } else {
          return Center(
            child: ListView(
              padding: const EdgeInsets.all(20.0),
              children: [
                Center(
                  child: Text(
                    "No Distributors are assigned.",
                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      } else {
        return Center(
          child: ListView(
            padding: const EdgeInsets.all(20.0),
            children: [
              Center(
                child: Text(
                  "Refresh View",
                  style: TextStyle(
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    });

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: SafeArea(
        child: fbBody,
      ),
    );
  }
}
