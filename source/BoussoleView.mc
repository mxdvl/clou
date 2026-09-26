import Toybox.ActivityMonitor;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Position;
import Toybox.System;
import Toybox.Time;
import Toybox.WatchUi;

//! Watch face made of concentric rings. Each update is three steps:
//!
//!   1. read the device (time, steps, location) - the only impure inputs
//!   2. build a scene: pure functions turn those values into `Shapes`
//!        TimeRing   near the rim: the current time as a `ClockArc`, with
//!                   hour points and numerals
//!        SunRing    the next sunrise or sunset as a `ClockArc`
//!        StepsRing  progress towards the step goal, bar anchored at XII
//!   3. `Render` draws the scene
//!
//! While asleep on a device that requires AMOLED burn-in protection,
//! `onUpdate` builds the scene from `TimeRing.aodScene` instead of
//! `fullScene` - see there for what that drops.
class BoussoleView extends WatchUi.WatchFace {

    private const DEFAULT_STEP_GOAL = 10000;

    private var sleeping as Boolean = false;

    function initialize() {
        WatchFace.initialize();
    }

    //! No fixed drawables: Layout derives all geometry from the screen size
    //! fresh on every onUpdate instead.
    function onLayout(dc as Graphics.Dc) as Void {
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var clock = System.getClockTime();
        var minuteOfDay = clock.hour * 60 + clock.min;
        var lowPower = sleeping && burnInProtected();

        // Always redraw the whole screen: several real devices clear the Dc
        // before calling onUpdate (the simulator doesn't), so skipping this
        // when nothing appears to have changed can leave the display blank.
        var layout = new Layout(dc.getWidth(), dc.getHeight());
        var scene = lowPower
            ? TimeRing.aodScene(layout, minuteOfDay)
            : fullScene(layout, minuteOfDay);

        Render.draw(dc, scene);
    }

    //! The normal scene: steps, the next sun event, and the current time.
    private function fullScene(
        layout as Layout, minuteOfDay as Number
    ) as Array<Shapes.Shape> {
        var activity = ActivityMonitor.getInfo();
        var location = Position.getInfo().position;
        var scene = StepsRing.scene(layout, orZero(activity.steps), stepGoal(activity.stepGoal));
        scene.addAll(SunRing.scene(layout, nextSunEvent(location)));
        scene.addAll(TimeRing.scene(layout, minuteOfDay));
        return scene;
    }

    //! Tracks power state for onUpdate's Always-On branch. requestUpdate()
    //! forces an immediate redraw in the new state, rather than waiting for
    //! the next scheduled tick.
    function onEnterSleep() as Void {
        sleeping = true;
        WatchUi.requestUpdate();
    }

    //! Tracks power state for onUpdate's Always-On branch. requestUpdate()
    //! forces an immediate redraw in the new state, rather than waiting for
    //! the next scheduled tick.
    function onExitSleep() as Void {
        sleeping = false;
        WatchUi.requestUpdate();
    }

    //! Whether low-power redraws on this device must stay within the AMOLED
    //! burn-in budget (false on devices without Always-On, which just turn
    //! their screen off instead of calling `onUpdate` while asleep).
    private function burnInProtected() as Boolean {
        var settings = System.getDeviceSettings();
        return (settings has :requiresBurnInProtection) && settings.requiresBurnInProtection;
    }

    private function orZero(value as Number?) as Number {
        return value != null ? value : 0;
    }

    private function stepGoal(goal as Number?) as Number {
        return (goal != null && goal > 0) ? goal : DEFAULT_STEP_GOAL;
    }

    //! Local minute of the next sunrise or sunset, or null without a known
    //! location.
    private function nextSunEvent(location as Position.Location?) as Number? {
        if (location == null) {
            return null;
        }
        return SunCalc.nextEvent(Time.now(), location);
    }
}
