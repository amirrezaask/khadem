use std::{io, collections::HashMap};
use tokio::io::AsyncReadExt;
use tokio::net::TcpListener;

mod http;
use http::*;

async fn handle(socket: tokio::net::TcpStream) -> Result<(), Error> {
    let mut connection = Connection::new(socket).await?;
    println!("method: {:?}\nuri:{:?}\nversion:{:?}\nheaders:{:?}\n", connection.request.method, connection.request.uri, connection.request.version, connection.request.headers);
    let mut resp_headers: HashMap<String, String> = HashMap::new();
    // resp_headers.insert("Content-Length".to_string(), "0".to_string());
    connection.respond(Response {
        status: StatusCode::ok(),
        headers: resp_headers,
        body: &String::from("Salam"),
    }).await?;
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
