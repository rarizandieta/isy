import 'package:flutter/material.dart';

import '../models/mini_store.dart';
import '../models/store_product.dart';

/// Maneja las Mini Tiendas y sus productos (en memoria).
class MiniStoreController extends ChangeNotifier {
  final List<MiniStore> _stores = _seedStores();
  final List<StoreProduct> _products = _seedProducts();
  int _seq = 0;

  // --- Lecturas ---
  MiniStore? storeForProfile(String profileId) {
    for (final s in _stores) {
      if (s.sellerProfileId == profileId) return s;
    }
    return null;
  }

  MiniStore? storeById(String id) {
    for (final s in _stores) {
      if (s.id == id) return s;
    }
    return null;
  }

  bool hasStore(String profileId) => storeForProfile(profileId) != null;

  List<StoreProduct> productsOf(String storeId) {
    final list = _products.where((p) => p.storeId == storeId).toList();
    list.sort((a, b) {
      if (a.isFeatured != b.isFeatured) return a.isFeatured ? -1 : 1;
      return a.name.compareTo(b.name);
    });
    return list;
  }

  List<StoreProduct> productsOfSection(String storeId, String? sectionId) =>
      productsOf(storeId).where((p) => p.sectionId == sectionId).toList();

  List<StoreProduct> featured(String storeId) =>
      productsOf(storeId).where((p) => p.isFeatured).toList();

  // --- Tienda ---
  MiniStore createStore(MiniStore store) {
    _stores.add(store);
    notifyListeners();
    return store;
  }

  void updateStore(MiniStore store) {
    final i = _stores.indexWhere((s) => s.id == store.id);
    if (i < 0) return;
    _stores[i] = store;
    notifyListeners();
  }

  void toggleOpen(String storeId) {
    final i = _stores.indexWhere((s) => s.id == storeId);
    if (i < 0) return;
    _stores[i] = _stores[i].copyWith(isOpen: !_stores[i].isOpen);
    notifyListeners();
  }

  String newStoreId() => 's_${DateTime.now().microsecondsSinceEpoch}';

  // --- Secciones ---
  StoreSection addSection(String storeId, String name) {
    final i = _stores.indexWhere((s) => s.id == storeId);
    final section =
        StoreSection(id: 'sec_${_seq++}_${DateTime.now().millisecond}', name: name);
    if (i >= 0) {
      _stores[i] = _stores[i]
          .copyWith(sections: [..._stores[i].sections, section]);
      notifyListeners();
    }
    return section;
  }

  void removeSection(String storeId, String sectionId) {
    final i = _stores.indexWhere((s) => s.id == storeId);
    if (i < 0) return;
    _stores[i] = _stores[i].copyWith(
      sections:
          _stores[i].sections.where((s) => s.id != sectionId).toList(),
    );
    // Los productos de esa sección quedan sin sección.
    for (var j = 0; j < _products.length; j++) {
      if (_products[j].storeId == storeId &&
          _products[j].sectionId == sectionId) {
        _products[j] = _products[j].copyWith(sectionId: null);
      }
    }
    notifyListeners();
  }

  // --- Productos ---
  StoreProduct addProduct(StoreProduct product) {
    _products.add(product);
    notifyListeners();
    return product;
  }

  void updateProduct(StoreProduct product) {
    final i = _products.indexWhere((p) => p.id == product.id);
    if (i < 0) return;
    _products[i] = product;
    notifyListeners();
  }

  void deleteProduct(String productId) {
    _products.removeWhere((p) => p.id == productId);
    notifyListeners();
  }

  String newProductId() => 'prod_${DateTime.now().microsecondsSinceEpoch}';

  // --- Semillas ---
  static List<MiniStore> _seedStores() => [
        const MiniStore(
          id: 's_esquina',
          sellerProfileId: 'p_esquina',
          name: 'Tienda La Esquina',
          tagline: 'Lo de siempre, fresquecito',
          description:
              'Abarrotes, café de especialidad y comida del día. Pedidos por chat.',
          category: 'Abarrotes',
          coverSeed: 14,
          accentColor: 0xFFEF6C00,
          isOpen: true,
          schedule: 'Lun–Sáb · 7:00–19:00',
          zone: 'Zona 1 · entregas a 3 km',
          delivery: {DeliveryOption.pickup, DeliveryOption.delivery},
          payments: {PaymentMethod.cash, PaymentMethod.transfer},
          sections: [
            StoreSection(id: 'sec_dia', name: 'Del día'),
            StoreSection(id: 'sec_cafe', name: 'Café'),
            StoreSection(id: 'sec_aba', name: 'Abarrotes'),
          ],
        ),
        const MiniStore(
          id: 's_dulce',
          sellerProfileId: 'ext_dulcehogar',
          name: 'Dulce Hogar',
          tagline: 'Detalles que hacen hogar',
          description: 'Decoración y textiles hechos a mano.',
          category: 'Hogar',
          coverSeed: 27,
          accentColor: 0xFF00897B,
          isOpen: false,
          schedule: 'Mar–Dom · 10:00–20:00',
          zone: 'Envíos a todo el país',
          delivery: {DeliveryOption.shipping, DeliveryOption.pickup},
          payments: {PaymentMethod.cash, PaymentMethod.card, PaymentMethod.transfer},
          sections: [
            StoreSection(id: 'sec_deco', name: 'Decoración'),
            StoreSection(id: 'sec_tex', name: 'Textiles'),
          ],
        ),
      ];

  static List<StoreProduct> _seedProducts() => [
        // Tienda La Esquina
        const StoreProduct(
          id: 'p_tamal',
          storeId: 's_esquina',
          sectionId: 'sec_dia',
          name: 'Tamales de pollo',
          description: 'Masa suave, recado rojo. Por encargo del día.',
          price: 2.50,
          unit: 'pieza',
          imageSeed: 3,
          stock: StockStatus.madeToOrder,
          isFeatured: true,
          tags: ['Popular', 'Hecho a mano'],
        ),
        const StoreProduct(
          id: 'p_cafe',
          storeId: 's_esquina',
          sectionId: 'sec_cafe',
          name: 'Café de especialidad 250g',
          description: 'Tostado artesanal, molido o en grano.',
          price: 8.50,
          offerPrice: 6.90,
          unit: 'bolsa',
          imageSeed: 8,
          isFeatured: true,
          tags: ['Oferta'],
        ),
        const StoreProduct(
          id: 'p_frijol',
          storeId: 's_esquina',
          sectionId: 'sec_aba',
          name: 'Frijol negro',
          description: 'Grano selecto.',
          price: 1.80,
          unit: 'libra',
          imageSeed: 15,
        ),
        const StoreProduct(
          id: 'p_huevo',
          storeId: 's_esquina',
          sectionId: 'sec_aba',
          name: 'Huevos de granja',
          description: 'Frescos, del día.',
          price: 2.20,
          unit: 'docena',
          imageSeed: 21,
        ),
        const StoreProduct(
          id: 'p_verdura',
          storeId: 's_esquina',
          sectionId: 'sec_dia',
          name: 'Manojo de hierbas',
          description: 'Cilantro, perejil o hierbabuena.',
          price: 1.00,
          unit: 'manojo',
          imageSeed: 33,
          stock: StockStatus.soldOut,
          tags: ['Orgánico'],
        ),
        // Dulce Hogar
        const StoreProduct(
          id: 'p_velas',
          storeId: 's_dulce',
          sectionId: 'sec_deco',
          name: 'Set de velas aromáticas',
          description: 'Lavanda, vainilla y cítricos. Cera de soya.',
          price: 12.50,
          unit: 'caja',
          imageSeed: 41,
          isFeatured: true,
          tags: ['Hecho a mano'],
        ),
        const StoreProduct(
          id: 'p_sabanas',
          storeId: 's_dulce',
          sectionId: 'sec_tex',
          name: 'Juego de sábanas premium',
          description: 'Algodón 400 hilos.',
          price: 34.90,
          unit: 'pieza',
          imageSeed: 52,
        ),
      ];
}
