using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Lang as Lang;
using Toybox.Application as App;
using Toybox.Time as Time;
using Toybox.Time.Gregorian as Calendar;
using Toybox.Activity as Act;
using Toybox.ActivityMonitor as ActMonitor;

// ----------------------------------------------------------------
// Credits
// ----------------------------------------------------------------
//
// I have used the following sources for the development of this watch face:
//	- Garmid SDK samples
// 	- Very nice blog post from Aaron Boman 
//		http://blog.aaronboman.com/programming/connectiq/2014/11/11/making-an-analog-watch-face/
//	- Several informative posts in Connect IQ forums
//		Custom fonts: https://forums.garmin.com/showthread.php?338498-Using-Custom-Fonts
//		Many others I cannot find any more
//	- Some other sources I cannot remember any more
//  - I could not get icon fonts working but borrowed two icons as bitmap from
//    icon fonts created by Franco Trimboli
//      https://github.com/sunpazed/garmin-iconfonts
//  - Watch face from claudiocandio provided some useful tips for reading heart rate that I could not
//    find from the docs
//      https://github.com/claudiocandio/Garmin-WatchCLC
//
// This is updated from original Fenix 3 version. I now have Vivoactive 4.
//
// ----------------------------------------------------------------
// How to build and other info:
// ----------------------------------------------------------------
//
// https://developer.garmin.com/connect-iq/connect-iq-basics/getting-started/
//
// ----------------------------------------------------------------
// Misc notes
// ----------------------------------------------------------------
//
// fonts
// -----
// 
// use BMFont, set the "File format Texture" to "png"
// 
// resources.xml file:
// <fonts>
// <font id="id_konqa32_hd" filename="fonts/konqa32-hd.fnt" filter="0123456789"/>
// </fonts>
// 
// in initialize(), have something like
// 
// bigNumFont=Ui.loadResource(Rez.Fonts.id_bignum);
// 
// sample for the layout
// <label id="TimeLabel" x="113" y="63" font="@Fonts.font" justification="Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER" />
// 
// add the font to the resources.xml file and add "font=@Fonts.id_konqa32_hd" 
// to layout file label definitions
//

class ClockJxView extends Ui.WatchFace {

	var settingsChanged = true;
	var fgcolor;
	var digital_time_color;
	var bgcolor;
	var hash_color;
	var analog_number_font;
	var battery_limit_low = 25;
	var battery_limit_critical = 10;
	var battery_background_color = 0x000000;
	var background;
	var image_num = 0;
	var altitude_mode = false;
	var AnalogUse24hFormat = true;
	var digital_clock = true;
	var steps = false;
	var steps_image = null;
	var heart_rate = false;
	var heart_rate_image = null;
	var screen_shape;
	var bgcolor_with_image;
	var use_bgcolor_with_image = true;
	var digital_clock_font;
	var use_system_font = false;
	var dualtime = false;
	var dualtimeTZ = 0;
	var dualtimeDST = -1;	// current DST
	var bluetooth_ok_image = null;
	var bluetooth_error_image = null;
	var bluetooth_status = true;
	var show_bluetooth_status = true;
	var use_large_dualtime_font = false;
	var new_image_num = 0;
	var new_use_system_font = false;
	var demo = false;	// DEMO
	
	var ColorsArr = [ [0, 0x000000], [1, 0x555555], [2, 0xAAAAAA], [3, 0x0000FF], [4, 0x00AA00], [5, 0x00FF00] , 
					  [6, 0xAA0000], [7, 0xFF5500], [8, 0xFFAA00], [9, 0xFFFFFF], [-1, -1]];
	
	function checkBool(b, def) {
		if (b == null || (b != true && b != false)) {
			return def;
		} 
		return b;
	}
	
	function checkNumber(n, def) {
		if (n == null) {
			return def;
		} 
		return n.toNumber();
	}
	
	function checkColor(c, defcolor) {
		var n;
		if (c == null) {
			return defcolor;
		}
		n = c.toNumber();
		for (var i = 0; ColorsArr[i][0] != -1; i = i + 1) {
			if (n == ColorsArr[i][0] || n == ColorsArr[i][1]) {
				return ColorsArr[i][1];
			}
		}
		return defcolor;
	}
	
	function getSettings() {
		
		if (!settingsChanged) {
			return;
		}
		settingsChanged = false;
		
		demo = checkBool(App.getApp().getProperty("DemoMode"), demo);
		
		digital_clock = checkBool(App.getApp().getProperty("DigitalClock"), digital_clock);
		AnalogUse24hFormat = checkBool(App.getApp().getProperty("AnalogUse24hFormat"), AnalogUse24hFormat);
		altitude_mode = checkBool(App.getApp().getProperty("MountainMode"), altitude_mode);
		steps = checkBool(App.getApp().getProperty("Steps"), steps);
		heart_rate = checkBool(App.getApp().getProperty("HeartRate"), heart_rate);
		dualtime = checkBool(App.getApp().getProperty("UseDualTime"), dualtime);
		dualtimeTZ = checkNumber(App.getApp().getProperty("DualTimeTZ"), dualtimeTZ);
		dualtimeDST = checkNumber(App.getApp().getProperty("DualTimeDST"), dualtimeDST);

		new_use_system_font = checkBool(App.getApp().getProperty("UseSystemFont"), new_use_system_font);
		if (dualtime && screen_shape != Sys.SCREEN_SHAPE_ROUND) {
			//new_use_system_font = true;
		}
		if (digital_clock && new_use_system_font != use_system_font) {
			use_system_font = new_use_system_font;
			digital_clock_font = null;
			if (use_system_font) {
				digital_clock_font = Gfx.FONT_NUMBER_THAI_HOT;
			} else {
				digital_clock_font = Ui.loadResource(Rez.Fonts.timefont);    			
			}
		}
		//if (use_system_font && steps && dualtime && digital_clock) {
		//	digital_clock_font = Gfx.FONT_NUMBER_THAI_HOT;
		//}
		new_image_num = checkNumber(App.getApp().getProperty("BackgroundImage"), new_image_num);
		if (new_image_num != image_num && new_image_num != 0) {
			background = null;
			if (new_image_num == 1) {
	        	background = Ui.loadResource(Rez.Drawables.bgimg1);
        	} else if (new_image_num == 2) {
       			background = Ui.loadResource(Rez.Drawables.bgimg2);
        	} else if (new_image_num == 3) {
       			background = Ui.loadResource(Rez.Drawables.bgimg3);
        	} else if (new_image_num == 4) {
       			background = Ui.loadResource(Rez.Drawables.bgimg4);
        	} else if (new_image_num == 5) {
       			background = Ui.loadResource(Rez.Drawables.bgimg5);
        	} else if (new_image_num == 6) {
       			background = Ui.loadResource(Rez.Drawables.bgimg6);
        	} else if (new_image_num == 7) {
       			background = Ui.loadResource(Rez.Drawables.bgimg7);       			
        	} else {
       			new_image_num = 0;
        	}			
    	}
    	image_num = new_image_num;
       	digital_time_color = checkColor(App.getApp().getProperty("TimeColor"), Gfx.COLOR_WHITE);
       	fgcolor = checkColor(App.getApp().getProperty("ForegroundColor"), Gfx.COLOR_WHITE);
       	bgcolor = checkColor(App.getApp().getProperty("BackgroundColor"), Gfx.COLOR_BLACK);
    	if (fgcolor == Gfx.COLOR_WHITE && bgcolor == Gfx.COLOR_BLACK && image_num == 0) {
    		hash_color = Gfx.COLOR_LT_GRAY;
    	} else {
    		hash_color = fgcolor;
    	}
    	if (checkBool(App.getApp().getProperty("UseBackgroundColorWithImage"), use_bgcolor_with_image)) {
    		bgcolor_with_image = bgcolor;
    		use_bgcolor_with_image = true;
    	} else {
    		bgcolor_with_image = Gfx.COLOR_TRANSPARENT;
    		use_bgcolor_with_image = false;
    	}
    	show_bluetooth_status = checkBool(App.getApp().getProperty("UseBluetoothIcon"), show_bluetooth_status);
    	if (show_bluetooth_status) {
	    	if (demo) {
	    		bluetooth_status = !bluetooth_status;
	    	}
			bluetooth_ok_image = Ui.loadResource(Rez.Drawables.bluetooth_ok);
			bluetooth_error_image = Ui.loadResource(Rez.Drawables.bluetooth_error);
	    }
		if (steps) {
			steps_image = Ui.loadResource(Rez.Drawables.steps);
		}
		if (heart_rate) {
			heart_rate_image = Ui.loadResource(Rez.Drawables.bpm);
		}
	    use_large_dualtime_font = checkBool(App.getApp().getProperty("UseLargeDualTimeFont"), use_large_dualtime_font);
	    battery_limit_low = checkNumber(App.getApp().getProperty("BatteryWarningLimitLow"), battery_limit_low);
	    battery_limit_critical = checkNumber(App.getApp().getProperty("BatteryWarningLimitCritical"), battery_limit_critical);
	    battery_background_color = checkNumber(App.getApp().getProperty("BatteryBackgroundColor"), Gfx.COLOR_TRANSPARENT);
	    if (battery_background_color == 0x123456) {
	    	// None
	    	battery_background_color = Gfx.COLOR_TRANSPARENT;
	    } else {
	    	battery_background_color = checkColor(battery_background_color, Gfx.COLOR_TRANSPARENT);
	    }
	}

    function initialize() {
    	digital_clock_font = Ui.loadResource(Rez.Fonts.timefont);
    	//digital_clock_font = Gfx.FONT_NUMBER_THAI_HOT;
        WatchFace.initialize();
        screen_shape = Sys.getDeviceSettings().screenShape;
        bluetooth_status = true;
    }

    //! Load your resources here
    function onLayout(dc) {
    }

    //! Called when this View is brought to the foreground. Restore
    //! the state of this View and prepare it to be shown. This includes
    //! loading resources into memory.
    function onShow() {
    }

    //! Draw the watch hand
    //! @param dc Device Context to Draw
    //! @param angle Angle to draw the watch hand
    //! @param length Length of the watch hand
    //! @param width Width of the watch hand
    function drawHand(dc, angle, length, width, draw_type, fgcol, bgcol, border)
    {
        // Map out the coordinates of the watch hand
		var start;
        var dev_height = dc.getHeight();		
        var dev_width = dc.getWidth();
        if (border) {
        	length = length + 1;
        	width = width + 2;
        }
		if (draw_type == 2) {
			// hour marks
			start = dev_height / 2 - length - 4;
			length = start + length;
		} else {
			// minute and hours hands
			if (border) {
				start = -21;
			} else {
				start = -20;
			}
		}
        var coords = [];
        var ncoords;
        var result = [];
        var centerX = dev_width / 2;
        var centerY = dev_height / 2;
        var cos = Math.cos(angle);
        var sin = Math.sin(angle);
        var endX = centerX - (-length * sin);
        var endY = centerY + (-length * cos);

		if (draw_type == 2) {
        	coords = [ [-(width/2),-start], [-(width/2), -length], [width/2, -length], [width/2, -start] ];
        	result = new [4];
        	ncoords = 4;
        } else {
        	coords = [ [-(width/2),-start], [-(width/2), -length], [0, -length-width-1], 
        		  	   [width/2, -length], [width/2, -start] ];
        	result = new [5];
        	ncoords = 5;
        }

        // Transform the coordinates
        for (var i = 0; i < ncoords; i += 1)
        {
            var x = (coords[i][0] * cos) - (coords[i][1] * sin);
            var y = (coords[i][0] * sin) + (coords[i][1] * cos);
            var res_x = centerX+x;
            var res_y = centerY+y;
            result[i] = [ res_x, res_y ];
        }

        // Draw the polygon
		if (draw_type == 2) {
			dc.setColor(hash_color, Gfx.COLOR_TRANSPARENT);
		} else {
       		dc.setColor(fgcol, Gfx.COLOR_TRANSPARENT);
       	}
        dc.fillPolygon(result);
        if (draw_type == 1) { // hours
       		dc.setColor(bgcol, Gfx.COLOR_TRANSPARENT);
       		dc.drawLine(centerX, centerY, endX, endY);
       		dc.setColor(fgcol, Gfx.COLOR_TRANSPARENT);
       	}
       	//if (draw_type != 2) {
       	//	// minutes or hours hand
        //	dc.fillCircle(endX, endY, width / 2);
        //}
    }

    //! Draw the hash mark symbols on the watch
    //! @param dc Device context
    function drawHashMarks(dc, length, width)
    {    		
        for (var i = 0; i < 12; i += 1)
        {
        	if (i % 3 != 0) {
         		var hour = i;
        		hour = i * 60;
        		hour = hour / (12 * 60.0);
        		hour = hour * Math.PI * 2;
        		drawHand(dc, hour, length, width, 2, fgcolor, bgcolor, false);
        	}
        }
    }

    //! Handle the update event
    function onUpdate(dc)
    {
        var width, height;
        var clockTime = Sys.getClockTime();
        var hour;
        var min;
        var tiny_font_height;
        var dateStr;
        var center;
        var analog_num_dim = null;
		var base_date;
		var base_ampm;
		var base_altitude;
		var base_battery;
		var base_steps_hr;
		var base_dualtime;
		var pos_dualtime;
		var text_justify_dualtime;
		var bluetooth_x;
		var bluetooth_y;
		var dualtime_font = Gfx.FONT_TINY;
		var now_hour;
		var now_min;
        
        getSettings();

        width = dc.getWidth();
        height = dc.getHeight();	
        
        var now = Time.now();
        var info = Calendar.info(now, Time.FORMAT_LONG);
        
        now_hour = info.hour;
		now_min = info.min;

		if (digital_clock) {
        	dateStr = Lang.format(" $1$ $2$ $3$ ", [info.day_of_week, info.month, info.day]);
        } else {
        	dateStr = Lang.format(" $1$ $2$ ", [info.day_of_week, info.day]);
        }
        var Battery = Toybox.System.getSystemStats().battery;       
        var BatteryStr = Lang.format(" $1$% ", [Battery.toLong()]);

        // Clear the screen
        if (image_num != 0) {
        	dc.drawBitmap(0, 0, background);
        } else {
        	dc.setColor(Gfx.COLOR_TRANSPARENT, bgcolor);
        	dc.clear();
        }
        
		var analog_24h = false;
        if (!digital_clock) { 
	        // Draw the numbers
			if (screen_shape == Sys.SCREEN_SHAPE_ROUND) {
				analog_number_font = Gfx.FONT_NUMBER_MILD;
			} else {
				analog_number_font = Gfx.FONT_SMALL;
			}
			analog_num_dim = dc.getFontHeight(analog_number_font);
			tiny_font_height = analog_num_dim;
			hour = now_hour;
			if (hour >= 12 && AnalogUse24hFormat) {
				analog_24h = true;
				if (Battery >= battery_limit_critical) {
					dc.setColor(fgcolor, Gfx.COLOR_TRANSPARENT);
				} else {
					dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_TRANSPARENT);
				}
	        	dc.drawText((width/2),0,analog_number_font,"24",Gfx.TEXT_JUSTIFY_CENTER);
	        	// if (Battery >= battery_limit2) {
	        	//	dc.setColor(fgcolor, Gfx.COLOR_TRANSPARENT);
	        	//}
	        	//dc.drawText(width-5,height/2-15,analog_number_font,"15", Gfx.TEXT_JUSTIFY_RIGHT);
	        	dc.drawText(width/2,height-tiny_font_height,analog_number_font,"18", Gfx.TEXT_JUSTIFY_CENTER);
	        	dc.drawText(width/2-height/2+4,(height/2)-(tiny_font_height/2)-4,analog_number_font,"21",Gfx.TEXT_JUSTIFY_LEFT);
	        } else {
	        	if (Battery >= battery_limit_critical) {
					dc.setColor(fgcolor, Gfx.COLOR_TRANSPARENT);
				} else {
					dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_TRANSPARENT);
				}
	        	dc.drawText((width/2),0,analog_number_font,"12",Gfx.TEXT_JUSTIFY_CENTER);
	        	if (Battery >= battery_limit_critical) {
	        		dc.setColor(fgcolor, Gfx.COLOR_TRANSPARENT);
	        	}
	        	//dc.drawText(width-5,height/2-15,analog_number_font,"3", Gfx.TEXT_JUSTIFY_RIGHT);
	        	//dc.drawText(width/2,height-35,analog_number_font,"6", Gfx.TEXT_JUSTIFY_CENTER);
	        	dc.drawText(width/2,height-tiny_font_height,analog_number_font,"6", Gfx.TEXT_JUSTIFY_CENTER);
				tiny_font_height = dc.getFontHeight(analog_number_font);        	
	        	dc.drawText(width/2-height/2+4,(height/2)-(tiny_font_height/2)-4,analog_number_font,"9",Gfx.TEXT_JUSTIFY_LEFT);
	        }
	 	}

		// fonts and dimensions
	    tiny_font_height = dc.getFontHeight(Gfx.FONT_TINY);
    	center = height/2;

		pos_dualtime = width / 2;
		text_justify_dualtime = Gfx.TEXT_JUSTIFY_CENTER;
		
		var fix = 0;
		
		// positions of each element
		// * = optional
		// dt = dualtime
		// bt = bluetooth status
		if (screen_shape == Sys.SCREEN_SHAPE_ROUND) {
			// Round clock
			if (digital_clock) {
				//	digital clock
				// 		altitude* -> dualtime*
				//		date
				//		TIME
				// 		dualtime* -> altitude*
				//		steps* heart_rate*
				//		battery
				var extra_fix = 3;
				// if (!altitude_mode) {
				if (!dualtime) {
					fix = tiny_font_height/2;
				}
				// base_altitude = tiny_font_height + 1;
				base_dualtime = tiny_font_height + 1;
				base_date = 2 * tiny_font_height + 2 - fix;
				// TIME
				fix = 0;			
				// if (!dualtime || !(steps || heart_rate)) {
				if (!altitude_mode || !(steps || heart_rate)) {
					fix = tiny_font_height/2;
				}
				// base_dualtime = height - 3 * tiny_font_height - 3 + fix - extra_fix;
				base_altitude = height - 3 * tiny_font_height - 5 + fix - extra_fix;
				base_steps_hr = height - 2 * tiny_font_height - 4 - fix - extra_fix;
				base_battery = height - tiny_font_height - 1 - fix - extra_fix;
				//bluetooth_x = 32;
				//bluetooth_y = base_date  + 2;
				bluetooth_x = width / 2 - 8;
				bluetooth_y = 1;
				base_ampm = center + tiny_font_height/2;
			} else {
				//	analog clock
				// 		dualtime*
				//		altitude*
				//	bt	CENTER		date
				//		steps* heart_rate*
				//		battery
				var analog_number_font_height = dc.getFontHeight(analog_number_font);
				if (!dualtime || !altitude_mode) {
					fix = tiny_font_height/2;
				}
				if (!altitude_mode && use_large_dualtime_font) {
					dualtime_font = Gfx.FONT_MEDIUM;
				}
				// base_dualtime = tiny_font_height/2 + tiny_font_height + 1 + fix;
				// base_altitude = tiny_font_height/2 + 2 * tiny_font_height + 2 - fix;
				base_dualtime = analog_number_font_height + 2 + fix;
				base_altitude = analog_number_font_height + 2 + tiny_font_height - fix;
				// CENTER
				base_date = center + tiny_font_height/2;
				fix = 0;
				if (!(steps || heart_rate)) {
					fix = tiny_font_height/2;
				}				
				// base_steps_hr = height - tiny_font_height/2 - 3 * tiny_font_height - 3;
				// base_battery = height - tiny_font_height/2 - 2 * tiny_font_height - 2 - fix;
				base_steps_hr = height - analog_number_font_height - 2 - 2 * tiny_font_height;
				base_battery = height - analog_number_font_height - 2 - tiny_font_height - fix;
				bluetooth_x = 2 * 16;
				if (analog_24h) {
					bluetooth_x  = bluetooth_x + 16;
				}
				bluetooth_y = height / 2 - 8;
				base_ampm = 0;
			}
		
		} else {
			// Square clock
			if (digital_clock) {
				//	digital clock
				// 	bt	altitude*
				//		date
				//		TIME
				//		steps* heart_rate*
				//	dt*	battery
				if (!altitude_mode) {
					fix = tiny_font_height/2;
				}
				base_altitude = 1;
				base_date = tiny_font_height + 2 - fix;
				// TIME
				fix = 0;
				if (!(steps || heart_rate) && !dualtime) {
					fix = tiny_font_height/2;
				}
				base_steps_hr = height - 2 * tiny_font_height - 2;
				base_battery = height - tiny_font_height - 1 - fix;				
				base_dualtime = height - tiny_font_height - 1;	// lower left corner
				pos_dualtime = 1;		
				text_justify_dualtime = Gfx.TEXT_JUSTIFY_LEFT;	
				base_ampm = center + tiny_font_height/2;	
			} else {
				//	analog clock
				// 	bt	dualtime*
				//		altitude*
				//		CENTER		date
				//		steps* heart_rate
				//		battery
				if (!dualtime || !altitude_mode) {
					fix = tiny_font_height/2;
				}
				if (!altitude_mode && use_large_dualtime_font) {
					dualtime_font = Gfx.FONT_SMALL;
				}
				base_dualtime = tiny_font_height + 1 + fix;
				base_altitude = 2 * tiny_font_height + 2 - fix;
				// CENTER
				fix = 0;
				base_date = center + tiny_font_height/2;
				if (!(steps || heart_rate)) {
					fix = tiny_font_height/2;
				}
				base_steps_hr = height - 3 * tiny_font_height - 3;
				base_battery = height - 2 * tiny_font_height - 2 - fix;
				base_ampm = 0;
			}
			bluetooth_x = 0;
			bluetooth_y = 0;
		}
		
		// Draw bluetooth status
		if (show_bluetooth_status) {
			if (!demo) {
				bluetooth_status = Sys.getDeviceSettings().phoneConnected;
			}
			if (bluetooth_status) {
				dc.drawBitmap(bluetooth_x, bluetooth_y, bluetooth_ok_image);
			} else {
				dc.drawBitmap(bluetooth_x, bluetooth_y, bluetooth_error_image);			
			}
		}
		
    	// Draw Altitude
		if (altitude_mode) {		
			var actInfo;
			var altitudeStr;
			var highaltide = false;			
			var unknownaltitude = true;
			var actaltitude = 0;
			
			actInfo = Act.getActivityInfo();
			if (actInfo != null) {
				actaltitude = actInfo.altitude;
				if (actaltitude != null) {
					unknownaltitude = false;
					if (actaltitude > 4000) {
						highaltide = true;
					}
				} 				
			}
			var metric = Sys.getDeviceSettings().elevationUnits == Sys.UNIT_METRIC;
			if (demo) {
				unknownaltitude = false;	// DEMO			
				metric = true;				// DEMO
				actaltitude = 2238;			// DEMO
			}				
			if (unknownaltitude) {
				altitudeStr = " Alt -";
			} else {
				altitudeStr = Lang.format(" Alt $1$", [actaltitude.toLong()]);
			}
			if (metric) {
				altitudeStr = altitudeStr + " m ";
			} else {
				altitudeStr = altitudeStr + " ft ";
			}

			if (Battery < battery_limit_critical) {
				dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_RED);
        	} else if (highaltide) {
        		if (image_num != 0) {
					dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_BLACK);
				} else {
					dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_TRANSPARENT);
				}        
			} else {
				if (image_num != 0) {
					dc.setColor(fgcolor, bgcolor_with_image);
				} else {
					dc.setColor(fgcolor, Gfx.COLOR_TRANSPARENT);
				}
			}
       		dc.drawText(width/2,base_altitude,Gfx.FONT_TINY, altitudeStr, Gfx.TEXT_JUSTIFY_CENTER);
        }
        
		// Draw date        
		if (Battery >= battery_limit_critical) {
			if (digital_clock) {
        		if (image_num != 0) {
					dc.setColor(fgcolor, bgcolor_with_image);
				} else {
					dc.setColor(fgcolor, Gfx.COLOR_TRANSPARENT);
				}
        	} else {
        		dc.setColor(bgcolor, hash_color);
        	}
        } else {
        	dc.setColor(fgcolor, Gfx.COLOR_RED);
	    }	    
        if (digital_clock) {
        	dc.drawText(width/2,base_date,Gfx.FONT_TINY, dateStr, Gfx.TEXT_JUSTIFY_CENTER);
        } else {
	        dc.drawText(width - 4, (height/2)-(tiny_font_height/2), Gfx.FONT_TINY, dateStr, Gfx.TEXT_JUSTIFY_RIGHT);
	  	}
	  	
		// Draw dual time
		if (dualtime) {
			var timeStr;
			var dthour;
			var dtmin;
			
			var dtnow = now;
			// adjust to UTC/GMT
			dtnow = dtnow.add(new Time.Duration(-clockTime.timeZoneOffset));
			// adjust to time zone
			dtnow = dtnow.add(new Time.Duration(dualtimeTZ));
			
			if (dualtimeDST != 0) {
				// calculate Daylight Savings Time (DST)
				var dtDST;
				if (dualtimeDST == -1) {
					// Use the current dst value
					dtDST = clockTime.dst;
				} else {
					// Use the configured DST value
					dtDST = dualtimeDST; 
				}
				// adjust DST
				dtnow = dtnow.add(new Time.Duration(dtDST));
			}

			// create a time info object
			var dtinfo = Calendar.info(dtnow, Time.FORMAT_LONG);
			
			dthour = dtinfo.hour;
			dtmin = dtinfo.min;
			
			var use24hclock;
			var ampmStr = "am ";
			
			use24hclock = Sys.getDeviceSettings().is24Hour;
			if (!use24hclock) {
				if (dthour >= 12) {
					ampmStr = "pm ";
				}
				if (dthour > 12) {
					dthour = dthour - 12;				
				} else if (dthour == 0) {
					dthour = 12;
					ampmStr = "am ";
				}
			}			
			
			if (dthour < 10) {
				timeStr = Lang.format(" 0$1$:", [dthour]);
			} else {
				timeStr = Lang.format(" $1$:", [dthour]);
			}
			if (dtmin < 10) {
				timeStr = timeStr + Lang.format("0$1$ ", [dtmin]);
			} else {
				timeStr = timeStr + Lang.format("$1$ ", [dtmin]);
			}
			if (!use24hclock) {
				timeStr = timeStr + ampmStr; 
			}
			
			if (Battery < battery_limit_critical) {
				dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_RED);
			} else {
				if (image_num != 0) {
					dc.setColor(fgcolor, bgcolor_with_image);
				} else {
					dc.setColor(fgcolor, Gfx.COLOR_TRANSPARENT);
				}
			}
        	dc.drawText(pos_dualtime,base_dualtime,dualtime_font, timeStr, text_justify_dualtime);        
		} 

		// Draw Steps and/or heart rate on the same line
        if (steps || heart_rate) {
			var actInfo;
			var hrSample;
			var act_steps = 0;
			var steps_txt;
			var cur_hr;
			var hr_txt;
			var step_hr_font = Gfx.FONT_TINY;
			var steps_txt_width = 0;
			var hr_txt_width = 0;
			var steps_image_width = 0;
			var hr_image_width = 0;
			
			if (steps) {
				actInfo = ActMonitor.getInfo();
				if (actInfo != null) {
					act_steps = actInfo.steps;
				} else {
					act_steps = null;
				}
				if (demo) {
					act_steps = 2968;		// DEMO
				}
				if (act_steps == null) {
					steps_txt = " - ";
				} else {
					steps_txt = " " + act_steps.toString() + " ";
				}
				steps_txt_width = dc.getTextWidthInPixels(steps_txt, step_hr_font);
				steps_image_width = steps_image.getWidth();
			} else {
				steps_txt = "";
			}
			if (heart_rate) {
				actInfo = Act.getActivityInfo();
				if (actInfo != null) {
					cur_hr = actInfo.currentHeartRate;
				} else {
					cur_hr = null;
				}
				if (cur_hr == null) {
					if (ActMonitor has :getHeartRateHistory) {
						var HRH = ActMonitor.getHeartRateHistory(1, true);
						if (HRH != null) {
							var HRS = HRH.next();
							if (HRS != null && HRS.heartRate != ActMonitor.INVALID_HR_SAMPLE) {
								cur_hr = HRS.heartRate;
							}
						}
					}
				}
				if (demo) {
					cur_hr = 187;				// DEMO
				}
				if (cur_hr == null) {
					hr_txt = " - ";
				} else {
					hr_txt = " " + cur_hr.toString() + " ";
				}
				hr_txt_width = dc.getTextWidthInPixels(hr_txt, step_hr_font);
				hr_image_width = heart_rate_image.getWidth();
			} else {
				hr_txt = "";
			}

			if (Battery < battery_limit_critical) {
				dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_RED);
			} else {
				if (image_num != 0) {
					dc.setColor(fgcolor, bgcolor_with_image);
				} else {
					dc.setColor(fgcolor, Gfx.COLOR_TRANSPARENT);
				}
			}
			var pos;
			var spacing = 2;
			if (steps && heart_rate) {
				pos = width/2 - (hr_image_width + hr_txt_width + steps_image_width + steps_txt_width + 4 * spacing) / 2;

				dc.drawBitmap(pos, base_steps_hr + steps_image.getHeight() / 2 , heart_rate_image);
				pos = pos + hr_image_width + spacing;
				dc.drawText(pos, base_steps_hr, Gfx.FONT_TINY, hr_txt, Gfx.TEXT_JUSTIFY_LEFT);
				pos = pos + hr_txt_width + spacing;

				pos = pos + spacing;	// extra spacing in the middle

				dc.drawBitmap(pos, base_steps_hr + steps_image.getHeight() / 2, steps_image);
				pos = pos + steps_image_width + spacing;
				dc.drawText(pos, base_steps_hr, Gfx.FONT_TINY, steps_txt, Gfx.TEXT_JUSTIFY_LEFT);

			} else if (steps) {
				pos = width/2 - (steps_image_width + steps_txt_width + spacing) / 2;
				dc.drawBitmap(pos, base_steps_hr + steps_image.getHeight() / 2, steps_image);
				pos = pos + steps_image_width + spacing;
				dc.drawText(pos, base_steps_hr, Gfx.FONT_TINY, steps_txt, Gfx.TEXT_JUSTIFY_LEFT);

			} else if (heart_rate) {
				pos = width/2 - (hr_image_width + hr_txt_width + spacing) / 2;
				dc.drawBitmap(pos, base_steps_hr + heart_rate_image.getHeight() / 2, heart_rate_image);
				pos = pos + hr_image_width + spacing;
				dc.drawText(pos, base_steps_hr, Gfx.FONT_TINY, hr_txt, Gfx.TEXT_JUSTIFY_LEFT);
			}
        }

        // Draw battery
		if (Battery >= battery_limit_low) { 
			// Normal battery status
			dc.setColor(Gfx.COLOR_GREEN, battery_background_color);
		} else if (Battery >= battery_limit_critical) {
			// Low battery status
			dc.setColor(Gfx.COLOR_ORANGE, battery_background_color);		
		} else {
			// Critical battery status
			dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_BLACK);		
		}
        dc.drawText(width/2,base_battery,Gfx.FONT_TINY, BatteryStr, Gfx.TEXT_JUSTIFY_CENTER);
              	
       	// Draw the time.        
        if (digital_clock) {
			var timeStr;
			var textdimarr;
			var textx;
			var texty;
			var use24hclock;
			//var hour;
			var ampmStr = "AM";
			
			use24hclock = Sys.getDeviceSettings().is24Hour;
			hour = now_hour;
			if (!use24hclock) {
				if (hour >= 12) {
					ampmStr = "PM";
				}
				if (hour > 12) {
					hour = hour - 12;				
				} else if (hour == 0) {
					hour = 12;
					ampmStr = "AM";
				}
			}
			if (hour < 10) {
				timeStr = Lang.format("0$1$:", [hour]);
			} else {
				timeStr = Lang.format("$1$:", [hour]);
			}
			if (now_min < 10) {
				timeStr = timeStr + Lang.format("0$1$", [now_min]);
			} else {
				timeStr = timeStr + Lang.format("$1$", [now_min]);
			}
			textdimarr = dc.getTextDimensions(timeStr, digital_clock_font);
			textx = width/2 - textdimarr[0]/2;
			texty = height/2 - textdimarr[1]/2; 
			if (screen_shape != Sys.SCREEN_SHAPE_ROUND && use_system_font) {
				texty = texty + 4;
			} 		
         	if (use_bgcolor_with_image && image_num != 0) {
         		dc.setColor(bgcolor, Gfx.COLOR_TRANSPARENT);
         		dc.drawText(textx, texty, digital_clock_font, timeStr, Gfx.TEXT_JUSTIFY_LEFT);
         	
         		dc.setColor(digital_time_color, Gfx.COLOR_TRANSPARENT);
         		dc.drawText(textx-4,texty-4, digital_clock_font, timeStr, Gfx.TEXT_JUSTIFY_LEFT);
         	} else {
         		dc.setColor(digital_time_color, Gfx.COLOR_TRANSPARENT);
         		dc.drawText(textx, texty, digital_clock_font, timeStr, Gfx.TEXT_JUSTIFY_LEFT);
         	}
         	if (!use24hclock) {
         		dc.drawText(width - 4,(height/2)-(tiny_font_height/2),Gfx.FONT_TINY, ampmStr, Gfx.TEXT_JUSTIFY_RIGHT);
         	}
        } else {
        	var hour_hand_length;
			var min_hand_length;        
        	var hour_hand_width = 8;
			var min_hand_width = 6;        
        
            dc.setColor(fgcolor, Gfx.COLOR_TRANSPARENT);
	        
	        var hash_len = analog_num_dim / 2;
	        //min_hand_length = height/2 - hash_len - 4 - 1;
	        min_hand_length = height/2 - min_hand_width - 4 - 1;
			//hour_hand_length = min_hand_length * 65 / 100;
			hour_hand_length = height/2 - analog_num_dim - hour_hand_width - 4 - 1;
			// Draw the hash marks
	        drawHashMarks(dc, hash_len, 4);
	        	       
	        // Draw the hour. Convert it to minutes and
	        // compute the angle.
			var clock_hour = now_hour;
			var clock_min = now_min;
			if (demo) {
				clock_hour = 10;	// DEMO
				clock_min = 12;		// DEMO
			}
	        hour = ( ( ( clock_hour % 12 ) * 60 ) + clock_min );	        
	        hour = hour / (12 * 60.0);
	        hour = hour * Math.PI * 2;
	        drawHand(dc, hour, hour_hand_length, hour_hand_width, 0, bgcolor, bgcolor, true);        
	        drawHand(dc, hour, hour_hand_length, hour_hand_width, 1, fgcolor, bgcolor, false);
	        
	        // Draw the minute		
	        min = ( clock_min / 60.0) * Math.PI * 2;	        
	        drawHand(dc, min, min_hand_length, min_hand_width, 0, bgcolor, bgcolor, true);
	        drawHand(dc, min, min_hand_length, min_hand_width, 0, fgcolor, bgcolor, false);
	        
	        // Draw the inner circle
	        dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_BLACK);
	        dc.fillCircle(width/2, height/2, 7);
	        dc.setColor(Gfx.COLOR_WHITE,Gfx.COLOR_WHITE);
	        dc.drawCircle(width/2, height/2, 7);
	        dc.setColor(Gfx.COLOR_BLACK,Gfx.COLOR_BLACK);
	        dc.drawCircle(width/2, height/2, 9);
	 	}
	}

    //! Called when this View is removed from the screen. Save the
    //! state of this View here. This includes freeing resources from
    //! memory.
    function onHide() {
    }

    //! The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() {
    }

    //! Terminate any active timers and prepare for slow updates.
    function onEnterSleep() {
    }

}
