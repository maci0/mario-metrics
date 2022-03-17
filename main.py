#!/usr/bin/env python3

import os
import time
import atexit
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import urlparse, parse_qsl
from newrelic_telemetry_sdk import Event, EventClient, EventBatch, Harvester

hostName = "0.0.0.0"
serverPort = 8082

# for now this is static, could be provided from a database and detected based on ROM checksum
baseEvent = {
    "gameName":"Super Mario Bros.",
    "gameDeveloper":"Nintendo",
}

#TODO: implement proper checking of events and parameters
def checkEvent(event):
  if not event:
      print("No event")

class MyServer(BaseHTTPRequestHandler):

    def do_GET(self):
        self.close_connection = 1
        if not self.path.startswith( '/event' ):
            print(self.path)
            self.send_response(400)
            self.send_header("Content-type", "text/plain")
            self.end_headers()
            self.connection.close()
        elif self.path.startswith( '/event' ):
            print("Pathinfo: ", self.path)
            self.send_response(200)
            self.send_header("Content-type", "text/plain")
            self.end_headers()
            self.connection.close()
            
            query = urlparse(self.path).query
            qsl = dict(parse_qsl(query))
            print("Parsed query parameters: ", qsl)
            if not qsl:
                print ("qsl data empty")
                return 1
            event = {**baseEvent , **qsl}
            print("Event: ", event)
            event_batch.record(Event("MesenSample", event))
            return 0

    def log_message(self, format, *args):
        return


if __name__ == "__main__":
    webServer = HTTPServer((hostName, serverPort), MyServer)
    print("Server started http://%s:%s" % (hostName, serverPort))

    event_client = EventClient(os.environ["NEW_RELIC_LICENSE_KEY"]) 
    event_batch = EventBatch()
    event_harvester = Harvester(event_client, event_batch)

    # Send any buffered data when the process exits
    atexit.register(event_harvester.stop)

    # Start the harvester background thread
    event_harvester.start()

    try:
        webServer.serve_forever()
    except KeyboardInterrupt:
        pass

    webServer.server_close()
    print("Server stopped.")

