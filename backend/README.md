# Basic backend to test the ReScript app

This is a basic backend to test the ReScript app. It's written in Python 3 / Django and
uses a sqlite DB.

## Installation
- `cd backend`
- install Python 3 including its venv module and pip: `apt install python3-venv python3-pip`
- create a virtual env: `python3 -m venv venv`
- activate it: `source venv/bin/activate`
- install dependencies: `pip install -r requirements.txt`
- initialize database: `./manage.py migrate`
- load the example data: `./manage.py loaddata messagearea`
- start the server: `./manage.py runserver 8000`

**Note (1):** the backend/API server must run on port 8000, the frontend/ReScript app must run on port 8002
(if you want to use a different port, change `CORS_ORIGIN_WHITELIST` in `backend/settings.py` accordingly.

**Note (2):** the frontend/ReScript app uses an empty string as the API base URL by default.
In order to use this example backend (which runs on a different port) you need to edit `src/ConversationData.res`
and change `isProd` to `false`.


## Subsequent runs
- `cd backend`
- activate virtual env: `source venv/bin/activate`
- start the server: `./manage.py runserver 8000`


## This backend sucks
I know, I quickly hacked it up in half an hour making it as short and simple to run as possible whilst
staying compatible with the real API (which is ~10x the size).

Support for attachments is also missing from this simple backend.
