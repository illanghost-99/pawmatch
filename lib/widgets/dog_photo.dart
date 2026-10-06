import 'package:flutter/material.dart';

/// Small webp of a Supabase photo. The original camera files are about 2 MB,
/// which is why the cards stayed blank. This is the same picture at card size.
String photoUrl(String url, {int width = 900}) {
  const from = '/storage/v1/object/public/';
  if (!url.contains(from)) return url;
  final next = url.replaceFirst(from, '/storage/v1/render/image/public/');
  final join = next.contains('?') ? '&' : '?';
  return '$next${join}width=$width&quality=62&format=webp&resize=contain';
}

class DogPhoto extends StatelessWidget {
  const DogPhoto({super.key, required this.url, this.memWidth});
  final String url;
  final int? memWidth;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return const ColoredBox(color: Color(0xFFE7D3C4));
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final w = (memWidth ?? (MediaQuery.sizeOf(context).width * dpr).round()).clamp(480, 1200).toInt();
    return Image.network(
      photoUrl(url, width: w),
      fit: BoxFit.cover,
      gaplessPlayback: true,
      filterQuality: FilterQuality.low,
      cacheWidth: w,
      errorBuilder: (_, __, ___) => Image.network(
        url,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        cacheWidth: w,
        errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFFE7D3C4)),
      ),
    );
  }
}

void warmDogPhotos(BuildContext context, Iterable<String> urls) {
  final dpr = MediaQuery.devicePixelRatioOf(context);
  final w = (MediaQuery.sizeOf(context).width * dpr).round().clamp(480, 1200).toInt();
  for (final url in urls) {
    if (!url.startsWith('http')) continue;
    precacheImage(ResizeImage(NetworkImage(photoUrl(url, width: w)), width: w), context);
  }
}
