@echo off
pushd %~dp0
"%VS120COMNTOOLS%..\IDE\mstest" /testcontainer:..\..\MS-FSSHTTP-FSSHTTPB\TestSuite\bin\Debug\MS-FSSHTTP-FSSHTTPB_TestSuite.dll /runconfig:..\..\MS-FSSHTTP-FSSHTTPB\MS-FSSHTTP-FSSHTTPB.testsettings 
pause