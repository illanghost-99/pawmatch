class ChatLine {
  const ChatLine(this.fromMe, this.text, {this.id = '', this.recalled = false});
  final bool fromMe;
  final String text;
  final String id;
  final bool recalled;
}
