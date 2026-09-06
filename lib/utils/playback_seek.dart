/// The position to seek to when jumping [deltaSeconds] (positive or negative)
/// from [position], clamped into `[0, total]`.
///
/// A [total] of zero (or negative) means the track length isn't known yet —
/// only the lower bound is enforced then, so an early "+5s" tap never lands
/// at a bogus clamp. Shared by every ±Ns transport button (project-detail
/// player, mobile player).
Duration seekTarget(Duration position, int deltaSeconds, Duration total) {
  var target = position + Duration(seconds: deltaSeconds);
  if (target < Duration.zero) target = Duration.zero;
  if (total > Duration.zero && target > total) target = total;
  return target;
}
