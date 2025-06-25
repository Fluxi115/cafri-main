import 'package:cloud_firestore/cloud_firestore.dart';

class FolioService {
  static const String _collection = 'config';
  static const String _document = 'folio';
  static const String _field = 'valor';
  static const int _defaultFolio = 2140669;

  /// Obtiene el siguiente folio disponible desde Firestore (NO seguro para concurrencia).
  static Future<int> getNextFolio() async {
    final doc = await FirebaseFirestore.instance
        .collection(_collection)
        .doc(_document)
        .get();

    final ultimoFolio = doc.data()?[_field] as int?;
    return (ultimoFolio ?? _defaultFolio) + 1;
  }

  /// Actualiza el folio en Firestore después de generar un PDF (NO seguro para concurrencia).
  static Future<void> updateFolio(int nuevoFolio) async {
    await FirebaseFirestore.instance.collection(_collection).doc(_document).set(
      {_field: nuevoFolio},
      SetOptions(merge: true),
    );
  }

  /// Obtiene y actualiza el folio de manera atómica usando una transacción.
  /// Garantiza que cada llamada concurrente reciba un folio único y secuencial.
  static Future<int> getAndUpdateFolio() async {
    return FirebaseFirestore.instance.runTransaction((transaction) async {
      final docRef = FirebaseFirestore.instance
          .collection(_collection)
          .doc(_document);
      final snapshot = await transaction.get(docRef);
      final ultimoFolio = snapshot.data()?[_field] as int? ?? _defaultFolio;
      final nuevoFolio = ultimoFolio + 1;
      transaction.set(docRef, {_field: nuevoFolio}, SetOptions(merge: true));
      return nuevoFolio;
    });
  }
}
