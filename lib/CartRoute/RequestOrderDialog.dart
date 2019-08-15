import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:talabatakawamer/model/CartItem.dart';
import 'package:talabatakawamer/utils/DatabaseHelper.dart';
import 'package:toast/toast.dart';

//time interval selected
String groupValue = "";

class DialogRequestOrder extends StatefulWidget {
  final int countProductHomemade;

  DialogRequestOrder({@required this.countProductHomemade});

  @override
  State<StatefulWidget> createState() => DialogRequestOrderState();
}

class DialogRequestOrderState extends State<DialogRequestOrder> {
  int countProductHomemade;
  bool isValidPhone;

  final TimeOfDay now = TimeOfDay.now();
  final DatabaseHelper _databaseHelper = DatabaseHelper.getInstance();
  final TextEditingController phoneTextCont = TextEditingController();

  @override
  void initState() {
    super.initState();
    countProductHomemade = widget.countProductHomemade;
    isValidPhone = true;
  }

  @override
  Widget build(BuildContext context) {
    List<String> timeIntervals = getTimeIntervals();

    String dayOfDelivery =
        now.hour >= 17 || countProductHomemade > 0 ? "TOMORROW" : "TODAY";
    String titleTime = dayOfDelivery == "TOMORROW"
        ? "إختر فترة التوصيل من يوم غد"
        : "إختر فترة التوصيل لهذا اليوم";

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          child: Container(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                getDialogBar(titleTime),
                _RadioGroupTimeInterval(listTimeInterval: timeIntervals),
                getTotalPriceWidget(),
                Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: TextField(
                    keyboardType: TextInputType.phone,
                    controller: phoneTextCont,
                    decoration: InputDecoration(
                        hintText: "إدخل رقم هاتف من اجل التواصل",
                        errorText: !isValidPhone ? "ادخل رقم هاتف صالح" : null),
                  ),
                ),
                getBtnRow()
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget getTotalPriceWidget() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: FutureBuilder<double>(
        future: getTotalPrice(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.hasData) {
            double totalPrice = snapshot.data;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Text(
                  " المجموع : ${totalPrice.toStringAsFixed(2)} دينار ",
                  textDirection: TextDirection.rtl,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                Text(
                  "* غير شامل سعر التوصيل",
                  textDirection: TextDirection.rtl,
                  style: TextStyle(fontSize: 10),
                )
              ],
            );
          }
          return Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Future<double> getTotalPrice() async {
    double total = 0;

    List<CartItem> items = await _databaseHelper.getCartItemList();

    for (CartItem cartItem in items) total += cartItem.priceInCart / 100.0;

    return total;
  }

  Widget getDialogBar(String titleTime) {
    return Container(
      padding: EdgeInsets.all(8.0),
      color: Theme.of(context).accentColor,
      child: Column(
        children: <Widget>[
          Icon(
            Icons.access_time,
            size: 38,
            color: Colors.white,
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              titleTime,
              style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  List<String> getTimeIntervals() {
    // get hour in 24 format
    int hour = now.hour;
    int iMin = now.minute;

    // add prefix zero if min is less than 10 or if first condition is not true
    String min;
    if (hour >= 17 || hour < 8 || countProductHomemade > 0)
      min = "00";
    else
      min = iMin < 10 ? "0$iMin" : iMin.toString();

    //last hour to request  is 5PM
    // startInterval is begin from 10 AM (11 AM for HOME MADE) or after 1 hour of time of request
    // and depend on request hour from user or product type in cart
    int startInterval = hour >= 17 || hour < 10 || countProductHomemade > 0
        ? countProductHomemade > 0 ? 11 : 10
        : hour + 1;

    List<String> timeInterval = List();
    //last hour to deliver is 7PM
    while (startInterval < 19) {
      String from =
          (startInterval > 12 ? "${startInterval - 12}" : "$startInterval") +
              ":" +
              min +
              " " +
              (startInterval >= 12 ? "PM" : "AM");
      startInterval += 2;
      startInterval = startInterval > 19 ? 19 : startInterval;

      String to =
          (startInterval > 12 ? "${startInterval - 12}" : "$startInterval") +
              ":" +
              min +
              " " +
              (startInterval >= 12 ? "PM" : "AM");
      String time = from + " - " + to;

      timeInterval.add(time);
    }

    return timeInterval;
  }

  Row getBtnRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        InkWell(
          onTap: () {
            //dismiss dialog
            Navigator.pop(context);
          },
          highlightColor: Theme.of(context).accentColor,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              "إلغاء",
              style: TextStyle(
                  color: Theme.of(context).accentColor,
                  fontSize: 17,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ),
        InkWell(
          onTap: sendRequestOrder,
          highlightColor: Theme.of(context).primaryColor,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              "إطلب",
              style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 17,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  void sendRequestOrder() {
    //check the phone number
    if (phoneTextCont.text.length != 10 ||
        !phoneTextCont.text.startsWith("07")) {
      setState(() {
        isValidPhone = false;
      });
      return;
    }
    //check value time interval if selected
    if (groupValue.trim().length == 0) {
      Toast.show("يرجى إختيار فترة التوصيل بالبداية", context,
          duration: Toast.LENGTH_LONG,
          gravity: Toast.CENTER,
          backgroundColor: Theme.of(context).accentColor,
          textColor: Colors.white);
      return;
    }
    //dismiss time interval dialog
    Navigator.pop(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        _sendOrder(context).then((isSent) {
          if (isSent) {
            DatabaseHelper.getInstance().deleteAllItem();
            sendNotify(phoneTextCont.text);
            //dismiss progress dialog
            Navigator.pop(context);
            Toast.show("تم إرسال طلبك بنجاح", context,
                duration: Toast.LENGTH_LONG,
                gravity: Toast.CENTER,
                backgroundColor: Theme.of(context).primaryColor,
                textColor: Colors.white);
          } else
            Toast.show(
                "يرجى التحقق من اتصالك من الانترنت والمحاولة مرة إخرى", context,
                duration: Toast.LENGTH_LONG,
                gravity: Toast.CENTER,
                backgroundColor: Theme.of(context).accentColor,
                textColor: Colors.white);
        });

        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          child: new Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(child: CircularProgressIndicator()),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  "جاري إرسال الطلب \n\n قد يطرأ تغير بسيط على الاوزان في حال حصول ذلك سيتم إرسال فاتورة نهائية اليك",
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<bool> _sendOrder(BuildContext context) async {
    List<dynamic> billInfo = await buildBillInfo();
    double totalPrice = await getTotalPrice() * 100.0;

    Map<String, dynamic> match = {
      "phone_info": phoneTextCont.text,
      "info": json.encode(billInfo),
      "deliverTime": groupValue,
      "total_price": totalPrice.toString(),
      "token": "no Token",
      "platform":
          Theme.of(context).platform == TargetPlatform.iOS ? "ios" : "android",
    };

    var url =
        'http://talabatakawamer.com/TalabatakAwamerApp/VegetableSection/insertNewOrder.php';

    final response = await http.post(
      Uri.parse(url),
      body: match,
    );

    if (response.statusCode == 200) {
      // If server returns an OK response, parse the JSON.

      Map<String, dynamic> mapData = json.decode(response.body);

      return !mapData["error"];
    } else
      return false;
  }

  Future<List<dynamic>> buildBillInfo() async {
    List<dynamic> bill = List();

    List<CartItem> cartItems = await _databaseHelper.getCartItemList();

    for (CartItem item in cartItems) bill.add(item.toMapRequestOrder());

    return bill;
  }

  void sendNotify(String phoneNum) async {
    Map<String, dynamic> match = {
      "title": "'طلب جديد .",
      "message": "لديك طلب جديد من $phoneNum",
      "channel_id": "new_request",
      "content": "",
    };

    var url =
        'http://talabatakawamer.com/TalabatakAwamerApp/sendNotify/sentNotfiy.php';

    await http.post(
      Uri.parse(url),
      body: match,
    );
  }
}

class _RadioGroupTimeInterval extends StatefulWidget {
  final List<String> listTimeInterval;

  _RadioGroupTimeInterval({@required this.listTimeInterval});

  @override
  State<StatefulWidget> createState() => _RadioGroupState();
}

class _RadioGroupState extends State<_RadioGroupTimeInterval> {
  List<String> listTimeInterval;

  @override
  void initState() {
    super.initState();
    listTimeInterval = widget.listTimeInterval;
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> radioTimeInterval = List();
    //if just one interval is available select it by default
    if (listTimeInterval.length == 1) groupValue = listTimeInterval[0];
    //build radio btn for every interval
    for (String time in listTimeInterval)
      radioTimeInterval.add(_buildRadioBtn(time));

    // add red line in bottom
    radioTimeInterval.add(_line());

    return Container(
      color: Colors.grey[400],
      child: Column(
        children: radioTimeInterval,
      ),
    );
  }

  Row _buildRadioBtn(String timeInterval) {
    return Row(
      children: <Widget>[
        Radio<String>(
          groupValue: groupValue,
          value: timeInterval,
          onChanged: (timeSelect) {
            setState(() {
              groupValue = timeSelect;
            });
          },
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        InkWell(
            onTap: () {
              setState(() {
                groupValue = timeInterval;
              });
            },
            child: Text(
              timeInterval,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).primaryColor,
              ),
              softWrap: true,
            ))
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
}
