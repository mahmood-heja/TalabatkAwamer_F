import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:talabatakawamer/model/CartItem.dart';
import 'package:talabatakawamer/model/Products.dart';
import 'package:talabatakawamer/utils/DatabaseHelper.dart';
import 'package:transparent_image/transparent_image.dart';

final String sectionName = "Vegetable";

class ListViewVegetable extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _ListVegetableState();
}

class _ListVegetableState extends State<ListViewVegetable>
    with AutomaticKeepAliveClientMixin<ListViewVegetable> {
  List<VegetableItem> listItems = List();
  Future<List<VegetableItem>> _postResult;

  DatabaseHelper _databaseHelper = DatabaseHelper.getInstance();
  OnChangeData _onChangeData;
  List<int> _productInsideCartById;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _postResult = _fetchPost();
    getProductInsideCartList().then((List<int> value) {
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
            _productInsideCartById = List<int>();
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
    return _getVegetableFutureList();
  }

  Future<List<int>> getProductInsideCartList() {
    return _databaseHelper.getCartItemBySection(sectionName);
  }

  FutureBuilder<List<VegetableItem>> _getVegetableFutureList() {
    return FutureBuilder<List<VegetableItem>>(
      future: _postResult,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasData && _productInsideCartById != null) {
          listItems = snapshot.data;
          return _buildList();
        } else if (snapshot.hasError) {
          return Text("Error : ${snapshot.error.toString()}");
        }

        // By default, show a loading spinner.
        return Center(child: CircularProgressIndicator());
      },
    );
  }

  GridView _buildList() {
    double width = MediaQuery.of(context).size.width;

    int countRow = width ~/ 150;
    double crossAxisSpacing = (width % 150) / (countRow + 1);

    return GridView.builder(
      shrinkWrap: false,
      padding: EdgeInsets.all(10),
      itemCount: listItems.length,
      itemBuilder: (BuildContext context, int index) {
        VegetableItem item = listItems[index];
        return _CardItem(Key(UniqueKey().toString()), item, index,
            _productInsideCartById.contains(item.id));
      },
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: countRow,
          crossAxisSpacing: crossAxisSpacing,
          mainAxisSpacing: 12,
          childAspectRatio:
              MediaQuery.of(context).orientation == Orientation.portrait
                  ? 1 / 1.7
                  : 1 / 1.8),
    );
  }

  Future<List<VegetableItem>> _fetchPost() async {
    Map<String, dynamic> match = {
      "is_Visible": "1",
    };

    List<VegetableItem> listItem = List();

    var url =
        'http://talabatakawamer.com/TalabatakAwamerApp/VegetableSection/getAllProduct.php';

    final response = await http.post(
      Uri.parse(url),
      body: match,
    );

    if (response.statusCode == 200) {
      // If server returns an OK response, parse the JSON.

      Map<String, dynamic> mapData = json.decode(response.body);

      //get array of products
      List<dynamic> list = mapData["products"];
      //convert every product to object
      for (int i = 0; i < list.length; i++) {
        listItem.add(VegetableItem.fromJson(list[i]));
      }

      return listItem;
    } else {
      // If that response was not OK, throw an error.
      throw Exception('Failed to load post');
    }
  }
}

class _CardItem extends StatefulWidget {
  final VegetableItem item;
  final int index;
  final bool insideCart;

  _CardItem(Key key, this.item, this.index, this.insideCart) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _CardState();
  }
}

class _CardState extends State<_CardItem> {
  List<String> _categoryProduct = <String>["صنف اول", "صنف سوبر"];
  String groupValue;
  VegetableItem item;
  int index;

  //cart information
  bool insideCart;
  CartItem _cartItem;

  DatabaseHelper _databaseHelper = DatabaseHelper.getInstance();

  @override
  void initState() {
    super.initState();
    item = widget.item;
    index = widget.index;
    groupValue = _getItemPicked();
    insideCart = widget.insideCart;

    ///get information product from cart if it added
    if (insideCart)
      _databaseHelper.getCartItemByIdProduct(item.id, sectionName).then((map) {
        setState(() {
          if (map == null) {
            insideCart = false;
            return;
          }
          _cartItem = CartItem.fromMapObject(map);

          item.currentQuantity = _cartItem.quantity;
          groupValue = _cartItem.productClassification;
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
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          FadeInImage.memoryNetwork(
            image: item.imageUrl,
            height: 80,
            fit: BoxFit.contain,
            placeholder: kTransparentImage,
          ),
          _createRadioGroup(),
          Padding(
            padding: EdgeInsets.all(5),
            child: Text(item.name, textAlign: TextAlign.center),
          ),
          RaisedButton(
            onPressed: _addToCartAction,
            padding: EdgeInsets.all(0),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            color: insideCart ? Colors.grey : Colors.green,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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

  Widget _createRadioGroup() {
    //display price in JD when it larger than 200 cent
    //when price ==-1 that mean is it not available
    String priceFirst = item.priceFirst == -1
        ? "غير متوفر"
        : item.priceFirst >= 200
            ? "${item.priceFirst / 100.0} دينار "
            : "${item.priceFirst} قرش ";
    String priceSuper = item.priceSuper == -1
        ? "غير متوفر"
        : item.priceSuper >= 200
            ? "${item.priceSuper / 100.0} دينار "
            : "${item.priceSuper} قرش ";

    Color backgroundFirst =
        item.priceFirst == -1 ? Colors.grey[400] : Colors.transparent;
    Color backgroundSuper =
        item.priceSuper == -1 ? Colors.grey[400] : Colors.transparent;

    //set onChange = null if category not avi. to disable radioBtn
    ValueChanged onChangeFirst = item.priceFirst == -1
        ? null
        : (value) {
            setState(() {
              groupValue = value;
            });
          };

    ValueChanged onChangeSuper = item.priceSuper == -1
        ? null
        : (value) {
            setState(() {
              groupValue = value;
            });
          };

    return Column(
      children: <Widget>[
        InkWell(
          //to change radio select when tap any where on row
          onTap: () => onChangeSuper(_categoryProduct[1]),
          child: Container(
              color: backgroundSuper,
              padding: EdgeInsets.only(right: 4, left: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Flexible(
                    flex: 1,
                    fit: FlexFit.tight,
                    child: FittedBox(
                        fit: BoxFit.contain,
                        child: Text(
                          priceSuper,
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.center,
                        )),
                  ),
                  Radio(
                    onChanged: onChangeSuper,
                    value: _categoryProduct[1],
                    groupValue: groupValue,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  Flexible(
                    flex: 1,
                    fit: FlexFit.loose,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: Text(
                        _categoryProduct[1],
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              )),
        ),
        InkWell(
          //to change radio select when tap any where on row
          onTap: () => onChangeFirst(_categoryProduct[0]),
          child: Container(
              color: backgroundFirst,
              padding: EdgeInsets.only(right: 4, left: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Flexible(
                    flex: 1,
                    fit: FlexFit.tight,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: Text(
                        priceFirst,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Radio(
                    onChanged: onChangeFirst,
                    value: _categoryProduct[0],
                    groupValue: groupValue,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  Flexible(
                    flex: 1,
                    fit: FlexFit.loose,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: Text(
                        _categoryProduct[0],
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              )),
        ),
        _line(),
        _createQuantityControl(),
        _line(),
      ],
    );
  }

  Widget _createQuantityControl() {
    double jump = item.quantityType == 3 ? 0.5 : 1;

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

  Widget _line() {
    return Container(
      padding: EdgeInsets.all(0),
      margin: EdgeInsets.all(0),
      height: 1,
      color: Theme.of(context).accentColor,
    );
  }

  String _getItemPicked() {
    if (item.priceSuper == -1)
      return _categoryProduct[0];
    else if (item.priceFirst == -1)
      return _categoryProduct[1];
    else
      return _categoryProduct[1];
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

  void _updateCartItem() {
    if (_cartItem != null && _cartItem.id != null) {
      int pricePerUnit =
          groupValue == _categoryProduct[0] ? item.priceFirst : item.priceSuper;

      _cartItem.quantity = item.currentQuantity;
      _cartItem.productClassification = groupValue;
      _cartItem.priceInCart = pricePerUnit * item.currentQuantity;
      _cartItem.pricePerUnit = pricePerUnit;

      _databaseHelper.updateCartItem(_cartItem);
    }
  }

  //create when add to cart
  CartItem createCartItem() {
    int pricePerUnit =
        groupValue == _categoryProduct[0] ? item.priceFirst : item.priceSuper;

    return CartItem(
        item.id,
        item.name,
        groupValue,
        item.imageUrl,
        pricePerUnit,
        item.quantityName,
        item.currentQuantity,
        item.currentQuantity * pricePerUnit,
        sectionName);
  }
}
