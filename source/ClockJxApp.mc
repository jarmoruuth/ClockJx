using Toybox.Application as App;
using Toybox.WatchUi as Ui;

class ClockJxApp extends App.AppBase {

	var cjx;

    function initialize() {
        AppBase.initialize();
    }

    //! onStart() is called on application start up
    function onStart() {
    }

    //! onStop() is called when your application is exiting
    function onStop() {
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