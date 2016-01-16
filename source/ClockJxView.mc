using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Lang as Lang;
using Toybox.Application as App;
using Toybox.Time.Gregorian as Calendar;
using Toybox.Activity as Act;
using Toybox.ActivityMonitor as ActMonitor;

class ClockJxView extends Ui.WatchFace {

	var fgcolor;
	var bgcolor;
	var hash_color;
	var font;
	var battery_limit1 = 50;
	var battery_limit2 = 25;
	var background;
	var image_num = 0;
	var mountain_mode;
	var Use24hFormat;
	var digital_clock;
	var steps;
	var screen_shape;
	var bgcolor_with_image;
	
	var fgColorsArr = [ [0, 0x000000], [1, 0xAAAAAA], [2, 0x0000FF], [3, 0x00FF00], [4, 0xFF5500], [5, 0xFFAA00] , [6, 0xFFFFFF], [-1, -1]];
	var bgColorsArr = [ [0, 0x000000], [1, 0x555555], [2, 0xAAAAAA], [3, 0x0000FF], [4, 0x00AA00], [5, 0xFFFFFF] , [-1, -1]];
	
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
	
	function checkColor(c, arr, defcolor) {
		var n;
		if (c == null) {
			return defcolor;
		}
		n = c.toNumber();
		for (var i = 0; arr[i][0] != -1; i = i + 1) {
			if (n == arr[i][0] || n == arr[i][1]) {
				return arr[i][1];
			}
		}
		return defcolor;
	}
	
	function getSettings() {
		var new_image_num;
		
		digital_clock = checkBool(App.getApp().getProperty("DigitalClock"));
		Use24hFormat = checkBool(App.getApp().getProperty("Use24hFormat"));
		mountain_mode = checkBool(App.getApp().getProperty("MountainMode"));
		steps = checkBool(App.getApp().getProperty("Steps"));
		screen_shape = Sys.getDeviceSettings().screenShape;
		new_image_num = checkNumber(App.getApp().getProperty("BackgroundImage"));
		if (new_image_num != image_num && new_image_num != 0) {
			if (new_image_num == 1) {
	        	background = Ui.loadResource(Rez.Drawables.bgimg1);
        	} else if (new_image_num == 2) {
       			background = Ui.loadResource(Rez.Drawables.bgimg2);
        	} else if (new_image_num == 3) {
       			background = Ui.loadResource(Rez.Drawables.bgimg3);
        	} else if (new_image_num == 4) {
       			background = Ui.loadResource(Rez.Drawables.bgimg4);
        	} else {
       			new_image_num = 0;
        	}			
    	}
    	image_num = new_image_num;
       	fgcolor = checkColor(App.getApp().getProperty("ForegroundColor"), fgColorsArr, Gfx.COLOR_WHITE);
       	bgcolor = checkColor(App.getApp().getProperty("BackgroundColor"), bgColorsArr, Gfx.COLOR_BLACK);
    	if (fgcolor == Gfx.COLOR_WHITE && bgcolor == Gfx.COLOR_BLACK && image_num == 0) {
    		hash_color = Gfx.COLOR_LT_GRAY;
    	} else {
    		hash_color = fgcolor;
    	}
    	if (checkBool(App.getApp().getProperty("UseBackgroundColorWithImage"))) {
    		bgcolor_with_image = bgcolor;
    	} else {
    		bgcolor_with_image = Gfx.COLOR_TRANSPARENT;
    	}
	}

    function initialize() {
        WatchFace.initialize();
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
    function drawHand(dc, angle, length, width, draw_type, fgcol, bgcol)
    {
        // Map out the coordinates of the watch hand
		var start;
		if (draw_type == 2) {
			// hour marks
			start = 90;
		} else {
			// minute and hours hands
			start = 0;
		}
        var coords = [ [-(width/2),-start], [-(width/2), -length], [width/2, -length], [width/2, -start] ];
        var result = new [4];
        var dev_width = dc.getWidth();
        var dev_height = dc.getHeight();
        var centerX = dev_width / 2;
        var centerY = dev_height / 2;
        var cos = Math.cos(angle);
        var sin = Math.sin(angle);
        var endX = centerX - (-length * sin);
        var endY = centerY + (-length * cos);

        // Transform the coordinates
        for (var i = 0; i < 4; i += 1)
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
       	if (draw_type != 2) {
       		// minutes or hours hand
        	dc.fillCircle(endX, endY, width / 2);
        }
    }

    //! Draw the hash mark symbols on the watch
    //! @param dc Device context
    function drawHashMarks(dc)
    {    		
        for (var i = 0; i < 12; i += 1)
        {
        	if (i % 3 != 0) {
         		var hour = i;
        		hour = i * 60;
        		hour = hour / (12 * 60.0);
        		hour = hour * Math.PI * 2;
        		drawHand(dc, hour, 105, 4, 2, fgcolor, bgcolor);
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
        var digital_clock_font;
        var base_up;
        var base_down;
        
        getSettings();

        width = dc.getWidth();
        height = dc.getHeight();	
        
        var now = Time.now();
        var info = Calendar.info(now, Time.FORMAT_LONG);

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
			font = Gfx.FONT_NUMBER_MILD;
			dim = dc.getFontHeight(font);
			hour = clockTime.hour;
			if (hour >= 12 && Use24hFormat) {
				if (Battery >= battery_limit2) {
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
	        	dc.drawText(5,(height/2)-(dim/2)-5,font,"21",Gfx.TEXT_JUSTIFY_LEFT);
	        } else {
	        	if (Battery >= battery_limit2) {
					dc.setColor(fgcolor, Gfx.COLOR_TRANSPARENT);
				} else {
					dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_TRANSPARENT);
				}
	        	dc.drawText((width/2),0,font,"12",Gfx.TEXT_JUSTIFY_CENTER);
	        	if (Battery >= battery_limit2) {
	        		dc.setColor(fgcolor, Gfx.COLOR_TRANSPARENT);
	        	}
	        	//dc.drawText(width-5,height/2-15,font,"3", Gfx.TEXT_JUSTIFY_RIGHT);
	        	//dc.drawText(width/2,height-35,font,"6", Gfx.TEXT_JUSTIFY_CENTER);
	        	dc.drawText(width/2,height-dim,font,"6", Gfx.TEXT_JUSTIFY_CENTER);
				dim = dc.getFontHeight(font);        	
	        	dc.drawText(5,(height/2)-(dim/2)-5,font,"9",Gfx.TEXT_JUSTIFY_LEFT);
	        }
	 	}

		// fonts and dimensions
		digital_clock_font = Gfx.FONT_NUMBER_THAI_HOT;
	    digital_dim = dc.getFontHeight(digital_clock_font); 

	    dim = dc.getFontHeight(Gfx.FONT_TINY);
	    
	    if (digital_clock) {
	    	if (mountain_mode && screen_shape == Sys.SCREEN_SHAPE_ROUND) {
	    		center = height/2+10;
	    	} else {
	    		center = height/2;	    	
	    	}
	    } else {
	    	center = height/2;
	    }
	    if (screen_shape == Sys.SCREEN_SHAPE_ROUND) {
	    	base_up = center-digital_dim/2-10;
	    	base_down = center+digital_dim/2-10;
	    } else {
	    	base_up = dim+1;
	    	base_down = 2*center-2*dim-1;
	    	if (!digital_clock) {
	    		base_down = base_down - 3;
	    	}
	    }
	    
		if (mountain_mode) {
			// Draw Altitude
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
			if (unknownaltitude) {
				altitudeStr = Lang.format(" Alt unknown");
			} else {
				altitudeStr = Lang.format(" Alt $1$", [actaltitude.toLong()]);
			}
			var metric = Sys.getDeviceSettings().elevationUnits == Sys.UNIT_METRIC;
			if (metric) {
				altitudeStr = altitudeStr + " m ";
			} else {
				altitudeStr = altitudeStr + " ft ";
			}

			if (Battery < battery_limit2) {
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
			if (digital_clock) {
				dc.drawText(width/2,base_up-dim-1,Gfx.FONT_TINY, altitudeStr, Gfx.TEXT_JUSTIFY_CENTER);
			} else {
        		dc.drawText(width/2,(height/4)-1,Gfx.FONT_TINY, altitudeStr, Gfx.TEXT_JUSTIFY_CENTER);
       		}
        }
        
		// Draw date        
		if (Battery >= battery_limit2) {
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
        	dc.setColor(bgcolor, Gfx.COLOR_RED);
	    }	    
        if (digital_clock) {
        	dc.drawText(width/2,base_up,Gfx.FONT_TINY, dateStr, Gfx.TEXT_JUSTIFY_CENTER);
        } else {
	        dc.drawText(width-5,(height/2)-(dim/2),Gfx.FONT_TINY, dateStr, Gfx.TEXT_JUSTIFY_RIGHT);
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
			if (unknownsteps) {
				stepsStr = Lang.format(" unknown steps ", [actsteps]);
			} else {
				stepsStr = Lang.format(" $1$ steps ", [actsteps]);			
			}

			if (Battery < battery_limit2) {
				dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_RED);
			} else {
				if (image_num != 0) {
					dc.setColor(fgcolor, bgcolor_with_image);
				} else {
					dc.setColor(fgcolor, Gfx.COLOR_TRANSPARENT);
				}
			}
			if (digital_clock) {
				dc.drawText(width/2,base_down-1,Gfx.FONT_TINY, stepsStr, Gfx.TEXT_JUSTIFY_CENTER);
			} else {
        		dc.drawText(width/2,(60*height/100)-1,Gfx.FONT_TINY, stepsStr, Gfx.TEXT_JUSTIFY_CENTER);
       		}        
        }

        // Draw battery
		if (Battery >= battery_limit1) { 
			dc.setColor(Gfx.COLOR_GREEN, Gfx.COLOR_BLACK);
		} else if (Battery >= battery_limit2) {
			dc.setColor(Gfx.COLOR_ORANGE, Gfx.COLOR_BLACK);		
		} else {
			dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_BLACK);		
		}
        if (digital_clock) {
        	if (steps) {
        		dc.drawText(width/2,base_down+dim,Gfx.FONT_TINY, BatteryStr, Gfx.TEXT_JUSTIFY_CENTER);
        	} else {		
        		dc.drawText(width/2,base_down+dim/2,Gfx.FONT_TINY, BatteryStr, Gfx.TEXT_JUSTIFY_CENTER);
        	}
       	} else {
       		if (steps) {
       			dc.drawText(width/2,(60*height/100)+dim,Gfx.FONT_TINY, BatteryStr, Gfx.TEXT_JUSTIFY_CENTER);
       		} else {
       			dc.drawText(width/2,(65*height/100),Gfx.FONT_TINY, BatteryStr, Gfx.TEXT_JUSTIFY_CENTER);
       		}
       	}
        
        dc.setColor(fgcolor, Gfx.COLOR_TRANSPARENT);
      	
       	// Draw the time.        
        if (digital_clock) {

			var timeStr;
			if (clockTime.hour < 10) {
				timeStr = Lang.format("0$1$:", [clockTime.hour]);
			} else {
				timeStr = Lang.format("$1$:", [clockTime.hour]);
			}
			if (clockTime.min < 10) {
				timeStr = timeStr + Lang.format("0$1$", [clockTime.min]);
			} else {
				timeStr = timeStr + Lang.format("$1$", [clockTime.min]);
			}		
         	dc.drawText(width/2,center-digital_dim/2,digital_clock_font, timeStr, Gfx.TEXT_JUSTIFY_CENTER);
        } else {
        	if (screen_shape == Sys.SCREEN_SHAPE_ROUND) { 
	        	// Draw the hash marks
	        	drawHashMarks(dc);
	        }
	        
	        // Draw the hour. Convert it to minutes and
	        // compute the angle.
	        hour = ( ( ( clockTime.hour % 12 ) * 60 ) + clockTime.min );	        
	        hour = hour / (12 * 60.0);
	        hour = hour * Math.PI * 2;
	        if (image_num != 0) {
	        	drawHand(dc, hour, 52, 11, 0, Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);
	        }        
	        drawHand(dc, hour, 52, 9, 1, fgcolor, bgcolor);
	        
	        // Draw the minute		
	        min = ( clockTime.min / 60.0) * Math.PI * 2;	        
	        if (image_num != 0) {
	        	drawHand(dc, min, 80, 8, 0, Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);
	        }
	        drawHand(dc, min, 80, 6, 0, fgcolor, bgcolor);
	        
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
