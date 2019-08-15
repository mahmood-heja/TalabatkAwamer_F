class VegetableItem extends ItemInList {
  String name;
  String des;

  // id product inside database
  int id;
  String imageUrl;
  int priceSuper;
  int priceFirst;

  //	0 for gram,1 for kg,2 for number
  // 3 spacial for kg give the user ability to change quantity by 0.5 not by one
  int quantityType;

  // 0 for super,1 for (صنف اول), and 2 for both
  int typeAvailable;

  VegetableItem(this.id, this.name, this.des, this.imageUrl, this.priceFirst,
      this.priceSuper, this.quantityType, this.typeAvailable);

  VegetableItem.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = json['name'],
        des = json['des'],
        imageUrl = json['image_url'],
        priceFirst = json['first_price'],
        priceSuper = json['super_price'],
        quantityType = json['quantity_type'],
        typeAvailable = json['type_available'];

  @override
  String get quantityName {
    switch (quantityType) {
      case 0:
        return " غرام ";
      case 1:
        return " كيلو ";
      case 2:
        return "";
      case 3:
        return " كيلو ";
    }

    return "";
  }
}

class HomemadeItem extends ItemInList {
  String name;

  // id product inside database
  int id;
  String imageUrl;
  int price;

  HomemadeItem(this.name, this.id, this.imageUrl, this.price);

  HomemadeItem.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = json['name'],
        price = json['price'],
        imageUrl = json['image_url'];
}

class JuiceItem extends ItemInList {
  int id;
  String name;
  String des;
  String imageUrl;
  int price;

  JuiceItem(this.id, this.name, this.des, this.imageUrl, this.price);

  JuiceItem.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = json['name'],
        price = json['priceSmall'],
        des = json['des'],
        imageUrl = json['image_url'];
}

class PoultryItem {
  int id;
  String name;
  String imageUrl;
  int price;

  PoultryItem(this.id, this.name, this.imageUrl, this.price);

  PoultryItem.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = json['name'],
        price = json['price'],
        imageUrl = json['image_url'];
}

class ItemInList {
  double currentQuantity = 1;
  String quantityName = "";
}
