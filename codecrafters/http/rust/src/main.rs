#![allow(unused_variables)]
#![allow(dead_code)]

use std::collections::HashMap;
use std::env;
use std::fs;
use std::fs::File;
use std::io::{BufRead, BufReader, Write};
use std::net::{TcpListener, TcpStream};
use std::path;
use std::path::Path;
use std::thread;

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
        let buf = BufReader::new(&mut stream);

        let req: Vec<_> = buf
            .lines()
            .map(|result| result.unwrap())
            .collect();

        // println!("{:?}", &req);
        let headers = HTTPHeaders::new(req[1..(req.len()-2)].to_vec());
        let (method, path, version) = parse_request_line(req[0].clone());
        let body = req.last().expect("Empty request").to_owned();

        Ok(HTTPRequest { method, path, version, headers, body })
    }
}

#[derive(Debug)]
struct HTTPResponse {
    pub status: HTTPStatus,
    pub version: String,
    pub headers: HTTPHeaders,
    pub body: String,
}

impl HTTPResponse {
    fn new(status: HTTPStatus, req: &HTTPRequest) -> Result<HTTPResponse, std::io::Error> {
        let version = String::from("HTTP/1.1");
        let headers = HTTPHeaders::new(["".to_string()].to_vec());
        let body = String::new();

        Ok(HTTPResponse { status, version, headers, body })
    }

    fn get_response_bytes(&self) -> Box<[u8]> {
        let mut response = String::new();
        response.push_str(
            format!("{} {} {}\r\n", 
                &self.version, 
                &self.status.code().to_string(), 
                &self.status.message())
                .as_str());

        for (key, value) in self.headers.headers.clone().into_iter() {
            response.push_str(format!("{key}: {value}").as_str());
            response.push_str("\r\n");     
        }

        response.push_str("\r\n");
        response.push_str(&self.body);

        response.as_bytes().into()
    }
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

fn handle_get_file(req: &HTTPRequest, res: &mut HTTPResponse) {
    let path = req.path.clone().strip_prefix("/files/").to_owned(); 
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

fn handle_post_file(req: &HTTPRequest, res: &mut HTTPResponse) {

}

fn handle_request(mut stream: TcpStream) -> Result<(), std::io::Error> {
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
                HTTPMethod::Get => handle_get_file(&req, &mut res),
                HTTPMethod::Post => handle_post_file(&req, &mut res),
            }
        },
        "/user-agent" => handle_user_agent(&req, &mut res),
        _ => ()
    }
    
    println!("{:#?}", &res);
    let res_bytes = res.get_response_bytes();
    // println!("{}", String::from_utf8_lossy(&res_bytes));
    stream.write_all(&res_bytes)?;

    Ok(())
}

fn parse_request_line(line: String) -> (HTTPMethod, String, String) {
    let parts: Vec<_> = line
        .split(' ')
        .map(|part| part.trim())
        .collect();

    (HTTPMethod::from_str(parts[0]), parts[1].to_string(), parts[2].to_string())
}

static mut DIR: String = String::new();
fn main() {

    let listener = TcpListener::bind("127.0.0.1:4221").unwrap();

    for stream in listener.incoming() {
        match stream {
            Ok(mut _stream) => {
                thread::spawn(|| handle_request(_stream));
            }
            Err(e) => {
                println!("error: {}", e);
            }
        }
    }
}
