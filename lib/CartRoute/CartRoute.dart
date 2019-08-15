import 'package:talabatakawamer/model/CartItem.dart';
import 'package:talabatakawamer/utils/DatabaseHelper.dart';
import 'package:flutter/material.dart';

import 'CartBody.dart';

class CartRoute extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _CartRouteState();
}

class _CartRouteState extends State<CartRoute> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("سلتي"),
        bottom: PreferredSize(
            child: _TotalPriceBar(), preferredSize: Size(100, 64)),
      ),
      body: CartBody(),
    );
  }
}

class _TotalPriceBar extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _TotalPriceBarState();
  }
}

class _TotalPriceBarState extends State<_TotalPriceBar> {
  final String barNote = "يضاف دينار واحد قيمة التوصيل داخل مدينة اربد";
  String totalPrice;

  DatabaseHelper _databaseHelper = DatabaseHelper.getInstance();
  OnChangeData _onChangeData;

  @override
  void initState() {
    super.initState();
    totalPrice = "0.0";

    _onChangeData = (section, opr, cartItem) {
      if (opr == Operation.delete)
        setState(() {
          totalPrice = (double.parse(totalPrice) - cartItem.priceInCart / 100.0)
              .toStringAsFixed(2);
        });
      else if (opr == Operation.deleteAll)
        setState(() {
          totalPrice = "0.0";
        });
    };

    _databaseHelper.getCartItemList().then((items) {
      double total = 0;
      for (CartItem cartItem in items) total += cartItem.priceInCart / 100.0;

      setState(() {
        totalPrice = total.toStringAsFixed(2);
      });
    });

    _databaseHelper.addOnChangeData(_onChangeData);
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
        Text(
          " المجموع : $totalPrice دينار ",
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
        Text(
          barNote,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 10, color: Colors.white),
        ),
      ],
    );
  }
}
