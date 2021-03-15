enum TimeFormat { optionalHours0Minutes0Seconds, optionalHoursMinutes0Seconds }

String getFormattedDuration(Duration duration, {TimeFormat timeFormat}) {
  String hours = '';
  String minutes = '';
  String seconds = '';
  int clockHours = duration.inHours;
  int clockMinutes = duration.inMinutes % 60;
  int clockSeconds = duration.inSeconds % 60;

  switch (timeFormat) {
    case TimeFormat.optionalHours0Minutes0Seconds:
      if (duration == null) return '00:00';
      if (clockHours > 0) hours = '${clockHours.toString()}:';
      minutes = '${clockMinutes < 10 ? '0' : ''}${clockMinutes.toString()}:';
      seconds = '${clockSeconds < 10 ? '0' : ''}${clockSeconds.toString()}';
      break;
    case TimeFormat.optionalHoursMinutes0Seconds:
      if (duration == null) return '0:00';
      if (clockHours > 0) hours = '${clockHours.toString()}:';
      minutes = '${clockMinutes.toString()}:';
      seconds = '${clockSeconds < 10 ? '0' : ''}${clockSeconds.toString()}';
  }

  return '$hours$minutes$seconds';
}
