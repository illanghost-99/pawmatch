import '../models.dart';

class WalkCircle {
  WalkCircle({
    required this.id,
    required this.name,
    List<String>? members,
    List<ChatLine>? messages,
    this.walkPlan = '',
    this.owner = true,
  })  : members = members ?? ['Du'],
        messages = messages ?? [];
  final String id;
  String name;
  String walkPlan;
  bool owner;
  List<String> members;
  List<ChatLine> messages;
}
