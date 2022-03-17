#!/usr/bin/env python3
import requests
import time
import random

players = { 
    "d8677e10-0e73-410c-8c27-6c2cbaa75f26": "James",
    "496a34d5-c9c1-4e3b-bfaf-3d2e24a213ae": "Mike",
    "9a25904f-debd-4b96-b1a2-fd95da87701e": "Felix",
    "18c8aab8-9d67-4b11-a55d-7eb9e95b58a6": "Robert",
    "19372e67-97e6-4a00-b24e-5f17930ce83e": "Winona",
    "ec73ab11-bd71-4c5f-97b1-8a01041c62ca": "Elsie",
    "c0ddcbac-b0a9-42b0-b665-0dd37a1e104b": "Dwayne",
    "63478de3-ce7d-461e-9d6b-877256984e46": "Colin",
    "228988b1-16ae-4c31-8870-e59349324271": "Rosa",
    "7388b96f-f256-4196-85a2-30dafabc6b28": "Emily",
    "bc3f32df-192d-4329-8b5e-45adbe44c9ef": "Alvin",
    "d75b0ada-df06-43e2-b4c6-3b0f9af41ccd": "Gale"
    }
events = [
    "star",
    "death",
    "flower",
    "mushroom",
    "levelstart",
    "coin",
    "hit"
    ]

levels = [
    1,
    2,
    3,
    4
    ]

worlds = [
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    8
    ]

while True:
    player = random.choice(list(players.items()))
    event = random.choices(events,weights=(10,10,20,80,30,100,5))
    level = random.choices(levels, weights=(4,3,2,1))
    world = random.choices(worlds, weights=(12,7,6,5,4,3,2,1))

    print(player[0], player[1], event[0], world[0],'-',level[0])
    r =requests.get('http://localhost:8082/event?gameEvent=' + event[0] + '&playerName=' + player[1] + '&playerId=' + player[0] + '&gameLevel=' + str(world[0]) + '-' + str(level[0]))
    time.sleep(random.randint(0,5))

