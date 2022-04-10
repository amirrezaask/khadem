use std::{collections::HashMap, ops::Index};
use tokio::io::{AsyncReadExt, AsyncWriteExt};

pub type RequestParseResult = Result<Request, Error>;

pub enum Error {
    ParsingError,
    Utf8Error(std::string::FromUtf8Error),
    IOError(std::io::Error),
}

impl From<std::io::Error> for Error {
    fn from(internal_err: std::io::Error) -> Self {
        Error::IOError(internal_err)
    }
}

impl From<std::string::FromUtf8Error> for Error {
    fn from(internal_err: std::string::FromUtf8Error) -> Self {
        Error::Utf8Error(internal_err)
    }
}
#[derive(Debug)]
pub enum Method {
    GET,
    POST,
    PUT,
    PATCH,
    OPTION,
    DELETE,
}

impl From<&str> for Method {
    fn from(s: &str) -> Self {
        if s == "GET" {
            Method::GET
        } else if s == "POST" {
            Method::POST
        } else {
            Method::GET
        }
    }
}
#[derive(Debug)]
pub enum Version {
    HTTP1_1,
}

impl std::fmt::Display for Version {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Version::HTTP1_1 => f.write_str("HTTP/1.1")
        }
    }
}

impl From<&str> for Version {
    fn from(s: &str) -> Self {
        if s == "HTTP/1.1" {
            Version::HTTP1_1
        } else {
            Version::HTTP1_1
        }
    }
}
pub struct Request {
    pub method: Method,
    pub uri: String,
    pub version: Version,
    pub headers: HashMap<String, String>,
    pub query_params: HashMap<String, String>,
    pub path_params: HashMap<String, String>,
}

impl Request {
    pub async fn new(reader: &mut tokio::net::TcpStream) -> RequestParseResult {
        let mut first_line: String = String::new();
        let mut headers: HashMap<String, String> = HashMap::new();
        let mut buffer: Vec<u8> = std::vec::Vec::new();
        loop {
            let b = reader.read_u8().await?;
            buffer.push(b);
            if b as char == '\n' {
                if first_line.is_empty() {
                    // we are reading first line so buffer is first line content
                    first_line = String::from_utf8(buffer[0..buffer.len()-2].to_vec())?;
                    buffer.clear();
                } else {
                    if buffer.len() == 2 && buffer[0] as char == '\r' {
                        break;
                    }
                    let header_line = String::from_utf8( buffer[0..buffer.len()-2].to_vec())?;
                    buffer.clear();
                    let mut iter = header_line.split(":");
                    let key = match iter.next() {
                        Some(k) => k,
                        None => return Err(Error::ParsingError),
                    };
                    let value = match iter.next() {
                        Some(v) => {
                           if v.chars().nth(0) == Some(' ') {
                               String::from(v)[1..].to_string()
                           }  else {
                                v.to_string()
                           }
                        },
                        None => return Err(Error::ParsingError),
                    };
                    headers.insert(key.to_string(), value.to_string());
                }
            } 
        }
        // /some?name=value
        let mut first_line_iter = first_line.split(" ");
        let method: Method = first_line_iter.next().unwrap().into();
        let uri_iter_next_unwrap = first_line_iter.next().unwrap().to_string();
        let mut uri_iter = uri_iter_next_unwrap.split("?");
        let uri = match uri_iter.next() {
            Some(u) => u,
            None => return Err(Error::ParsingError),
        };
        let mut query_params: HashMap<String, String> = HashMap::new();
        match uri_iter.next() {
            Some(q) => {
                for kv in q.split("&") {
                    let mut iter = kv.split("=");
                    let key = match iter.next() {
                        Some(k) => k,
                        None => return Err(Error::ParsingError),
                    };
                    let value = match iter.next() {
                        Some(k) => k,
                        None => return Err(Error::ParsingError),
                    };
                    query_params.insert(key.to_string(), value.to_string());
                }
            },
            None => (),
        };
        Ok(Request {
            method,
            uri: uri.to_string(),
            version: first_line_iter.next().unwrap().into(),
            headers,
            query_params,
            path_params: HashMap::new(),
        })
    }
}

pub struct Connection {
    pub request: Request,
    pub socket: tokio::net::TcpStream,
}

pub struct StatusCode {
    pub code: usize,
    pub msg: &'static str,
}

impl StatusCode {
    pub fn ok() -> Self {
        StatusCode { code: 200, msg: "OK" }
    }
}


pub struct Response<'a> {
    pub status: StatusCode,
    pub headers: HashMap<String, String>,
    pub body: &'a str,
}

impl Connection {
    pub async fn new(mut socket: tokio::net::TcpStream) -> Result<Connection, Error> {
        let request = Request::new(&mut socket).await?;
        Ok(Connection {
            request, socket
        })
    }

    pub async fn respond<'a>(&mut self, resp: Response<'a>) -> Result<(), std::io::Error> {
        self.socket.write_all(format!("{} {} {}\r\n", self.request.version, resp.status.code, resp.status.msg).as_bytes()).await?;
        print!("{} {} {}\r\n", self.request.version, resp.status.code, resp.status.msg);
        for (k,v) in resp.headers.iter() {
            self.socket.write_all(format!("{}: {}\r\n", k, v).as_bytes()).await?;
            print!("{}: {}\r\n", k, v);
        }

        print!("\r\n");
        self.socket.write_all(b"\r\n").await?;
        if resp.body.len() != 0 {
            self.socket.write_all(resp.body.as_bytes()).await?;
        }
        Ok(())
    }
}
