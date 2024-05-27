#![allow(unused_variables)]
#![allow(dead_code)]

use std::collections::HashMap;
use std::{env, u64};
use std::fs::{self, File};
use std::io::{BufRead, BufReader, Read, Write};
use std::net::{TcpListener, TcpStream};

use flate2::write::GzEncoder;
use flate2::Compression;
use nom::{AsBytes, HexDisplay};

#[derive(Debug)]
enum HTTPMethod {
    Get,
    Post,
}

impl HTTPMethod {
    pub fn from_str(method: &str) -> HTTPMethod {
        match method {
            "GET" => HTTPMethod::Get,
            "POST" => HTTPMethod::Post,
            _ => unreachable!()
        }
    }
}

#[derive(Debug)]
enum HTTPStatus {
    Ok,
    Created,
    NotFound,
}

impl HTTPStatus {
    pub fn code(&self) -> u16 {
        match *self {
            HTTPStatus::Ok => 200,
            HTTPStatus::Created => 201,
            HTTPStatus::NotFound => 404,
        }
    }

    pub fn message(&self) -> String {
        match *self {
            HTTPStatus::Ok => String::from("OK"),
            HTTPStatus::Created => String::from("Created"),
            HTTPStatus::NotFound => String::from("Not Found"),
        }
    }
}

#[derive(Debug)]
struct HTTPHeaders {
    headers: HashMap<String, String>,
}

impl HTTPHeaders {
    fn new(raw_headers: Vec<String>) -> HTTPHeaders {
        let mut headers: HashMap<String, String> = HashMap::new();

        for raw_header in raw_headers {
            match raw_header.split_once(':') {
                Some(pair) => headers.insert(String::from(pair.0.trim()), String::from(pair.1.trim())),
                None => None,
            };
        }

        HTTPHeaders { headers }
    }

    pub fn get(&self, key: &str) -> Option<&String> {
        self.headers.get(key)
    }

    pub fn set(&mut self, key: String, value: String) -> Option<String> {
        self.headers.insert(key, value)
    }
}

#[derive(Debug)]
struct HTTPRequest {
    pub method: HTTPMethod,
    pub path: String,
    pub version: String,
    pub headers: HTTPHeaders,
    pub body: String,
}

impl HTTPRequest {
    fn new(mut stream: TcpStream) -> Result<HTTPRequest, std::io::Error> {
        let mut buf = BufReader::new(&mut stream);
            
        let req: Vec<_> = buf
            .by_ref()
            .lines()
            .map(|result| result.unwrap())
            .take_while(|line| !line.is_empty())
            .collect();

        let (method, path, version) = parse_request_line(req[0].clone());
        let headers = HTTPHeaders::new(req[1..].to_vec());

        if headers.headers.get("Content-Length").is_some() {
            let content_length: u64 = headers.headers.get("Content-Length").unwrap().parse().unwrap();

            let mut buffer = [0; 4096];
            let mut handle = buf.take(content_length);
            let _ = handle.read(&mut buffer)?;

            let body = &buffer[0 .. content_length as usize];
            let body = String::from_utf8_lossy(body).to_string();

            return Ok(HTTPRequest { method, path, version, headers, body })
        }

        Ok(HTTPRequest { method, path, version, headers, body: String::new() })
    }
}

#[derive(Debug)]
struct HTTPResponse {
    pub status: HTTPStatus,
    pub version: String,
    pub headers: HTTPHeaders,
    pub body: String,
    pub encoded_body: Vec<u8>,
}

impl HTTPResponse {
    fn new(status: HTTPStatus, req: &HTTPRequest) -> Result<HTTPResponse, std::io::Error> {
        let version = String::from("HTTP/1.1");
        let mut headers = HTTPHeaders::new(["".to_string()].to_vec());
        
        if let Some(req_encodings) = req.headers.get("Accept-Encoding") {
            let req_encodings = req_encodings.split(", ");

            for encoding in req_encodings {
                match encoding {
                    "gzip" => headers.set("Content-Encoding".to_string(), "gzip".to_string()),
                    _ => continue
                };
            }
        }

        let body = String::new();

        Ok(HTTPResponse { status, version, headers, body, encoded_body: Vec::new() })
    }

    fn get_response_bytes(&mut self) -> Vec<u8> {
        let mut response = String::new();
        response.push_str(
            format!("{} {} {}\r\n", 
                &self.version, 
                &self.status.code().to_string(), 
                &self.status.message())
                .as_str());

        if let Some(content_header) = self.headers.get("Content-Encoding") {
            self.encode_body();
        }

        for (key, value) in self.headers.headers.clone().into_iter() {
            response.push_str(format!("{key}: {value}").as_str());
            response.push_str("\r\n");     
        }

        response.push_str("\r\n");

        if self.encoded_body.is_empty() {
            response.push_str(&self.body);
            response.push_str("\r\n");
            response.as_bytes().into()
        } else {
            let response: Vec<u8> = [response.as_bytes(), &self.encoded_body.as_bytes(), "\r\n".as_bytes()].concat();
            response
        }

    }

    fn encode_body(&mut self) {
        let mut encoder = GzEncoder::new(Vec::new(), Compression::default());
        let _ = encoder.write(self.body.as_bytes()).unwrap();

        let encoded_bytes: Vec<u8> = encoder.finish().unwrap();
        let hex_bytes: String = encoded_bytes.iter()
            .map(|b| format!("{:02x}", b).to_string())
            .collect::<String>();
         
        self.encoded_body = encoded_bytes;
        self.headers.set("Content-Length".to_string(), self.encoded_body.len().to_string());
        self.status = HTTPStatus::Ok;
    }
}

fn handle_request(mut stream: TcpStream, config: String) -> Result<(), std::io::Error> {
    let req = HTTPRequest::new(stream.try_clone()?)?;
    println!("{:#?}", &req);

    let mut res = match req.path.as_str() {
        path if path.starts_with("/echo/") => HTTPResponse::new(HTTPStatus::Ok, &req)?,
        path if path.starts_with("/files/") => HTTPResponse::new(HTTPStatus::Ok, &req)?,
        "/user-agent" => HTTPResponse::new(HTTPStatus::Ok, &req)?,
        "/" => HTTPResponse::new(HTTPStatus::Ok, &req)?,
        _ => HTTPResponse::new(HTTPStatus::NotFound, &req)?,
    };

    match req.path.as_str() {
        path if path.starts_with("/echo/") => handle_echo(&req, &mut res),
        path if path.starts_with("/files/") => {
            match req.method {
                HTTPMethod::Get => handle_get_file(&req, &mut res, config),
                HTTPMethod::Post => handle_post_file(&req, &mut res, config),
            }
        },
        "/user-agent" => handle_user_agent(&req, &mut res),
        _ => ()
    }
    
    let res_bytes = res.get_response_bytes();
    println!("{:#?}", &res);
    println!("{}", String::from_utf8_lossy(&res_bytes));
    stream.write_all(res_bytes.as_bytes())?;

    Ok(())
}

fn handle_echo(req: &HTTPRequest, res: &mut HTTPResponse) {
    res.body = req.path.strip_prefix("/echo/").expect("Nothing to echo").to_owned();
    res.headers.set("Content-Type".to_string(), "text/plain".to_string());
    res.headers.set("Content-Length".to_string(), res.body.len().to_string());
}

fn handle_user_agent(req: &HTTPRequest, res: &mut HTTPResponse) {
    res.body = req.headers.get("User-Agent").expect("No User-Agent set").to_owned();
    res.headers.set("Content-Type".to_string(), "text/plain".to_string());
    res.headers.set("Content-Length".to_string(), res.body.len().to_string());
}

fn handle_get_file(req: &HTTPRequest, res: &mut HTTPResponse, path: String) {
    let path = req.path.replace("/files/", &path); 
    let file = fs::read_to_string(path);
    match file {
        Ok(file) => {
            res.body = file;
        },
        Err(e) => {
            res.status = HTTPStatus::NotFound
        }
    }

    res.headers.set("Content-Type".to_string(), "application/octet-stream".to_string());
    res.headers.set("Content-Length".to_string(), res.body.len().to_string());
}

fn handle_post_file(req: &HTTPRequest, res: &mut HTTPResponse, config: String) {
    let path = req.path.replace("/files/", &config);
    let mut file = File::create(path).unwrap();
    let _ = file.write_all(req.body.as_bytes());

    res.status = HTTPStatus::Created
}

fn parse_request_line(line: String) -> (HTTPMethod, String, String) {
    let parts: Vec<_> = line
        .split(' ')
        .map(|part| part.trim())
        .collect();

    (HTTPMethod::from_str(parts[0]), parts[1].to_string(), parts[2].to_string())
}

fn main() {
    let args: Vec<String> = env::args().collect();
    let mut dir = String::new();
    
    if args.len() == 3 {
        dir = args[2].to_owned();
    }

    let listener = TcpListener::bind("127.0.0.1:4221").unwrap();

    for stream in listener.incoming() {
        match stream {
            Ok(mut _stream) => {
                let config = dir.clone();
                let t = std::thread::spawn(move || handle_request(_stream, config));
            }
            Err(e) => {
                println!("error: {}", e);
            }
        }
    }
}
