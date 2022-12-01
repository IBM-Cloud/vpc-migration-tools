#Disabling the Precheck Task if success
Disable-ScheduledTask -TaskPath "\CustomTasks\" -TaskName "Precheckscript"

#Executing the Sysprep Command
YOUR_COMMAND