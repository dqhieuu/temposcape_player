import 'dart:core';
import 'dart:typed_data';

import 'package:hive/hive.dart';

@HiveType(typeId: 1)
class ArtistCache {
  static final hiveBox = 'cachedArtists';

  ArtistCache({this.bio, this.bioFull, this.imageCache});

  @HiveField(0)
  String bio;
  @HiveField(1)
  String bioFull;
  @HiveField(2)
  Uint8List imageCache;
}

class ArtistCacheAdapter extends TypeAdapter<ArtistCache> {
  @override
  final int typeId = 1;

  @override
  ArtistCache read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ArtistCache()
      ..bio = fields[0] as String
      ..bioFull = fields[1] as String
      ..imageCache = fields[2] as Uint8List;
  }

  @override
  void write(BinaryWriter writer, ArtistCache obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.bio)
      ..writeByte(1)
      ..write(obj.bioFull)
      ..writeByte(2)
      ..write(obj.imageCache);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArtistCacheAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
