use tokio::net::{TcpStream, TcpListener};
use std::future::Future;

use super::Error;
use super::Connection;

pub struct Server {}

impl Server {
    async fn handle<'a, F, Output>(socket: TcpStream, handler: &F) -> Result<(), Error>
    where
        F: Fn(Connection) -> Output,
        Output: Future<Output = ()> + Send + Sync,
    {
        let connection = Connection::new(socket).await?;
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
    pub async fn start<'a, F, Fut>(addr: &str, handler: F) -> Result<(), Error>
    where
        F: Send + Sync + 'static,
        F: Fn(Connection) -> Fut,
        Fut: Future<Output = ()> + Send + Sync,
    {
        let listener = TcpListener::bind(addr).await?;
        loop {
            let (socket, _) = listener.accept().await?;
            Server::handle(socket, &handler).await;
        }
    }
}
