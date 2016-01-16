set bakTimestamp=%date:~4,2%%date:~7,2%%date:~10,4%_%time:~0,2%%time:~3,2%%time:~6,2%
mkdir "\Users\jruuth.SOLID\Google Drive\Garmin\ClockJx\%bakTimestamp%"
xcopy /S * "\Users\jruuth.SOLID\Google Drive\Garmin\ClockJx\%bakTimestamp%\*" 
