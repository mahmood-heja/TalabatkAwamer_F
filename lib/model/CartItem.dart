class CartItem {
  ///id inside sql table
  int id;

  ///id product in Mysql server
  int idProduct;

  ///product info.
  String name;
  String productClassification;
  String imageUrl;
  int pricePerUnit;

  ///cart item info
  String quantityUnit;
  double quantity;
  String sectionName;

  //priceInCart = quantity * quantityUnit
  double priceInCart;

  CartItem(
      this.idProduct,
      this.name,
      this.productClassification,
      this.imageUrl,
      this.pricePerUnit,
      this.quantityUnit,
      this.quantity,
      this.priceInCart,
      this.sectionName);

  // Extract a Note object from a Map object
  CartItem.fromMapObject(Map<String, dynamic> map) {
    this.id = map[ColumnNames.idCol];
    this.idProduct = map[ColumnNames.idProductCol];
    this.name = map[ColumnNames.nameCol];
    this.productClassification = map[ColumnNames.productClassificationCol];
    this.imageUrl = map[ColumnNames.imageUrlCol];
    this.pricePerUnit = map[ColumnNames.pricePerUnitCol];
    this.quantityUnit = map[ColumnNames.quantityUnitCol];
    this.quantity = map[ColumnNames.quantityCol];
    this.priceInCart = map[ColumnNames.priceInCartCol];
    this.sectionName = map[ColumnNames.sectionNameCol];
  }

  Map<String, dynamic> toMap() {
    var map = Map<String, dynamic>();

    if (id != null) {
      map[ColumnNames.idCol] = id;
    }
    map[ColumnNames.nameCol] = name;
    map[ColumnNames.idProductCol] = idProduct;
    map[ColumnNames.productClassificationCol] = productClassification;
    map[ColumnNames.imageUrlCol] = imageUrl;
    map[ColumnNames.pricePerUnitCol] = pricePerUnit;
    map[ColumnNames.quantityUnitCol] = quantityUnit;
    map[ColumnNames.quantityCol] = quantity;
    map[ColumnNames.priceInCartCol] = priceInCart;
    map[ColumnNames.sectionNameCol] = sectionName;

    return map;
  }

  //this method used to convert cartItem to JSON Object when sent to order request
  Map<String, dynamic> toMapRequestOrder() {
    var map = Map<String, dynamic>();

    map["id"] = idProduct;
    map["quantityType"] = quantityUnit;
    map["name"] = name;
    map["type"] = productClassification;
    map["quantity"] = quantity;
    // price in cent (قرش)
    map["price"] = priceInCart;
    map["image"] = imageUrl;
    // price per unit in cent
    map["pricePerUnit"] = pricePerUnit;
    //Packaging of product states
    // if true the price of packaging is added to total price and not to price of product
    // Packaging Price in cent (قرش)
    map["isPackaging"] = false;
    map["PackagingPrice"] = 0;

    return map;
  }
}

class ColumnNames {
  static final String idCol = "id";
  static final String idProductCol = "idProduct";
  static final String nameCol = "name";
  static final String productClassificationCol = "classification";
  static final String imageUrlCol = "imageUrl";
  static final String pricePerUnitCol = "pricePerUnit";
  static final String quantityUnitCol = "quantityUnit";
  static final String quantityCol = "quantity";
  static final String priceInCartCol = "priceIncart";
  static final String sectionNameCol = "sectionName";
}
