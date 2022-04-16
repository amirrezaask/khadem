use std::{collections::HashMap, future::Future, io};
use tokio::net::TcpListener;
use tokio::net::TcpStream;

mod http;
use http::*;

/*
    - user defined handlers[x]
    - middlewares
    - radix tree routing -> path parameters feature
*/



async fn custom_handler(mut conn: Connection) -> () {
    conn.respond(Response {
        status: StatusCode::ok(),
        headers: HashMap::new(),
        body: "Hello From Custom handler",
    })
    .await;
}
#[tokio::main]
async fn main() -> io::Result<()> {
    Server::start("127.0.0.1:8080", custom_handler).await;
    Ok(())
}
