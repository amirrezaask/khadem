use std::{io, collections::HashMap};
use tokio::io::AsyncReadExt;
use tokio::net::TcpListener;

mod http;
use http::*;

async fn handle(socket: tokio::net::TcpStream) -> Result<(), Error> {
    let connection = Connection::new(socket).await?;
    println!("method: {:?}\nuri:{:?}\nversion:{:?}\nheaders:{:?}\n", connection.request.method, connection.request.uri, connection.request.version, connection.request.headers);

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
