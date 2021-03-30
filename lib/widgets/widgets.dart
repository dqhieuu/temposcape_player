import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class RoundedImage extends StatelessWidget {
  const RoundedImage({
    Key key,
    @required this.image,
    this.borderRadius,
    this.width,
    this.height,
    this.border,
    this.boxShadow,
  }) : super(key: key);

  final BorderRadius borderRadius;
  final double width;
  final double height;
  final ImageProvider image;
  final BoxBorder border;
  final List<BoxShadow> boxShadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: image,
          fit: BoxFit.cover,
        ),
        borderRadius: borderRadius,
        border: border,
        boxShadow: boxShadow,
      ),
      width: width,
      height: height,
    );
  }
}

class ArtCoverHeader extends StatelessWidget {
  final ImageProvider image;
  final double height;
  final Widget content;

  const ArtCoverHeader(
      {Key key, @required this.height, @required this.image, this.content})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      child: Stack(
        children: [
          ShaderMask(
            shaderCallback: (rect) {
              return LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Colors.black.withOpacity(0.5),
                  Colors.transparent,
                ],
              ).createShader(Rect.fromLTRB(0, 0, rect.width, rect.height));
            },
            blendMode: BlendMode.dstIn,
            child: Image(
              image: image,
              fit: BoxFit.cover,
              width: MediaQuery.of(context).size.width,
              height: height * 0.8,
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: content,
            ),
          )
        ],
      ),
    );
  }
}
