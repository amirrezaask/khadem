use super::Connection;
use super::Error;
use super::HttpHandler;
use async_trait::async_trait;

#[derive(Clone)]
pub struct LogMiddleware<CH>
where
    CH: super::HttpHandler,
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
