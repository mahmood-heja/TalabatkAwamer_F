import 'dart:async';
import 'dart:io';

import 'package:talabatakawamer/model/CartItem.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static DatabaseHelper _databaseHelper; // Singleton DatabaseHelper
  static Database _database; // Singleton Database

  String cartTable = 'cart_table';
  List<OnChangeData> _onChangeData = List();

  DatabaseHelper._createInstance(); // Named constructor to create instance of DatabaseHelper

  factory DatabaseHelper.getInstance() {
    if (_databaseHelper == null) {
      _databaseHelper = DatabaseHelper
          ._createInstance(); // This is executed only once, singleton object
    }
    return _databaseHelper;
  }

  Future<Database> get database async {
    if (_database == null) {
      _database = await initializeDatabase();
    }
    return _database;
  }

  Future<Database> initializeDatabase() async {
    // Get the directory path for both Android and iOS to store database.
    Directory directory = await getApplicationDocumentsDirectory();
    String path = directory.path + '$cartTable.db';

    // Open/create the database at a given path
    var cartsDatabase =
        await openDatabase(path, version: 1, onCreate: _createDb);
    return cartsDatabase;
  }

  void _createDb(Database db, int newVersion) async {
    await db.execute(
        'CREATE TABLE $cartTable(${ColumnNames.idCol} INTEGER PRIMARY KEY AUTOINCREMENT, ${ColumnNames.nameCol} TEXT, '
        '${ColumnNames.productClassificationCol} TEXT, ${ColumnNames.imageUrlCol} INTEGER, ${ColumnNames.pricePerUnitCol} INTEGER, '
        '${ColumnNames.quantityUnitCol} TEXT, ${ColumnNames.quantityCol} DOUBLE, ${ColumnNames.priceInCartCol} DOUBLE, '
        '${ColumnNames.sectionNameCol} TEXT, ${ColumnNames.idProductCol} INTEGER)');
  }

  /// Fetch Operation: Get all cartItem objects from database
  Future<List<Map<String, dynamic>>> getCartItemMapList() async {
    Database db = await this.database;

//	var result = await db.rawQuery('SELECT * FROM $cartTable order by ${ColumnNames.idCol} DESC');
    var result =
        await db.query(cartTable, orderBy: '${ColumnNames.idCol} DESC');
    return result;
  }

  /// Fetch Operation: Get all productId in specific section from database
  Future<List<int>> getCartItemBySection(String sectionName) async {
    Database db = await this.database;

    var cartItem = await db.query(cartTable,
        orderBy: '${ColumnNames.idCol} ASC',
        where: '${ColumnNames.sectionNameCol} = ?',
        whereArgs: [sectionName]);

    List<int> result = List();

    //get IdProduct 's
    for (int i = 0; i < cartItem.length; i++) {
      result.add(cartItem[i][ColumnNames.idProductCol]);
    }

    return result;
  }

  /// Insert Operation: Insert a CartItem object to database
  Future<int> insertCartItem(CartItem cartItem) async {
    Database db = await this.database;
    var result = await db.insert(cartTable, cartItem.toMap()).then((value) {
      for (OnChangeData onChangeData in _onChangeData)
        onChangeData(cartItem.sectionName, Operation.insert, cartItem);
      return value;
    });

    return result;
  }

  /// Update Operation: Update a CartItem object and save it to database
  Future<int> updateCartItem(CartItem cartItem) async {
    var db = await this.database;
    var result = await db.update(cartTable, cartItem.toMap(),
        where: '${ColumnNames.idCol} = ?', whereArgs: [cartItem.id]);
    return result;
  }

  /// Delete Operation: Delete a CartItem object from database
  Future<int> deleteCartItem(CartItem item) async {
    var db = await this.database;

    int result = await db.delete(cartTable,
        where: '${ColumnNames.idCol} = ?', whereArgs: [item.id]).then((value) {
      for (OnChangeData onChangeData in _onChangeData)
        onChangeData(item.sectionName, Operation.delete, item);
      return value;
    });

    return result;
  }

  /// Delete All Operation: Delete All CartItem objects from database
  Future<int> deleteAllItem() async {
    var db = await this.database;

    int result = await db.delete(cartTable).then((value) {
      for (OnChangeData onChangeData in _onChangeData)
        onChangeData(null, Operation.deleteAll, null);
      return value;
    });

    return result;
  }

  ///get cartItem object by product ID from #mysql and section name
  Future<Map<String, dynamic>> getCartItemByIdProduct(
      int idProduct, String section) async {
    var db = await this.database;

    List<Map<String, dynamic>> result = await db.query(cartTable,
        where:
            '${ColumnNames.idProductCol} = ? AND ${ColumnNames.sectionNameCol} = ?',
        whereArgs: [idProduct, section]);

    // must be one result
    return result[0];
  }

  /// Get number of CartItem objects in database
  Future<int> getCount() async {
    Database db = await this.database;
    List<Map<String, dynamic>> x =
        await db.rawQuery('SELECT COUNT (*) from $cartTable');
    int result = Sqflite.firstIntValue(x);
    return result;
  }

  /// get number of product in cart based on Section Name
  Future<int> getCountProductBySection(String section) async {
    List<int> x = await getCartItemBySection(section);

    int result = x.length;
    return result;
  }

  //return list of CartItem
  Future<List<CartItem>> getCartItemList() async {
    List<CartItem> listCartItem = List<CartItem>();

    List<Map<String, dynamic>> mapObjects = await getCartItemMapList();

    for (int i = 0; i < mapObjects.length; i++)
      listCartItem.add(CartItem.fromMapObject(mapObjects[i]));

    return listCartItem;
  }

  void addOnChangeData(OnChangeData onChangeData) {
    _onChangeData.add(onChangeData);
  }

  void removeChangeData(OnChangeData onChangeData) {
    _onChangeData.remove(onChangeData);
  }
}

typedef OnChangeData(
    String sectionName, Operation operation, CartItem cartItem);

enum Operation { insert, delete, deleteAll }
