import 'dart:convert';

import 'package:talabatakawamer/model/CartItem.dart';
import 'package:talabatakawamer/model/Products.dart';
import 'package:talabatakawamer/utils/DatabaseHelper.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:transparent_image/transparent_image.dart';

final String sectionName = "Juice";

class ListViewJuice extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _ListJuiceState();
  }
}

class _ListJuiceState extends State<ListViewJuice>
    with AutomaticKeepAliveClientMixin<ListViewJuice> {
  Future<List<JuiceItem>> _postResult;

  DatabaseHelper _databaseHelper = DatabaseHelper.getInstance();
  OnChangeData _onChangeData;
  List<int> _productInsideCartById;

  @override
  void initState() {
    super.initState();
    _postResult = _fetchPost();

    _databaseHelper.getCartItemBySection(sectionName).then((List<int> value) {
      setState(() {
        _productInsideCartById = value;
      });
    });

    _onChangeData = (section, operation, cartItem) {
      if (section == sectionName || operation == Operation.deleteAll) {
        setState(() {
          if (operation == Operation.insert)
            _productInsideCartById.add(cartItem.idProduct);
          else if (operation == Operation.delete)
            _productInsideCartById.remove(cartItem.idProduct);
          else if (operation == Operation.deleteAll)
            _productInsideCartById = List();
        });
      }
    };

    _databaseHelper.addOnChangeData(_onChangeData);
  }

  @override
  void dispose() {
    super.dispose();
    _databaseHelper.removeChangeData(_onChangeData);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<List<JuiceItem>>(
      future: _postResult,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasData) {
          List<JuiceItem> listItems = snapshot.data;
          return _buildList(listItems);
        } else if (snapshot.hasError) {
          debugPrint(snapshot.error.toString());
          return Text("Error");
        }

        // By default, show a loading spinner.
        return Center(child: CircularProgressIndicator());
      },
    );
  }

  GridView _buildList(List<JuiceItem> listItems) {
    double width = MediaQuery.of(context).size.width;

    debugPrint("Width $width");
    int countRow = width ~/ 150;
    double crossAxisSpacing = (width % 150) / (countRow + 1);

    return GridView.builder(
      padding: EdgeInsets.all(10),
      itemCount: listItems.length,
      itemBuilder: (BuildContext context, int index) {
        JuiceItem item = listItems[index];
        return _CardItem(Key(UniqueKey().toString()), item, index,
            _productInsideCartById.contains(item.id));
      },
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: countRow,
          crossAxisSpacing: crossAxisSpacing,
          mainAxisSpacing: 12,
          childAspectRatio: 1 / 1.5),
    );
  }

  Future<List<JuiceItem>> _fetchPost() async {
    Map<String, dynamic> match = {
      "isVisible": "1",
    };

    List<JuiceItem> listItem = List();

    var url =
        'http://talabatakawamer.com/TalabatakAwamerApp/BreadSection/getAllProduct.php';

    final response = await http.post(Uri.parse(url), body: match);

    if (response.statusCode == 200) {
      // If server returns an OK response, parse the JSON.

      Map<String, dynamic> mapData = json.decode(response.body);

      //get array of products
      List<dynamic> list = mapData["products"];
      //convert every product to object
      for (int i = 0; i < list.length; i++) {
        listItem.add(JuiceItem.fromJson(list[i]));
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
  final int index;
  final JuiceItem item;
  final bool insideCart;

  _CardItem(Key key, this.item, this.index, this.insideCart) : super(key: key);

  @override
  State<StatefulWidget> createState() => _CardState();
}

class _CardState extends State<_CardItem> {
  JuiceItem item;
  int index;
  String price;

  //cart information
  bool insideCart;
  CartItem _cartItem;

  DatabaseHelper _databaseHelper = DatabaseHelper.getInstance();

  @override
  void initState() {
    super.initState();
    item = widget.item;
    index = widget.index;
    insideCart = widget.insideCart;

    price = item.price >= 200
        ? "${item.price / 100.0} دينار "
        : "${item.price} قرش ";

    ///get information product from cart if it added
    if (insideCart)
      _databaseHelper.getCartItemByIdProduct(item.id, sectionName).then((map) {
        setState(() {
          _cartItem = CartItem.fromMapObject(map);
          item.currentQuantity = _cartItem.quantity;
        });
      });
  }

  @override
  Widget build(BuildContext context) {
    ///when call build from setState() method update information into cart
    ///and change price in cart if admin change price for some product
    if (insideCart) _updateCartItem();

    return Card(
      elevation: 2,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          FadeInImage.memoryNetwork(
            image: item.imageUrl,
            height: 80,
            fit: BoxFit.contain,
            placeholder: kTransparentImage,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(4.0),
                height: 38,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Text(item.name.trim(), textAlign: TextAlign.center),
                ),
              ),
              _line(),
              _createQuantityControl(),
              _line(),
            ],
          ),
          Padding(
            padding: EdgeInsets.all(5),
            child: Text(
              price,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
            ),
          ),
          RaisedButton(
            onPressed: _addToCartAction,
            padding: EdgeInsets.all(0),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            color: insideCart ? Colors.grey : Colors.green,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                Text(
                  insideCart ? "تمت الاضافة" : "اضف الى السلة",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white),
                ),
                Icon(
                  insideCart ? Icons.done_outline : Icons.shopping_cart,
                  color: insideCart ? Colors.green[800] : Colors.white,
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _createQuantityControl() {
    double jump = 1;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          height: 32,
          width: 32,
          child: Container(
            color: Theme.of(context).primaryColor,
            child: IconButton(
              splashColor: Theme.of(context).primaryColor,
              icon: Icon(Icons.add, color: Colors.white),
              onPressed: () {
                setState(() {
                  item.currentQuantity += jump;
                });
              },
              padding: EdgeInsets.all(0),
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Text(
            "${item.currentQuantity} ${item.quantityName}",
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(
          height: 32,
          width: 32,
          child: Container(
            color: Theme.of(context).primaryColor,
            child: IconButton(
              splashColor: Theme.of(context).primaryColor,
              icon: Icon(Icons.remove, color: Colors.white),
              onPressed: () {
                if (item.currentQuantity - jump > 0)
                  setState(() {
                    item.currentQuantity -= jump;
                  });
              },
              padding: EdgeInsets.all(0),
            ),
          ),
        ),
      ],
    );
  }

  void _addToCartAction() {
    if (!insideCart) {
      _cartItem = createCartItem();
      _databaseHelper.insertCartItem(_cartItem).then((int id) {
        _cartItem.id = id;
      });
      insideCart = true;
    } else {
      if (_cartItem.id != null) {
        _databaseHelper.deleteCartItem(_cartItem);
        _cartItem = null;
        insideCart = false;
      }
    }
  }

  //create when add to cart
  CartItem createCartItem() {
    return CartItem(
        item.id,
        item.name,
        "",
        // no classification for this product
        item.imageUrl,
        item.price,
        item.quantityName,
        item.currentQuantity,
        item.currentQuantity * item.price,
        sectionName);
  }

  void _updateCartItem() {
    if (_cartItem != null && _cartItem.id != null) {
      _cartItem.quantity = item.currentQuantity;
      _cartItem.priceInCart = item.price * item.currentQuantity;
      _cartItem.pricePerUnit = item.price;

      _databaseHelper.updateCartItem(_cartItem);
    }
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
