using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Lang as Lang;
using Toybox.Application as App;
using Toybox.Time as Time;
using Toybox.Time.Gregorian as Calendar;
using Toybox.Activity as Act;
using Toybox.ActivityMonitor as ActMonitor;

// I have used the following sources for the development of this watch face:
//	- Garmid SDK samples
// 	- Very nice blog post from Aaron Boman 
//		http://blog.aaronboman.com/programming/connectiq/2014/11/11/making-an-analog-watch-face/
//	- Several informative posts in Connect IQ forums
//		Custom fonts: https://forums.garmin.com/showthread.php?338498-Using-Custom-Fonts
//		Many others I cannot find any more
//	- Some other sources I cannot remember any more
//
// Misc notes
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
	var bgcolor;
	var hash_color;
	var font;
	var battery_limit_low = 50;
	var battery_limit_critical = 25;
	var background;
	var image_num = 0;
	var mountain_mode;
	var Use24hFormat;
	var digital_clock;
	var steps;
	var screen_shape;
	var bgcolor_with_image;
	var use_bgcolor_with_image = false;
	var digital_clock_font;
	var use_system_font = false;
	var dualtime = false;
	var dualtimeTZ = 0;
	var dualtimeDST = 0;
	var bluetooth_ok_image;
	var bluetooth_error_image;
	var bluetooth_status = true;
	var show_bluetooth_status = true;
	var use_large_dualtime_font = false;
	var demo = false;	// DEMO
	
	var ColorsArr = [ [0, 0x000000], [1, 0x555555], [2, 0xAAAAAA], [3, 0x0000FF], [4, 0x00AA00], [5, 0x00FF00] , 
					  [6, 0xFF5500], [7, 0xFFAA00], [8, 0xFFFFFF], [-1, -1]];
	
	function checkBool(b) {
		if (b == null || (b != true && b != false)) {
			return false;
		} 
		return b;
	}
	
	function checkNumber(n) {
		if (n == null) {
			return 0;
		} 
		return n.toNumber();
	}
	
	function checkNumberDef(n, def) {
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
		var new_image_num;
		var new_use_system_font;
		
		if (!settingsChanged) {
			return;
		}
		settingsChanged = false;
		
		demo = checkBool(App.getApp().getProperty("DemoMode"));
		
		digital_clock = checkBool(App.getApp().getProperty("DigitalClock"));
		Use24hFormat = checkBool(App.getApp().getProperty("Use24hFormat"));
		mountain_mode = checkBool(App.getApp().getProperty("MountainMode"));
		steps = checkBool(App.getApp().getProperty("Steps"));
		dualtime = checkBool(App.getApp().getProperty("UseDualTime"));
		dualtimeTZ = checkNumber(App.getApp().getProperty("DualTimeTZ"));
		dualtimeDST = checkNumber(App.getApp().getProperty("DualTimeDST"));

		new_use_system_font = checkBool(App.getApp().getProperty("UseSystemFont"));
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
		new_image_num = checkNumber(App.getApp().getProperty("BackgroundImage"));
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
       	fgcolor = checkColor(App.getApp().getProperty("ForegroundColor"), Gfx.COLOR_WHITE);
       	bgcolor = checkColor(App.getApp().getProperty("BackgroundColor"), Gfx.COLOR_BLACK);
    	if (fgcolor == Gfx.COLOR_WHITE && bgcolor == Gfx.COLOR_BLACK && image_num == 0) {
    		hash_color = Gfx.COLOR_LT_GRAY;
    	} else {
    		hash_color = fgcolor;
    	}
    	if (checkBool(App.getApp().getProperty("UseBackgroundColorWithImage"))) {
    		bgcolor_with_image = bgcolor;
    		use_bgcolor_with_image = true;
    	} else {
    		bgcolor_with_image = Gfx.COLOR_TRANSPARENT;
    		use_bgcolor_with_image = false;
    	}
    	show_bluetooth_status = checkBool(App.getApp().getProperty("UseBluetoothIcon"));
    	if (show_bluetooth_status) {
	    	if (demo) {
	    		bluetooth_status = !bluetooth_status;
	    	}
	    	if (bluetooth_ok_image == null) {
	    		bluetooth_ok_image = Ui.loadResource(Rez.Drawables.bluetooth_ok);
	    	}
	    	if (bluetooth_error_image == null) {
    			bluetooth_error_image = Ui.loadResource(Rez.Drawables.bluetooth_error);
    		}
	    } else {
	    	bluetooth_ok_image = null;
	    	bluetooth_error_image = null;
	    }
	    use_large_dualtime_font = checkBool(App.getApp().getProperty("UseLargeDualTimeFont"));
	    battery_limit_low = checkNumberDef(App.getApp().getProperty("BatteryWarningLimitLow"), 50);
	    battery_limit_critical = checkNumberDef(App.getApp().getProperty("BatteryWarningLimitCritical"), 25);
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
        var dim;
        var digital_dim;
        var dateStr;
        var center;
        var analog_num_dim = null;
		var base_date;
		var base_ampm;
		var base_altitude;
		var base_battery;
		var base_steps;
		var base_dualtime;
		var pos_dualtime;
		var justify_dualtime;
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
        
        if (!digital_clock) { 
	        // Draw the numbers
			if (screen_shape == Sys.SCREEN_SHAPE_ROUND) {
				font = Gfx.FONT_NUMBER_MILD;
			} else {
				font = Gfx.FONT_SMALL;
			}
			analog_num_dim = dc.getFontHeight(font);
			dim = analog_num_dim;
			hour = now_hour;
			if (hour >= 12 && Use24hFormat) {
				if (Battery >= battery_limit_critical) {
					dc.setColor(fgcolor, Gfx.COLOR_TRANSPARENT);
				} else {
					dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_TRANSPARENT);
				}
	        	dc.drawText((width/2),0,font,"24",Gfx.TEXT_JUSTIFY_CENTER);
	        	if (Battery >= battery_limit2) {
	        		dc.setColor(fgcolor, Gfx.COLOR_TRANSPARENT);
	        	}
	        	//dc.drawText(width-5,height/2-15,font,"15", Gfx.TEXT_JUSTIFY_RIGHT);
	        	dc.drawText(width/2,height-dim,font,"18", Gfx.TEXT_JUSTIFY_CENTER);
	        	dc.drawText(width/2-height/2+4,(height/2)-(dim/2)-4,font,"21",Gfx.TEXT_JUSTIFY_LEFT);
	        } else {
	        	if (Battery >= battery_limit_critical) {
					dc.setColor(fgcolor, Gfx.COLOR_TRANSPARENT);
				} else {
					dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_TRANSPARENT);
				}
	        	dc.drawText((width/2),0,font,"12",Gfx.TEXT_JUSTIFY_CENTER);
	        	if (Battery >= battery_limit_critical) {
	        		dc.setColor(fgcolor, Gfx.COLOR_TRANSPARENT);
	        	}
	        	//dc.drawText(width-5,height/2-15,font,"3", Gfx.TEXT_JUSTIFY_RIGHT);
	        	//dc.drawText(width/2,height-35,font,"6", Gfx.TEXT_JUSTIFY_CENTER);
	        	dc.drawText(width/2,height-dim,font,"6", Gfx.TEXT_JUSTIFY_CENTER);
				dim = dc.getFontHeight(font);        	
	        	dc.drawText(width/2-height/2+4,(height/2)-(dim/2)-4,font,"9",Gfx.TEXT_JUSTIFY_LEFT);
	        }
	 	}

		// fonts and dimensions
	    digital_dim = dc.getFontHeight(digital_clock_font);
	    dim = dc.getFontHeight(Gfx.FONT_TINY);	   
    	center = height/2;

		pos_dualtime = width / 2;
		justify_dualtime = Gfx.TEXT_JUSTIFY_CENTER;
		
		var fix = 0;
		
		// positions of each element
		// * = optional
		// dt = dualtime
		// bt = bluetooth status
		if (screen_shape == Sys.SCREEN_SHAPE_ROUND) {
			// Round clock
			if (digital_clock) {
				//	digital clock
				// 		altitude*
				//		date
				//		TIME
				// 		dualtime*
				//		steps*
				//		battery
				var extra_fix = 3;
				if (!mountain_mode) {
					fix = dim/2;
				}
				base_altitude = dim + 1;
				base_date = 2 * dim + 2 - fix;
				// TIME
				fix = 0;			
				if (!dualtime || !steps) {
					fix = dim/2;
				}
				base_dualtime = height - 3 * dim - 3 + fix - extra_fix;				
				base_steps = height - 2 * dim - 2 - fix - extra_fix;
				base_battery = height - dim - 1 - fix - extra_fix;
				//bluetooth_x = 32;
				//bluetooth_y = base_date  + 2;
				bluetooth_x = width / 2 - 8;
				bluetooth_y = 1;
				base_ampm = center + dim/2;
			} else {
				//	analog clock
				// 		dualtime*
				//		altitude*
				//	bt	CENTER		date
				//		steps*
				//		battery
				if (!dualtime || !mountain_mode) {
					fix = dim/2;
				}
				if (!mountain_mode && use_large_dualtime_font) {
					dualtime_font = Gfx.FONT_MEDIUM;
				}
				base_dualtime = dim/2 + dim + 1 + fix;
				base_altitude = dim/2 + 2 * dim + 2 - fix;
				// CENTER
				base_date = center + dim/2;
				fix = 0;
				if (!steps) {
					fix = dim/2;
				}				
				base_steps = height - dim/2 - 3 * dim - 3;
				base_battery = height - dim/2 - 2 * dim - 2 - fix;
				bluetooth_x = 2 * 16;
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
				//		steps*
				//	dt*	battery
				if (!mountain_mode) {
					fix = dim/2;
				}
				base_altitude = 1;
				base_date = dim + 2 - fix;
				// TIME
				fix = 0;
				if (!steps && !dualtime) {
					fix = dim/2;
				}
				base_steps = height - 2 * dim - 2;
				base_battery = height - dim - 1 - fix;				
				base_dualtime = height - dim - 1;	// lower left corner
				pos_dualtime = 1;		
				justify_dualtime = Gfx.TEXT_JUSTIFY_LEFT;	
				base_ampm = center + dim/2;	
			} else {
				//	analog clock
				// 	bt	dualtime*
				//		altitude*
				//		CENTER		date
				//		steps*
				//		battery
				if (!dualtime || !mountain_mode) {
					fix = dim/2;
				}
				if (!mountain_mode && use_large_dualtime_font) {
					dualtime_font = Gfx.FONT_SMALL;
				}
				base_dualtime = dim + 1 + fix;
				base_altitude = 2 * dim + 2 - fix;
				// CENTER
				fix = 0;
				base_date = center + dim/2;
				if (!steps) {
					fix = dim/2;
				}
				base_steps = height - 3 * dim - 3;
				base_battery = height - 2 * dim - 2 - fix;
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
		if (mountain_mode) {		
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
				altitudeStr = Lang.format(" Alt unknown");
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
	        dc.drawText(width - 4, (height/2)-(dim/2), Gfx.FONT_TINY, dateStr, Gfx.TEXT_JUSTIFY_RIGHT);
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
        	dc.drawText(pos_dualtime,base_dualtime,dualtime_font, timeStr, justify_dualtime);        
		} 

		// Draw Steps        
        if (steps) {

			var actInfo;
			var actsteps = 0;
			var unknownsteps = true;	
			var stepsStr;
			
			actInfo = ActMonitor.getInfo();
			if (actInfo != null) {
				actsteps = actInfo.steps;
				if (actsteps != null) {
					unknownsteps = false;
				}
			}
			if (demo) {
				unknownsteps = false; 	//DEMO
				actsteps = 2968;		// DEMO
			}
			if (unknownsteps) {
				stepsStr = Lang.format(" unknown steps ", [actsteps]);
			} else {
				stepsStr = Lang.format(" $1$ steps ", [actsteps]);			
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
			dc.drawText(width/2,base_steps,Gfx.FONT_TINY, stepsStr, Gfx.TEXT_JUSTIFY_CENTER);
        }

        // Draw battery
		var battery_bgcolor;
		battery_bgcolor = Gfx.COLOR_BLACK;
		if (Battery >= battery_limit_low) { 
			// Normal battery status
			dc.setColor(Gfx.COLOR_GREEN, battery_bgcolor);
		} else if (Battery >= battery_limit_critical) {
			// Low battery status
			dc.setColor(Gfx.COLOR_ORANGE, battery_bgcolor);		
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
			var hour;
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
         	
         		dc.setColor(fgcolor, Gfx.COLOR_TRANSPARENT);
         		dc.drawText(textx-2,texty-2, digital_clock_font, timeStr, Gfx.TEXT_JUSTIFY_LEFT);
         	} else {
         		dc.setColor(fgcolor, Gfx.COLOR_TRANSPARENT);
         		dc.drawText(textx, texty, digital_clock_font, timeStr, Gfx.TEXT_JUSTIFY_LEFT);
         	}
         	if (!use24hclock) {
         		dc.drawText(width - 4,(height/2)-(dim/2),Gfx.FONT_TINY, ampmStr, Gfx.TEXT_JUSTIFY_RIGHT);
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
