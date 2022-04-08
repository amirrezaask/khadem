use tokio::io::AsyncReadExt;
use tokio::{net::TcpListener, io::AsyncWriteExt};
use std::io;
use std::collections::HashMap;

type RequestParseResult = std::io::Result<Request>;

enum Method{
    GET,
    POST,
    PUT,
    PATCH,
    OPTION,
    DELETE
}

enum Version {
    HTTP1_1,
}
struct Request {
    method: Method,
    uri: String,
    version: Version,
    headers: HashMap<String, String>,
    query_params: HashMap<String, String>,
    path_params: HashMap<String, String>,
    reader: tokio::net::TcpStream,
}
impl Request {
    pub async fn new(mut reader: tokio::net::TcpStream) -> RequestParseResult {
        let mut buffer: Vec<u8> = std::vec::Vec::new();
        let mut lines: Vec<String> = std::vec::Vec::new(); 
        loop {
            let b = reader.read_u8().await?;
            buffer.push(b);
            if b as char == '\n' {
                lines.push(String::from_utf8(buffer)?);
                buffer.clear();
            }
        }
        // Ok(Request{})

    }
}

async fn handle(mut socket: tokio::net::TcpStream) -> io::Result<()> {
    socket.write_all(b"Hello World From Rust").await?;
    Ok(())
}

#[tokio::main]
async fn main() -> io::Result<()> {
    let listener = TcpListener::bind("127.0.0.1:8080").await?;

    loop {
        let (socket, _) = listener.accept().await?;
        handle(socket).await;
    }
}

