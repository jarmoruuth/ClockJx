using Toybox.Application as App;
using Toybox.WatchUi as Ui;

class ClockJxApp extends App.AppBase {

	var cjx;

    function initialize() {
        AppBase.initialize();
    }

    //! Handle app startup
    //! @param state Startup arguments
    public function onStart(state as Dictionary?) as Void {
    }

    //! Handle app shutdown
    //! @param state Shutdown arguments
    public function onStop(state as Dictionary?) as Void {
    }

    //! Return the initial view of your application here
    function getInitialView() {
        cjx = new ClockJxView();
        return [ cjx ];
    }

    //! New app settings have been received so trigger a UI update
    function onSettingsChanged() {
    	cjx.settingsChanged = true;
        Ui.requestUpdate();
    }

}