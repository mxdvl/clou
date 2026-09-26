import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

//! Application entry point for the Clou watch face.
class ClouApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    //! Nothing to restore: every update rebuilds the scene from the device,
    //! so there's no state to carry between launches.
    function onStart(state as Dictionary?) as Void {
    }

    //! Nothing to persist: every update rebuilds the scene from the device,
    //! so there's no state to carry between launches.
    function onStop(state as Dictionary?) as Void {
    }

    //! Return the initial view for the watch face. A watch face has no
    //! input delegate, so we return just the view.
    function getInitialView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] {
        return [ new ClouView() ];
    }
}
