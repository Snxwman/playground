# Uncomment this to pass the first stage
import argparse
import gzip
import os
import socket
import threading
from enum import Enum
from typing import Optional


class HTTPMethod(Enum):
    GET = 'GET'
    POST = 'POST'

    @staticmethod
    def from_string(method):
        match method:
            case 'GET':
                return HTTPMethod.GET
            case 'POST':
                return HTTPMethod.POST
            case _:
                raise(ValueError(f'Unkown HTTP method: {method}'))


class HTTPStatus(Enum):
    OK = (200, 'OK')
    CREATED = (201, 'Created')
    NOT_FOUND = (404, 'Not Found')


class HTTP:
    line_terminator = '\r\n'
    versions = ['1.1']
    valid_encodings = ['gzip']


class HTTPRequest(HTTP):

    def __init__(self, raw_request):
        raw_request = raw_request.decode().split(HTTP.line_terminator)
        
        method, self.path, self.version = raw_request[0].split()
        self.method = HTTPMethod.from_string(method)
        self.base_path = self.path.split('/')[1]

        self.headers: dict = {} 
        self.encoding_method = None
        for header in raw_request[1:-2]:
            key, value = header.split(':', 1)
            self.headers[key.strip()] = value.strip()
            
            if key == 'Accept-Encoding':
                for v in value.split(','):
                    if v.strip() in HTTP.valid_encodings:
                        self.encoding_method = v.strip()

        self.body = raw_request[-1]


class HTTPResponse(HTTP):
    
    def __init__(self, version: str, req: HTTPRequest):
        if version in HTTP.versions:
            self.version = version
        else:
            raise(ValueError(f'Unknown HTTP version: {version}'))

        self.status: Optional[HTTPStatus] = None
        self.headers = {}
        self.body: str = ''

        self.encoding_method = None
        if req.encoding_method is not None:
            self.headers['Content-Encoding'] = req.encoding_method
            self.encoding_method = req.encoding_method


    def set_status(self, status: HTTPStatus):
        self.status = status


    def get_status_line(self):
        if self.status is not None:
            return f'HTTP/{self.version} {self.status.value[0]} {self.status.value[1]}'
        else:
            raise ValueError('Status not set')

    
    def get_response_bytes(self):
        status_line = f'{self.get_status_line()}{HTTP.line_terminator}'

        match self.encoding_method:
            case 'gzip':
                body = gzip.compress(self.body.encode('utf-8'))
                self.headers['Content-Length'] = len(body)
                print(body)
            case _:
                body = f'{self.body}'.encode('utf-8')

        headers = ''
        for key, value in self.headers.items():
            headers += f'{key}: {value}{HTTP.line_terminator}'
          
        res: bytearray = bytearray()
        res.extend(status_line.encode('utf-8'))
        res.extend(headers.encode('utf-8'))
        res.extend(f'{HTTP.line_terminator}'.encode('utf-8'))
        res.extend(body)
        res.extend(f'{HTTP.line_terminator}'.encode('utf-8'))

        return res 


    def handle_echo(self, path):
        self.body += path.split('/echo/')[1]
        self.headers['Content-Type'] = 'text/plain'
        self.headers['Content-Length'] = len(self.body)


    def handle_user_agent(self, user_agent: str):
        self.body += user_agent 
        self.headers['Content-Type'] = 'text/plain'
        self.headers['Content-Length'] = len(self.body)


    def handle_get_files(self, directory, path):
        file = f'{directory}/{path.split('/files/')[1]}'
        
        if os.path.isfile(file):
            with open(file, 'r') as f:
                self.body = f.read()
        else:
            self.status = HTTPStatus.NOT_FOUND

        self.headers['Content-Type'] = 'application/octet-stream'
        self.headers['Content-Length'] = len(self.body)


    def handle_post_file(self, directory, path, contents):
        filepath = f'{directory}/{path.split('/files/')[1]}'
        print(self.body)
        with open(filepath, 'w') as f:
            f.write(str(contents))

        self.status = HTTPStatus.CREATED



def request_handler(client_socket, client_address):
    raw_req = client_socket.recv(4096)
    req: HTTPRequest = HTTPRequest(raw_req)
    res: HTTPResponse = HTTPResponse('1.1', req)

    if req.base_path in paths:
        res.set_status(HTTPStatus.OK)

        match req.base_path:
            case 'echo':
                res.handle_echo(req.path)
            case 'user-agent':
                res.handle_user_agent(req.headers['User-Agent'])
            case 'files':
                match req.method:
                    case HTTPMethod.GET:
                        res.handle_get_files(args.directory, req.path)
                    case HTTPMethod.POST:
                        res.handle_post_file(args.directory, req.path, req.body)


        client_socket.sendall(res.get_response_bytes())
    else:
        res.set_status(HTTPStatus.NOT_FOUND)
        client_socket.sendall(res.get_response_bytes())


def main():
    server_socket = socket.create_server(("localhost", 4221), reuse_port=True)

    while True:
        client_socket, client_address = server_socket.accept() # wait for client
        threading.Thread(target=request_handler, args=(client_socket, client_address)).start()


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('--directory')
    args = parser.parse_args()

    paths = ['', 'echo', 'user-agent', 'files']

    main()
