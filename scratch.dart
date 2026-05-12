import 'package:mongo_dart/mongo_dart.dart';

void main() async {
  Db db = Db("mongodb://dummy");
  try {
    await db.pingCommand();
    print('pingCommand works');
  } catch (e) {
    print('error pinging: $e');
  }
}
