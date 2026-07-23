import '../../models/inventory_item.dart';

/// Best-effort guess of a food category from a typed item name.
/// Cheap keyword match — instant, offline, no API. User can always override.
///
/// Keywords are matched by substring in BOTH English and Chinese, so a name
/// typed (or written by the photo identifier) in Chinese still lands in the
/// right category instead of falling through to "other". Chinese needs no word
/// boundaries, which makes substring matching work well here.
ItemCategory? guessCategory(String name) {
  final n = name.toLowerCase();
  bool has(List<String> keys) => keys.any((k) => n.contains(k));

  // Order matters: more specific first.
  if (has(['牛奶', '鮮乳', '起司', '乳酪', '優格', '奶油', '鮮奶油', '雞蛋', '雞蛋', '蛋'])) {
    return ItemCategory.dairy;
  }
  if (has(['雞肉', '牛肉', '豬肉', '培根', '香腸', '火腿', '牛排', '火雞', '羊肉',
      '魚', '鮭魚', '鮪魚', '蝦', '肉', '絞肉', '海鮮'])) {
    return ItemCategory.meat;
  }
  if (has(['蘋果', '香蕉', '柳橙', '橘子', '葡萄', '莓', '草莓', '瓜', '芒果',
      '桃', '梨', '檸檬', '萊姆', '酪梨', '水果', '奇異果', '鳳梨'])) {
    return ItemCategory.fruit;
  }
  if (has(['生菜', '番茄', '洋蔥', '馬鈴薯', '紅蘿蔔', '菠菜', '辣椒', '青椒',
      '花椰菜', '小黃瓜', '芹菜', '大蒜', '高麗菜', '豆芽', '蔬菜', '青菜',
      '櫛瓜', '菇', '白菜', '蔥'])) {
    return ItemCategory.vegetable;
  }
  if (has(['麵包', '貝果', '餐包', '瑪芬', '可頌', '蛋糕', '糕點', '甜甜圈',
      '吐司', '饅頭'])) {
    return ItemCategory.bakery;
  }
  if (has(['冷凍', '冰淇淋', '冰棒', '水餃'])) return ItemCategory.frozen;
  if (has(['水', '果汁', '汽水', '咖啡', '茶', '啤酒', '葡萄酒', '可樂',
      '飲料', '豆漿'])) {
    return ItemCategory.beverages;
  }
  if (has(['洋芋片', '餅乾', '糖果', '巧克力', '爆米花', '零食', '點心',
      '堅果', '布丁'])) {
    return ItemCategory.snacks;
  }
  if (has(['牙膏', '洗髮', '體香', '乳液', '刮鬍', '肥皂', '沐浴',
      '藥', '維他命', 'ok繃', '牙線', '潤髮', '衛生棉'])) {
    return ItemCategory.personalCare;
  }
  if (has(['洗衣', '廚房紙巾', '衛生紙', '清潔', '漂白', '濕紙巾',
      '垃圾袋', '洗碗', '菜瓜布', '鋁箔', '餐巾'])) {
    return ItemCategory.household;
  }
  if (has(['米', '義大利麵', '麵粉', '糖', '麥片', '豆', '醬', '油',
      '香料', '鹽', '罐頭', '湯', '花生醬', '蜂蜜', '燕麥', '麵條', '泡麵'])) {
    return ItemCategory.pantry;
  }

  if (has(['milk', 'cheese', 'yogurt', 'yoghurt', 'butter', 'cream', 'egg'])) {
    return ItemCategory.dairy;
  }
  if (has(['chicken', 'beef', 'pork', 'bacon', 'sausage', 'ham', 'steak',
      'turkey', 'lamb', 'fish', 'salmon', 'tuna', 'shrimp', 'meat', 'mince'])) {
    return ItemCategory.meat;
  }
  if (has(['apple', 'banana', 'orange', 'grape', 'berry', 'strawberr', 'melon',
      'mango', 'peach', 'pear', 'lemon', 'lime', 'avocado', 'fruit', 'kiwi'])) {
    return ItemCategory.fruit;
  }
  if (has(['lettuce', 'tomato', 'onion', 'potato', 'carrot', 'spinach', 'pepper',
      'broccoli', 'cucumber', 'celery', 'garlic', 'kale', 'cabbage', 'bean sprout',
      'vegetable', 'veggie', 'zucchini', 'mushroom'])) {
    return ItemCategory.vegetable;
  }
  if (has(['bread', 'bagel', 'bun', 'roll', 'muffin', 'croissant', 'tortilla',
      'cake', 'pastry', 'donut', 'baguette'])) {
    return ItemCategory.bakery;
  }
  if (has(['frozen', 'ice cream', 'popsicle'])) return ItemCategory.frozen;
  if (has(['water', 'juice', 'soda', 'coffee', 'tea', 'beer', 'wine', 'cola',
      'lemonade', 'drink', 'kombucha'])) {
    return ItemCategory.beverages;
  }
  if (has(['chip', 'cookie', 'candy', 'chocolate', 'cracker', 'popcorn', 'snack',
      'pretzel', 'granola bar', 'nuts'])) {
    return ItemCategory.snacks;
  }
  if (has(['toothpaste', 'shampoo', 'deodorant', 'lotion', 'razor', 'soap',
      'medicine', 'vitamin', 'bandage', 'floss', 'conditioner'])) {
    return ItemCategory.personalCare;
  }
  if (has(['detergent', 'paper towel', 'toilet paper', 'cleaner', 'bleach', 'wipe',
      'trash bag', 'laundry', 'dish soap', 'sponge', 'foil', 'napkin'])) {
    return ItemCategory.household;
  }
  if (has(['rice', 'pasta', 'flour', 'sugar', 'cereal', 'beans', 'sauce', 'oil',
      'spice', 'salt', 'canned', 'soup', 'peanut butter', 'honey', 'oat', 'noodle'])) {
    return ItemCategory.pantry;
  }
  return null; // no confident guess
}
