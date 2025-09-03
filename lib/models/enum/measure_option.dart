enum MeasureOption {
  auto,
  manual
}

enum MeasureDetailOption {
  one,
  two,
  three,
  four,
}

String toNamed(MeasureDetailOption m) {
  switch (m) {
    case MeasureDetailOption.one:
      return '1번';
    case MeasureDetailOption.two:
      return '2번';
    case MeasureDetailOption.three:
      return '3번';
    case MeasureDetailOption.four:
      return '4번';
  }
}