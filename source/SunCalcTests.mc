import Toybox.Lang;
import Toybox.Position;
import Toybox.Test;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Weather;

//! Simulator-only regression tests; omitted from normal and release builds.
//! `nextEvent` now delegates the sunrise equation itself to Garmin's
//! `Weather.getSunrise`/`getSunset` (see SunCalc's doc comment), so these
//! cover the part still owned by this module: picking the soonest event
//! across the day boundary, and converting it to local time.
(:test)
module SunCalcTests {

    // 21 June 2026, noon UTC - a day either side of the northern-hemisphere
    // summer solstice, so long-day/no-set and short-day/no-rise cases are
    // unambiguous at moderately high latitudes.
    const JUNE_21_NOON = 1782043200;

    // London changes clocks at 01:00 UTC on these dates. At midnight,
    // sunrise is still ahead. Its displayed time must remain unchanged
    // across the transition, using the watch's timezone rather than GPS.
    (:test)
    function sunriseAcrossSpringClockChange(logger as Test.Logger) as Boolean {
        return londonSunrise(1774742400, logger);
    }

    (:test)
    function sunriseAcrossAutumnClockChange(logger as Test.Logger) as Boolean {
        return londonSunrise(1792886400, logger);
    }

    (:test)
    function sunriseUsesWatchTimezone(logger as Test.Logger) as Boolean {
        // At UTC midnight, sunrise is next at both locations. The result
        // must use the watch's timezone, regardless of the GPS longitude.
        var now = new Time.Moment(JUNE_21_NOON + 12 * 3600);
        var longitudes = [30.0d, -30.0d];
        for (var i = 0; i < longitudes.size(); i++) {
            var position = new Position.Location({
                :latitude => 0.0d, :longitude => longitudes[i], :format => :degrees
            });
            var sunrise = Weather.getSunrise(position, now);
            if (sunrise == null || sunrise.value() <= now.value()) { return false; }
            if (SunCalc.nextEvent(now, position) != localMinute(sunrise)) { return false; }
        }
        return true;
    }

    function londonSunrise(timestamp as Number, logger as Test.Logger) as Boolean {
        var now = new Time.Moment(timestamp);
        var position = new Position.Location({
            :latitude => 51.5074d, :longitude => -0.1278d, :format => :degrees
        });
        var sunrise = Weather.getSunrise(position, now);
        if (sunrise == null) { return false; }
        if (sunrise.value() <= timestamp + 3600) { return false; }
        var expected = localMinute(sunrise);
        var actual = SunCalc.nextEvent(now, position);
        logger.debug("Sunrise across clock change: expected=" + expected + ", actual=" + actual);
        if (actual != expected) { return false; }
        var afterChange = new Time.Moment(timestamp + 3600);
        return SunCalc.nextEvent(afterChange, position) == expected;
    }

    function localMinute(moment as Time.Moment) as Number {
        var local = Gregorian.info(moment, Time.FORMAT_SHORT);
        return local.hour * 60 + local.min;
    }

    (:test)
    function advanceAfterSunset(logger as Test.Logger) as Boolean {
        // Reykjavik-ish: long summer evenings, sunset well after 22:00 local.
        var location = new Position.Location({
            :latitude => 64.1d, :longitude => -21.9d, :format => :degrees
        });
        var noon = new Time.Moment(JUNE_21_NOON);
        var sunset = Weather.getSunset(location, noon);
        if (sunset == null) { return false; }

        var justBefore = SunCalc.nextEvent(new Time.Moment(sunset.value() - 1), location);
        var atSunset = SunCalc.nextEvent(sunset, location);
        var justAfter = SunCalc.nextEvent(new Time.Moment(sunset.value() + 1), location);
        logger.debug("Just before/at/after sunset: " + justBefore + "/" + atSunset + "/" + justAfter);

        if (atSunset == null || justAfter == null) { return false; }
        // Just before sunset, the next event is still that sunset.
        if (justBefore != localMinute(sunset)) { return false; }
        // At and after sunset, the next event has moved on to the following sunrise.
        return justAfter == atSunset;
    }

    (:test)
    function polarDayHasNoEvent(logger as Test.Logger) as Boolean {
        // Well inside the Arctic Circle at the solstice: the sun does not set.
        var location = new Position.Location({
            :latitude => 78.0d, :longitude => 15.0d, :format => :degrees
        });
        return SunCalc.nextEvent(new Time.Moment(JUNE_21_NOON), location) == null;
    }

    (:test)
    function polarNightHasNoEvent(logger as Test.Logger) as Boolean {
        // Same latitude, opposite hemisphere, same moment: the sun does not rise.
        var location = new Position.Location({
            :latitude => -78.0d, :longitude => 15.0d, :format => :degrees
        });
        return SunCalc.nextEvent(new Time.Moment(JUNE_21_NOON), location) == null;
    }
}
