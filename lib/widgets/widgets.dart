import 'package:flutter/widgets.dart';

class RoundedImage extends StatelessWidget {
  const RoundedImage(
      {Key key,
      @required this.image,
      this.borderRadius,
      this.width,
      this.height,
      this.border})
      : super(key: key);

  final BorderRadius borderRadius;
  final double width;
  final double height;
  final ImageProvider image;
  final BoxBorder border;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: image,
        ),
        borderRadius: borderRadius,
        border: border,
      ),
      width: width,
      height: height,
    );
  }
}
