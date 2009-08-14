===running selenium tests===


1.) to run only on Firefox just install latest version of seleniumIDE plugin & in options set path to user-extensions.js file & open test suite & run it

2.) to run test suite against IE browser:

  a.) download & extract seleniumRC from: http://seleniumhq.org/projects/remote-control/

  b.) to run it for localhost app: enter seleniumRC directory, type in command: java -jar selenium-server.jar -htmlSuite "*iexplore" "startURL" "pathToSuiteFile" "pathToResultFile" -userExtensions "pathTo user-extensions.js"

  for Firefox, you will have to run command: java -jar selenium-server.jar -htmlSuite "*firefox" "startURL" "pathToSuiteFile" "pathToResultFile" -userExtensions "pathTo user-extensions.js"

  c.) to run it against eg. demo server you need to run seleniumRC in proxy injection mode: java -jar selenium-server.jar -htmlSuite "*piiexplore" "startURL" "pathToSuiteFile" "pathToResultFile" -userExtensions "pathTo user-extensions.js"

  for Firefox, you will have to run command: java -jar selenium-server.jar -htmlSuite "*pifirefox" "startURL" "pathToSuiteFile" "pathToResultFile" -userExtensions "pathTo user-extensions.js"


===notes===

1.) user-extension.js file is stored in selenium tests directory

2.) test were prepared & ran on version 1.0.1 of seleniumIDE & seleniumRC & Firefox 3.0.10
