@echo off
pushd %~dp0
"%VS120COMNTOOLS%..\IDE\mstest" /test:Microsoft.Protocols.TestSuites.MS_OXWSSYNC.S03_OperateSyncFolderHierarchyOptionalElements.MSOXWSSYNC_S03_TC02_SyncFolderHierarchy_WithAllOptionalElements /testcontainer:..\..\MS-OXWSSYNC\TestSuite\bin\Debug\MS-OXWSSYNC_TestSuite.dll /runconfig:..\..\MS-OXWSSYNC\MS-OXWSSYNC.testsettings /unique
pause