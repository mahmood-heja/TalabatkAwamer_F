import 'package:talabatakawamer/utils/DatabaseHelper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart' as UrlLauncher;

import 'CartRoute/CartRoute.dart';
import 'Sections/HomemadeSection.dart';
import 'Sections/JuiceSection.dart';
import 'Sections/PoultrySection.dart';
import 'Sections/VegteableSection.dart';
import 'package:badges/badges.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "طلباتك اوامر",
      color: Theme.of(context).primaryColor,
      home: TabBarSection(),
      theme: ThemeData(
          fontFamily: 'Urw',
          accentColor: Color(0XFFFF0000),
          primaryColor: Color(0XFF1E9600),
          primaryColorDark: Color(0XFF1C8602)),
    );
  }
}

class TabBarSection extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => TabBarSectionState();
}

class TabBarSectionState extends State<TabBarSection> {
  @override
  Widget build(BuildContext context) {
    TextStyle tabTextStyle = TextStyle(fontSize: 12);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            CartBadge(),
            Expanded(
                child: Text(
              "طلباتك اوامر",
              textAlign: TextAlign.center,
            )),
            IconButton(
              icon: Icon(CupertinoIcons.phone_solid),
              onPressed: () => UrlLauncher.launch("tel:0798718364"),
            )
          ],
        ),
        centerTitle: true,
        titleSpacing: 0,
      ),
      body: DefaultTabController(
        length: 4,
        child: Column(
          children: <Widget>[
            Expanded(
              child: TabBarView(
                children: [
                  ListViewVegetable(),
                  ListViewHomemade(),
                  ListViewJuice(),
                  ListViewPoultry(),
                ],
              ),
            ),
            Container(
              color: Theme.of(context).accentColor,
              height: 1,
            ),
            Container(
              color: Theme.of(context).primaryColor,
              child: TabBar(
                labelPadding: EdgeInsets.only(left: 4, right: 4),
                labelColor: Colors.white,
                indicatorColor: Colors.white,
                unselectedLabelColor: Colors.grey[800],
                tabs: [
                  Tab(
                    child: Text("خضراوات وفواكه",
                        softWrap: true,
                        textAlign: TextAlign.center,
                        style: tabTextStyle),
                  ),
                  Tab(
                      child: Text("المنتجات البيتية",
                          softWrap: true,
                          textAlign: TextAlign.center,
                          style: tabTextStyle)),
                  Tab(
                      child: Text("عصائر طبيعية",
                          softWrap: true,
                          textAlign: TextAlign.center,
                          style: tabTextStyle)),
                  Tab(
                      child: Text("دواجن",
                          softWrap: true,
                          textAlign: TextAlign.center,
                          style: tabTextStyle)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

///Cart IconBtn bar widget
class CartBadge extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => CartBadgeState();
}

class CartBadgeState extends State<CartBadge> {
  DatabaseHelper _databaseHelper = DatabaseHelper.getInstance();
  OnChangeData _onChangeData;

  int countInCart;

  @override
  void initState() {
    super.initState();
    countInCart = 0;

    _databaseHelper.getCount().then((count) {
      setState(() {
        countInCart = count;
      });
    });

    _onChangeData = (section, opr, item) {
      setState(() {
        if (opr == Operation.insert)
          ++countInCart;
        else if (opr == Operation.delete)
          --countInCart;
        else if (opr == Operation.deleteAll) countInCart = 0;
      });
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
    return Badge(
      position: BadgePosition.topRight(right: 0),
      badgeContent: Text(
        "$countInCart",
        style: TextStyle(color: Colors.white),
      ),
      badgeColor: Theme.of(context).accentColor,
      animationType: BadgeAnimationType.slide,
      animationDuration: Duration(microseconds: 500),
      child: IconButton(
        icon: Icon(Icons.shopping_cart),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CartRoute()),
          );
        },
      ),
    );
  }
}
