use super::Connection;
use super::Error;
use async_trait::async_trait;
use tokio::net::{TcpListener, TcpStream};

#[async_trait]
pub trait HttpHandler {
    async fn handle_connection(&self, conn: &mut Connection) -> Result<(), Error>;
}

pub struct Server {}

impl Server {
    pub fn new() -> Server {
        Server {}
    }
}

pub struct LogMiddleware<CH>
where
    CH: HttpHandler,
{
    pub wrapped: CH,
}

#[async_trait]
impl<CH> HttpHandler for LogMiddleware<CH>
where
    CH: HttpHandler + Sync + Send,
{
    async fn handle_connection(&self, connection: &mut Connection) -> Result<(), Error> {
        println!(
            "method: {:?}\nuri:{:?}\nversion:{:?}\nheaders:{:?}\n",
            connection.request.method,
            connection.request.uri,
            connection.request.version,
            connection.request.headers
        );

        self.wrapped.handle_connection(connection).await
    }
}

impl Server {
    async fn handle<CH>(&self, socket: TcpStream, ch: &CH) -> Result<(), Error>
        where
            CH: HttpHandler + Send + Sync,
        {
            let mut connection = Connection::new(socket).await?;
            ch.handle_connection(&mut connection).await;
            Ok(())
    }
    pub async fn start<H>(addr: &str, handler: H) -> Result<(), Error>
    where
        H: HttpHandler + Send + Sync,
    {
        let listener = TcpListener::bind(addr).await?;
        let server = Server::new();
        loop {
            let (socket, _) = listener.accept().await?;
            match server.handle(socket, &handler).await {
                Ok(()) => (),
                Err(err) => println!("error in handling request: {:?}", err)
            };
        }
    }
}
