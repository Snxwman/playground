# Uncomment this to pass the first stage
import socket
from enum import Enum
from typing import Optional


class HTTPMethod(Enum):
    GET = 'GET'


class HTTPStatus(Enum):
    OK = (200, 'OK', 200)
    NOT_FOUND = (404, 'Not Found')


class HTTP:
    line_terminator = '\r\n'
    versions = ['1.1']


class HTTPRequest(HTTP):

    def __init__(self, raw_request):
        raw_request = raw_request.decode().splitlines()
        
        self.method, self.path, self.version = raw_request[0].split() 
        self.base_path = self.path.split('/')[1]

        self.headers: dict = {} 
        for header in raw_request[1:-1]:
            key, value = header.split(':', 1)
            self.headers[key.strip()] = value.strip()

        self.body = raw_request[-1]


class HTTPResponse(HTTP):
    
    def __init__(self, version: str):
        if version in HTTP.versions:
            self.version = version
        else:
            raise(ValueError(f'Unknown HTTP version: {version}'))

        self.status: Optional[HTTPStatus] = None
        self.headers = {}
        self.body: str = ''


    def set_status(self, status: HTTPStatus):
        self.status = status


    def get_status_line(self):
        if self.status is not None:
            return f'HTTP/{self.version} {self.status.value[0]} {self.status.value[1]}'
        else:
            raise ValueError('Status not set')

    
    def get_response_bytes(self):
        status_line = f'{self.get_status_line()}{HTTP.line_terminator}'

        headers = ''
        for key, value in self.headers.items():
            headers += f'{key}: {value}{HTTP.line_terminator}'

        body = f'{self.body}{HTTP.line_terminator}'
        
        return f'{status_line}{headers}{HTTP.line_terminator}{body}'.encode('utf-8')


    def handle_echo(self, path):
        self.body += path.split('/echo/')[1]
        self.headers['Content-Type'] = 'text/plain'
        self.headers['Content-Length'] = len(self.body)


    def handle_user_agent(self, user_agent: str):
        self.body += user_agent 
        self.headers['Content-Type'] = 'text/plain'
        self.headers['Content-Length'] = len(self.body)


def main():
    # You can use print statements as follows for debugging, they'll be visible when running tests.
    print("Logs from your program will appear here!")

    server_socket = socket.create_server(("localhost", 4221), reuse_port=True)
    client_socket, client_address = server_socket.accept() # wait for client
    raw_req = client_socket.recv(4096)
    print(raw_req)
    req: HTTPRequest = HTTPRequest(raw_req)
    res: HTTPResponse = HTTPResponse('1.1')

    paths = ['', 'echo', 'user-agent']

    if req.base_path in paths:
        res.set_status(HTTPStatus.OK)

        if req.base_path == 'echo':
            res.handle_echo(req.path)
        elif req.base_path == 'user-agent':
            res.handle_user_agent(req.headers['User-Agent'])

        client_socket.sendall(res.get_response_bytes())
    else:
        res.set_status(HTTPStatus.NOT_FOUND)
        client_socket.sendall(res.get_response_bytes())


if __name__ == "__main__":
    main()
