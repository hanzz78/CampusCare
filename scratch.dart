import 'package:mongo_dart/mongo_dart.dart';

void main() async {
  final connStr = "mongodb+srv://alexandriovegatif24_db_user:DPYqwSuDSiiaEjyT@cluster0.ckpijmr.mongodb.net/aplikasi_pelaporan_terpadu?retryWrites=true&w=majority&safeAtlas=true";
  print("Connecting to: $connStr");
  final db = await Db.create(connStr);
  try {
    await db.open();
    print("✅ Connected successfully!");
    
    final collections = await db.getCollectionNames();
    print("📂 Collections: $collections");
    
    final notificationsCol = db.collection('notifications');
    final list = await notificationsCol.find().toList();
    print("🔔 Notifications Count: ${list.length}");
    for (var doc in list) {
      print(doc);
    }
  } catch (e) {
    print("❌ Error: $e");
  } finally {
    await db.close();
    print("Closed.");
  }
}
