# New Relic Super Mario Demo for Conferences

## Prerequisites

-   Windows 10 Laptop with USB A and internet connectivity
-   [python3](https://www.python.org/downloads/), pip3 installed
-   Purchase this controller: https://www.amazon.com.au/8Bitdo-Gamepad-Windows-RetroPie-Raspberry/dp/B07V2P79Z2/ref=sr_1_2?qid=1647615575&refinements=p_4%3A8Bitdo&s=electronics&sr=1-2
-   Open this project in CMD.exe

```bat
:: install dependencies
pip install -r requirements.txt

:: REQUIRED ENVIRONMENT variables

:: New Relic Ingest key
setx NEW_RELIC_LICENSE_KEY enter_nr_ingest_key


:: OPTIONAL ENVIRONMENT variables

:: Number of lives player has, default is 1
setx TOTAL_LIFE 1

:: Start from world number (1 to 8), default is 1
setx START_WORLD 3

:: Title text, default is "-New Relic Demo-" (note: only A-Z and Dash are allowed)
setx GAME_TITLE "- New Relic SKO Demo -"

```

-   Review the [AutoHotKey](https://www.autohotkey.com) scripts

    -   `starthere.ahk`: this will prompt user for their Name, Email and Company Name before they start the game. You can customize the message by changing the `InputBox` (e.g. translate to French for example)
    -   `completed.ahk`: this will show a Dialog message after user completes the game. Again, you can customize the message here

-   Build the `starthere.exe` file by double clicking on the `starthere_build.cmd` file
-   Build the `completed.exe` file by double clicking on the `completed_build.cmd` file
-   Import Super Mario dashboard into New Relic using the `nr_dashboard.json` file, make sure you modify the `"accountId"` field with your accountId

## During the Conference

-   Double clicking on the `StartServer.cmd` file to start listening for events (only need to do this once)
-   Plug in the USB controller
-   Explain the rules to the attendees:
    -   They have only 1 life, if they die, it's game over
    -   Prize will be given to top 3 players who completed the level the fastest
    -   A different prize will be given to top 3 players who completed the level within 1/2 of the time (200 Seconds) and collected most Coins
-   Double clicking on the `starthere.exe` file. They will be prompted to enter their name, email and company name
-   Game will start after they provided those information (user will need to press the `Start` button on the controller)
-   Coins collected and Time remaining stats will be pushed to New Relic and the dashboard should show updates every 5 seconds
-   When user dies or completed the level, the Emulator will be closed and `completed.exe` will be launched automatically (by Python)
-   A dialog will appear thanking user for playing. Click any button will launch `starthere.exe` automatically and the next player can start

## Notes

-   You can start the Emulator in standalone mode by running this command `Mesen.exe /fullscreen smb.nes`
