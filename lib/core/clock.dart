/// Injectable time source so tests can fake the date.
class Clock {
  const Clock();

  DateTime now() => DateTime.now();
}

class FixedClock extends Clock {
  FixedClock(this.current);

  DateTime current;

  @override
  DateTime now() => current;
}
