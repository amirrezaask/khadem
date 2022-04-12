use std::{collections::HashMap, future::Future, io};
use tokio::net::TcpListener;

mod http;
use http::*;

/*
    - user defined handlers[x]
    - middlewares
    - radix tree routing -> path parameters feature
*/

async fn handle<'a, F, Fut>(socket: tokio::net::TcpStream, handler: &F) -> Result<(), Error>
where
    F: Send + Sync + 'static,
    F: Fn(Connection) -> Fut,
    Fut: Future<Output = ()> + Send + Sync,
{
    let mut connection = Connection::new(socket).await?;
    println!(
        "method: {:?}\nuri:{:?}\nversion:{:?}\nheaders:{:?}\n",
        connection.request.method,
        connection.request.uri,
        connection.request.version,
        connection.request.headers
    );
    handler(connection).await;
    Ok(())
}

struct Server {}

impl Server {
    pub async fn start<'a, F, Fut>(addr: &str, handler: F) -> Result<(), Error>
    where
        F: Send + Sync + 'static,
        F: Fn(Connection) -> Fut,
        Fut: Future<Output = ()> + Send + Sync,
    {
        let listener = TcpListener::bind(addr).await?;
        loop {
            let (socket, _) = listener.accept().await?;
            handle(socket, &handler).await;
        }
    }
}

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
