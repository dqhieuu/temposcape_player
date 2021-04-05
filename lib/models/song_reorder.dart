class SongReorder {
  int oldIndex;
  int newIndex;

  SongReorder(this.oldIndex, this.newIndex);
  SongReorder.fromMap(Map<dynamic, dynamic> map) {
    oldIndex = map['oldIndex'];
    newIndex = map['newIndex'];
  }
}
