use std::{collections::HashMap, io};
use async_trait::async_trait;

mod http;
use http::*;

/*
    - user defined handlers[x]
    - middlewares [x]
    - radix tree routing -> path parameters feature
*/


struct CustomHandler {}
#[async_trait]
impl HttpHandler for CustomHandler {
    async fn handle_connection(&self, conn: &mut Connection) -> Result<(), Error> {
        conn.respond(Response {
            status: StatusCode::ok(),
            headers: HashMap::new(),
            body: "Hello From Custom handler",
        })
        .await
    }
}

#[tokio::main]
async fn main() -> io::Result<()> {
    Server::start("127.0.0.1:8080", LogMiddleware{wrapped: CustomHandler{}}).await;
    Ok(())
}
