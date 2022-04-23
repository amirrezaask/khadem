use super::Connection;
use super::Error;
use async_trait::async_trait;
use tokio::net::{TcpListener, TcpStream};

#[async_trait]
pub trait HttpHandler {
    async fn handle_connection(&self, conn: &mut Connection) -> Result<(), Error>;
}

#[derive(Clone)]
pub struct Server;

impl Server {
    pub fn new() -> Server {
        Server {}
    }
}

impl Server {
    async fn handle<CH>(self, socket: TcpStream, ch: CH) -> Result<(), Error>
    where
        CH: HttpHandler + Send + Sync + 'static,
    {
        let mut connection = Connection::new(socket).await?;
        ch.handle_connection(&mut connection).await;
        Ok(())
    }
    pub async fn start<H>(addr: &str, handler: H) -> Result<(), Error>
    where
        H: HttpHandler + Send + Sync + Clone +'static,
    {
        let listener = TcpListener::bind(addr).await?;
        let server = Server::new();
        loop {
            let server_clone = server.clone();
            let (socket, _) = listener.accept().await?;
            tokio::spawn(server_clone.handle(socket, handler.clone()));
        }
    }
}
