import 'dart:convert';

import 'package:talabatakawamer/model/Products.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:transparent_image/transparent_image.dart';

class ListViewPoultry extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _ListPoultryState();
}

class _ListPoultryState extends State<ListViewPoultry>
    with AutomaticKeepAliveClientMixin<ListViewPoultry> {
  String noteSection =
      "يمكن الطلب من منتجات قسم الدواجن من خلال الاتصال بموظف خدمة العملاء";

  Future<List<PoultryItem>> _postResult;

  @override
  void initState() {
    super.initState();
    _postResult = _fetchPost();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
            color: Colors.grey[400],
            padding: EdgeInsets.all(4),
            child: Text(
              noteSection,
              softWrap: true,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 16, color: Theme.of(context).primaryColor),
            )),
        Expanded(
          child: FutureBuilder<List<PoultryItem>>(
            future: _postResult,
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              if (snapshot.hasData) {
                List<PoultryItem> listItems = snapshot.data;
                return _buildList(listItems);
              } else if (snapshot.hasError) {
                debugPrint(snapshot.error.toString());
                return Text("Error");
              }

              // By default, show a loading spinner.
              return Center(child: CircularProgressIndicator());
            },
          ),
        ),
      ],
    );
  }

  GridView _buildList(List<PoultryItem> listItems) {
    double width = MediaQuery.of(context).size.width;

    debugPrint("Width $width");
    int countRow = width ~/ 150;
    double crossAxisSpacing = (width % 150) / (countRow + 1);

    return GridView.builder(
      padding: EdgeInsets.all(10),
      itemCount: listItems.length,
      itemBuilder: (BuildContext context, int index) {
        return _CardItem(listItems[index], index);
      },
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: countRow,
          crossAxisSpacing: crossAxisSpacing,
          mainAxisSpacing: 12,
          childAspectRatio: 1 / 1.3),
    );
  }

  Future<List<PoultryItem>> _fetchPost() async {
    Map<String, dynamic> match = {
      "isVisible": "1",
    };

    List<PoultryItem> listItem = List();

    var url =
        'http://talabatakawamer.com/TalabatakAwamerApp/PoultrySection/getAllProduct.php';

    final response = await http.post(Uri.parse(url), body: match);

    if (response.statusCode == 200) {
      // If server returns an OK response, parse the JSON.

      Map<String, dynamic> mapData = json.decode(response.body);

      //get array of products
      List<dynamic> list = mapData["products"];
      //convert every product to object
      for (int i = 0; i < list.length; i++) {
        listItem.add(PoultryItem.fromJson(list[i]));
      }

      return listItem;
    } else {
      // If that response was not OK, throw an error.
      throw Exception('Failed to load post');
    }
  }

  @override
  bool get wantKeepAlive => true;
}

class _CardItem extends StatefulWidget {
  final PoultryItem item;
  final int index;

  _CardItem(this.item, this.index);

  @override
  State<StatefulWidget> createState() => _CardState();
}

class _CardState extends State<_CardItem> {
  PoultryItem item;
  int index;
  String price;

  @override
  void initState() {
    super.initState();
    item = widget.item;
    index = widget.index;

    price = item.price >= 200
        ? "${item.price / 100.0} دينار/كيلو "
        : "${item.price} قرش/كيلو ";
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          FadeInImage.memoryNetwork(
            image: item.imageUrl,
            height: 100,
            fit: BoxFit.contain,
            placeholder: kTransparentImage,
          ),
          Padding(
            padding: EdgeInsets.all(5),
            child: Text(
              price,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
            ),
          ),
          _line(),
          Padding(
            padding: EdgeInsets.all(5),
            child: Text(
              item.name,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _line() {
    return Container(
      padding: EdgeInsets.all(0),
      margin: EdgeInsets.all(0),
      height: 1,
      color: Theme.of(context).accentColor,
    );
  }
}
