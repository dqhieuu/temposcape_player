/// A discrete value that's a text representation of a duration.
///
/// It separates a duration into a component time quantity,
/// in which there's a most significant unit.
///
/// Syntax: `[optional|0|{none}]Unit`. Where:
///
/// * optional: quantity of unit isn't displayed if quantity = 0
/// * {none}: quantity of unit is displayed as 0 if quantity = 0, otherwise {quantity}
/// * 0 : pads an additional zero if quantity < 10
enum TimeFormat { optionalHours0Minutes0Seconds, optionalHoursMinutes0Seconds }

/// Display a duration as time intervals, separated by a colon.
///
/// `timeFormat`: the format of duration to be displayed
String getFormattedDuration(Duration duration,
    {TimeFormat timeFormat = TimeFormat.optionalHoursMinutes0Seconds}) {
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
