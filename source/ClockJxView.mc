using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Lang as Lang;
using Toybox.Application as App;
using Toybox.Time.Gregorian as Calendar;
using Toybox.Activity as Act;
using Toybox.ActivityMonitor as ActMonitor;

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

class ClockJxView extends Ui.WatchFace {

	var settingsChanged = true;
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
	var use_bgcolor_with_image = false;
	var digital_clock_font;
	var use_system_font = false;
	
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
		
		digital_clock = checkBool(App.getApp().getProperty("DigitalClock"));
		Use24hFormat = checkBool(App.getApp().getProperty("Use24hFormat"));
		mountain_mode = checkBool(App.getApp().getProperty("MountainMode"));
		steps = checkBool(App.getApp().getProperty("Steps"));
		screen_shape = Sys.getDeviceSettings().screenShape;
		new_use_system_font = checkBool(App.getApp().getProperty("UseSystemFont"));
		if (new_use_system_font != use_system_font) {
			use_system_font = new_use_system_font;
			digital_clock_font = null;
			if (use_system_font) {
				digital_clock_font = Gfx.FONT_NUMBER_THAI_HOT;
			} else {
				digital_clock_font = Ui.loadResource(Rez.Fonts.timefont);    			
			}
		}
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
	}

    function initialize() {
    	digital_clock_font = Ui.loadResource(Rez.Fonts.timefont);
    	//digital_clock_font = Gfx.FONT_NUMBER_THAI_HOT;
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
        var base_up;
        var base_down;
        var analog_num_dim = null;
        
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
			if (screen_shape == Sys.SCREEN_SHAPE_ROUND) {
				font = Gfx.FONT_NUMBER_MILD;
			} else {
				font = Gfx.FONT_SMALL;
			}
			analog_num_dim = dc.getFontHeight(font);
			dim = analog_num_dim;
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
	    digital_dim = dc.getFontHeight(digital_clock_font);
	    dim = dc.getFontHeight(Gfx.FONT_TINY);	   
    	center = height/2;
    	
	    if (screen_shape == Sys.SCREEN_SHAPE_ROUND) {
	    	//base_up = center-digital_dim/2-10-2*digital_clock_font_offset;
	    	//base_down = center+digital_dim/2-10;
	    	//base_down = center+digital_dim/2;
			base_up = 2 * dim;
			base_down = 2*center-2*dim-dim/2;
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
        	var date_base_up;
        	if (mountain_mode) {
        		date_base_up = base_up;
        	} else {
        		date_base_up = base_up - dim/2;
        	}
        	dc.drawText(width/2,date_base_up,Gfx.FONT_TINY, dateStr, Gfx.TEXT_JUSTIFY_CENTER);
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
              	
       	// Draw the time.        
        if (digital_clock) {
			var timeStr;
			var textdimarr;
			var textx;
			var texty;
			
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
			textdimarr = dc.getTextDimensions(timeStr, digital_clock_font);
			textx = width/2 - textdimarr[0]/2;
			texty = height/2 - textdimarr[1]/2; 
			if (screen_shape != Sys.SCREEN_SHAPE_ROUND) {
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
        } else {
        	var hour_hand_length;
			var min_hand_length;        
        	var hour_hand_width = 9;
			var min_hand_width = 6;        
        
            dc.setColor(fgcolor, Gfx.COLOR_TRANSPARENT);
	        min_hand_length = height/2 - analog_num_dim - 1;
	        if (screen_shape == Sys.SCREEN_SHAPE_ROUND) {
				hour_hand_length = min_hand_length * 65 / 100;
				// Draw the hash marks
	        	drawHashMarks(dc);
			} else {
				hour_hand_length = min_hand_length * 2 / 3;
			}
	        	       
	        // Draw the hour. Convert it to minutes and
	        // compute the angle.
			var clock_hour = clockTime.hour;
			var clock_min = clockTime.min;
clock_hour = 12;	// XXX
clock_min = 14;		// XXX
			//var clock_hour = 10;
			//var clock_min = 12;
			
	        hour = ( ( ( clock_hour % 12 ) * 60 ) + clock_min );	        
	        hour = hour / (12 * 60.0);
	        hour = hour * Math.PI * 2;
	        drawHand(dc, hour, hour_hand_length, hour_hand_width+2, 0, bgcolor, bgcolor);        
	        drawHand(dc, hour, hour_hand_length, hour_hand_width, 1, fgcolor, bgcolor);
	        
	        // Draw the minute		
	        min = ( clock_min / 60.0) * Math.PI * 2;	        
	        drawHand(dc, min, min_hand_length, min_hand_width+2, 0, bgcolor, bgcolor);
	        drawHand(dc, min, min_hand_length, min_hand_width, 0, fgcolor, bgcolor);
	        
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
