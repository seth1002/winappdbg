@echo off

:: ###############################################################################
:: #                                                                             #
:: #                          For more information see:                          #
:: #            http://winappdbg.sourceforge.net/Redistribution.html             #
:: #                                                                             #
:: ###############################################################################


:: The following packages should be installed and present in the PATH environment variable:
::   Python 2.7 (older versions won't do because of distutils)
::   Tar and BZip2 (to compress the source packages to tar.bz2 format, downloadable from gnuwin32)
::   Make (to build the PDF manuals, also downloadable from gnuwin32)
::   Epydoc and GraphViz (to generate the docs)
::   Sphinx (to build the manuals)
::   Microsoft HTML Help Workshop to generate CHM help files (http://www.microsoft.com/download/en/details.aspx?displaylang=en&id=21138)
::   MikTex (or an equivalent Latex package for Windows, to generate pdfs)


:: Location of this batch script
set BatchFile=%0


:: Location of the Python interpreters
set PYTHON_x86=%SystemDrive%\Python27\python.exe
set PYTHON_x64=%SystemDrive%\Python27-x64\python.exe


:: Epydoc command line switches
set EPYDOC_SCRIPT=%SystemDrive%\Python27\Scripts\epydoc.py
set EPYDOC_CMD=%PYTHON_x86% %EPYDOC_SCRIPT%
set EPYDOC_OPT=--verbose --fail-on-docstring-warning --simple-term --docformat epytext --name "WinAppDbg - Programming Reference" --url "http://sourceforge.net/projects/winappdbg/" winappdbg
set EPYDOC_HTML_OPT=--html --include-log --show-frames --css default
set EPYDOC_PDF_OPT=--pdf --separate-classes
set EPYDOC_TEST_OPT=--check
set EPYDOC_OUTPUT_OPT=--show-private --no-imports --inheritance=included
set EPYDOC_GRAPH_OPT=--graph all


:: Source package options
set SDIST_OPT=--formats=zip,bztar


:: Windows installer package options
set BDIST_UAC=--user-access-control auto


:Start
if "%1"=="" goto Help
if "%1"=="/?" goto Help
if "%1"=="/h" goto Help
if "%1"=="/H" goto Help
if "%1"=="-h" goto Help
if "%1"=="--help" goto Help

if exist %PYTHON_x86% goto Command
if exist %PYTHON_x64% goto Command
echo Error: Cannot find a suitable Python interpreter.
goto Exit

:Next
shift

:Command
if "%1"=="" goto Exit
if "%1"=="all" goto All
if "%1"=="clean" goto Clean
if "%1"=="source" goto Source
if "%1"=="wininst" goto WinInst
if "%1"=="portable" goto Portable
if "%1"=="autodoc" goto Autodoc
if "%1"=="manuals" goto Manuals
echo Error: Unknown command: %1
goto Next

:Help
echo WinAppDbg distribution builder
echo.
echo Available commands:
echo    make all                Build all the packages
echo    make clean              Clean up temporary files
echo.
echo Subcommands:
echo    make source             Build the source distribution packages
echo    make wininst            Build the Windows installer packages
:: echo    make portable           Build the portable packages
echo    make autodoc            Build the reference docs
echo    make manuals            Build the manuals
echo.
echo NOTE: If you're trying to install WinAppDbg, run install.bat instead!
goto Exit

:All
call %BatchFile% source portable wininst autodoc manuals
goto Next



:Clean
python setup.py clean
if exist build del /s /q build
if exist html del /s /q html
if exist pdf del /s /q pdf
if exist dist del /s /q dist
if exist doc\build del /s /q doc\build
if exist build rmdir /s /q build
if exist html rmdir /s /q html
if exist pdf rmdir /s /q pdf
if exist dist rmdir /s /q dist
if exist doc\build rmdir /s /q doc\build
if exist MANIFEST del MANIFEST
goto Next



:Source

:: Build the source distribution packages
python setup.py sdist %SDIST_OPT%

goto Next



:WinInst

:: Build the Windows installer packages
%PYTHON_x86% setup.py bdist_wininst %BDIST_UAC%
%PYTHON_x64% setup.py bdist_wininst %BDIST_UAC%

:: Build the Windows MSI installer packages for 32 bits
%PYTHON_x86% setup.py bdist_msi --target-version=2.4
%PYTHON_x86% setup.py bdist_msi --target-version=2.5
%PYTHON_x86% setup.py bdist_msi --target-version=2.6
%PYTHON_x86% setup.py bdist_msi --target-version=2.7

:: Build the Windows MSI installer packages for 64 bits
%PYTHON_x64% setup.py bdist_msi --target-version=2.5
%PYTHON_x64% setup.py bdist_msi --target-version=2.6
%PYTHON_x64% setup.py bdist_msi --target-version=2.7

goto Next



:Portable
echo TODO Portable
goto Next



:Autodoc
if not exist %EPYDOC_SCRIPT% (
	echo Error: Epydoc is not installed.
	goto Next
)

:: Generate the HTML documentation
%EPYDOC_CMD% %EPYDOC_HTML_OPT% %EPYDOC_OUTPUT_OPT% %EPYDOC_OPT%

:: Compile the HTML documentation into a CHM file
if %errorlevel%==0 hhc winappdbg.hhp

:: Generate the PDF documentation
%EPYDOC_CMD% %EPYDOC_PDF_OPT% %EPYDOC_OUTPUT_OPT% %EPYDOC_OPT%

goto Next



:Manuals
if not exist doc (
	echo Error: Cannot find the sources to build the manuals.
	goto Next
)
if not exist dist mkdir dist

:: Generate the HTML manual
cd doc
call make.bat html
cd build
if exist html tar -cjf ../../dist/html.tar.bz2 html
cd ..\..

:: Generate the CHM manual
cd doc
call make.bat htmlhelp
cd build\htmlhelp
hhc WinAppDbg.hhp
cd ..\..\..
if exist doc\build\htmlhelp\WinAppDbg.chm move doc\build\htmlhelp\WinAppDbg.chm dist\

:: Generate the PDF manual
cd doc
call make.bat latex
cd build\latex
make
cd ..\..\..
if exist doc\build\latex\WinAppDbg.pdf move doc\build\latex\WinAppDbg.pdf dist\

goto Next



:Exit
