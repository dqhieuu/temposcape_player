import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:temposcape_player/utils/duration_to_string.dart';

import '../constants/constants.dart' as Constants;

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

class SongListTile extends StatelessWidget {
  final MediaItem song;
  final GestureTapCallback onTap;
  final bool selected;
  final bool draggable;

  const SongListTile({
    Key key,
    this.song,
    this.onTap,
    this.selected = false,
    this.draggable = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: Key(song.id),
      leading: RoundedImage(
        image: song?.artUri != null
            ? ((song?.extras ?? {})['isOnline'] ?? false
                ? CachedNetworkImageProvider(song.artUri)
                : Image.file(File(Uri.parse(song.artUri).path)).image)
            : AssetImage(Constants.defaultImagePath),
        width: 50,
        height: 50,
      ),
      onTap: onTap,
      title: Text(
        song.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        song.artist,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      selected: selected,
      trailing: Container(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (song.duration != null)
              Text(
                getFormattedDuration(
                  song.duration,
                  timeFormat: TimeFormat.optionalHoursMinutes0Seconds,
                ),
              ),
            if (draggable)
              Container(
                child: Icon(
                  Icons.drag_handle,
                  color: Theme.of(context).textTheme.bodyText1.color,
                  size: 36,
                ),
                padding: EdgeInsets.only(left: 20.0),
              ),
          ],
        ),
      ),
    );
  }
}

class MyGridTile extends StatelessWidget {
  final Widget child;
  final GestureTapCallback onTap;
  const MyGridTile({
    this.child,
    this.onTap,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      GridTile(child: child),
      Positioned.fill(
          child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap ?? () {},
        ),
      )),
    ]);
  }
}

class NullTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Icon(
        Icons.not_interested,
        size: 40,
      ),
      Text('There\'s nothing here!'),
      RichText(
          text: TextSpan(children: <TextSpan>[
        TextSpan(text: 'Consider adding some music to your music folder, or '),
        TextSpan(
          text: 'download some songs here',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ]))
    ]);
  }
}
