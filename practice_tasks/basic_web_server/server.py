from BaseHTTPServer import BaseHTTPRequestHandler,HTTPServer
from SocketServer import ThreadingMixIn
from os import curdir, sep
import cgi, sys, re

FILE_FOR_PROCESSING = ""
PATTERN = r'[^\.0-9]'

def read_in_chunks(file_object, chunk_size=1024):
    while True:
        data = file_object.read(chunk_size)
        if not data:
            break
        yield data

class ThreadingServer(ThreadingMixIn, HTTPServer):
	pass

class RequestHandler(BaseHTTPRequestHandler):
	# protocol_version = "HTTP/1.1"
	def do_GET(self):
		if self.path=="/":
			self.path = "/calc.html"
			try:
				f = open(curdir + sep + self.path)
				self.send_response(200)
				self.send_header('Content-type','text/html')
				self.end_headers()
				self.wfile.write(f.read())
				f.close()
				return
			
			except IOError:
				self.send_error(404,'The requested file was not found: %' % self.path)

		elif self.path=="/process_file.html":
			try:
				f = open(curdir + sep + self.path)
				self.send_response(200)
				self.send_header('Content-type','text/html')
				self.end_headers()
				chunks_read = 0
				if FILE_FOR_PROCESSING:
					f = open(FILE_FOR_PROCESSING)
				else:
					raise IOError
				for piece in read_in_chunks(f):
				    chunks_read+=1
				    print "Chunk %d %s" % (chunks_read, (re.search('r[^\.0-1]', piece) == True))

				self.wfile.write("Chunks read: %d" % chunks_read)
				f.close()
				return
			
			except IOError:
				self.send_error(404,'The requested file was not found: %' % self.path)

	def do_POST(self):
		form = cgi.FieldStorage(
			fp=self.rfile, 
			headers=self.headers,
			environ={'REQUEST_METHOD':'POST',
		                 'CONTENT_TYPE':self.headers['Content-Type'],
		}) 

		if self.path=="/send_numbers":
			result = "Your input is bad !!! Please try again !!!"
			if not (re.search(PATTERN, form["first_number"].value) or
					re.search(PATTERN, form["second_number"].value)):
				result = "Result is: " + str(int(form["first_number"].value) + int(form["second_number"].value))

			self.send_response(200)
			self.end_headers()
			self.wfile.write(result)
			return


try:
	if sys.argv[2:]:
		FILE_FOR_PROCESSING = sys.argv[1]
		PORT_NUMBER = int(sys.argv[2])
	elif sys.argv[1:]:
		FILE_FOR_PROCESSING = sys.argv[1]
		PORT_NUMBER = 8080
	else:
		PORT_NUMBER = 8080

	server = ThreadingServer(('', PORT_NUMBER), RequestHandler)
	print 'Started web server on port: ' , PORT_NUMBER
	
	server.serve_forever()

except KeyboardInterrupt:
	print '\n^C received: SHUTTING DOWN'
	server.socket.close()