import 'package:talabatakawamer/Sections/HomemadeSection.dart'
    as HomemadeSection;
import 'package:talabatakawamer/model/CartItem.dart';
import 'package:talabatakawamer/utils/DatabaseHelper.dart';
import 'package:flutter/material.dart';
import 'package:toast/toast.dart';
import 'package:transparent_image/transparent_image.dart';

import 'RequestOrderDialog.dart';

class CartBody extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _CartBodyState();
}

class _CartBodyState extends State<CartBody> {
  DatabaseHelper _databaseHelper = DatabaseHelper.getInstance();
  List<CartItem> _list = List();
  OnChangeData _onChangeData;

  @override
  void initState() {
    super.initState();

    _databaseHelper.getCartItemList().then((values) {
      setState(() {
        _list = values;
      });

      _onChangeData = (section, operation, cartItem) {
        if (operation == Operation.delete)
          setState(() {
            _list.remove(cartItem);
          });
        else if (operation == Operation.deleteAll)
          setState(() {
            _list = List();
          });
      };

      _databaseHelper.addOnChangeData(_onChangeData);
    });
  }

  @override
  void dispose() {
    super.dispose();
    _databaseHelper.removeChangeData(_onChangeData);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: _buildCartList(),
        ),
        RaisedButton(
          onPressed: _showDialogTime,
          child: Text("إختر فترة التوصيل",
              style: TextStyle(color: Colors.white, fontSize: 18)),
          color: Theme.of(context).primaryColor,
          padding: EdgeInsets.all(10),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        )
      ],
    );
  }

  Widget _buildCartList() {
    return ListView.builder(
        itemCount: _list.length,
        itemBuilder: (context, index) {
          return _CardView(
            index: index,
            cartItem: _list[index],
            databaseHelper: _databaseHelper,
          );
        });
  }

  void _showDialogTime() {
    //check cart is empty
    if (_list.length == 0) {
      Toast.show("لا يوجد اي طلب داخل السلة", context,
          duration: Toast.LENGTH_LONG,
          gravity: Toast.CENTER,
          backgroundColor: Theme.of(context).accentColor,
          textColor: Colors.white);
      return;
    }

    _databaseHelper
        .getCountProductBySection(HomemadeSection.sectionName)
        .then((int count) {
      debugPrint("Count $count");
      showDialog(
          context: context,
          builder: (BuildContext context) =>
              DialogRequestOrder(countProductHomemade: count));
    });
  }
}

class _CardView extends StatelessWidget {
  final String priceAR = "السعر", quantityAR = "الكمية", dinarAr = "دينار";

  final DatabaseHelper databaseHelper;
  final int index;
  final CartItem cartItem;

  const _CardView({this.index, this.cartItem, this.databaseHelper});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: ListTile(
        contentPadding: EdgeInsets.all(4),
        trailing: FadeInImage.memoryNetwork(
          width: 64,
          image: cartItem.imageUrl,
          fit: BoxFit.contain,
          placeholder: kTransparentImage,
        ),
        title: Text(
          "${cartItem.name}  ${cartItem.productClassification}",
          textDirection: TextDirection.rtl,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 14),
        ),
        subtitle: Text(
          "$quantityAR : ${cartItem.quantity} ${cartItem.quantityUnit} \n$priceAR : ${cartItem.priceInCart / 100.0} $dinarAr",
          textDirection: TextDirection.rtl,
        ),
        isThreeLine: true,
        leading: IconButton(
            icon: Icon(
              Icons.delete,
              color: Theme.of(context).accentColor,
            ),
            onPressed: () {
              databaseHelper.deleteCartItem(cartItem);
            }),
      ),
    );
  }
}
