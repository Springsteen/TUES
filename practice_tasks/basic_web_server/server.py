from BaseHTTPServer import BaseHTTPRequestHandler,HTTPServer
from os import curdir, sep
import cgi, sys

class RequestHandler(BaseHTTPRequestHandler):
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

	def do_POST(self):
		form = cgi.FieldStorage(
			fp=self.rfile, 
			headers=self.headers,
			environ={'REQUEST_METHOD':'POST',
		                 'CONTENT_TYPE':self.headers['Content-Type'],
		}) 

		if self.path=="/send_numbers":
			first_num = int(form["first_number"].value)
			second_num = int(form["second_number"].value)

			self.send_response(200)
			self.end_headers()
			self.wfile.write("The sum is %d !" % (first_num+second_num))
			return


try:
	if sys.argv[1:]:
		PORT_NUMBER = int(sys.argv[1])
	else:
		PORT_NUMBER = 8080

	server = HTTPServer(('', PORT_NUMBER), RequestHandler)
	print 'Started web server on port: ' , PORT_NUMBER
	
	server.serve_forever()

except KeyboardInterrupt:
	print '\n^C received: SHUTTING DOWN'
	server.socket.close()