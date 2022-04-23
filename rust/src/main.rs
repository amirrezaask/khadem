use async_trait::async_trait;
use std::{collections::HashMap, io};

mod http;
use http::*;

/*
    - user defined handlers[x]
    - middlewares [x]
    - radix tree routing -> path parameters feature [x]
*/

#[derive(Clone)]
struct CustomHandler {
    msg: &'static str,
}
#[async_trait]
impl HttpHandler for CustomHandler {
    async fn handle_connection(&self, conn: &mut Connection) -> Result<(), Error> {
        if let Some(name) = conn.request.path_params.get("name") {
            println!("name {}", name);
        }
        conn.respond(Response {
            status: StatusCode::ok(),
            headers: HashMap::new(),
            body: self.msg,
        })
        .await
    }
}

#[tokio::main]
async fn main() -> io::Result<()> {
    let mut router = Router::new(&CustomHandler { msg: "Root" });
    router.root.insert("/bye", &CustomHandler { msg: "bye" });
    router
        .root
        .insert("/hello/:name", &CustomHandler { msg: "hello" });
    Server::start("127.0.0.1:8080", LogMiddleware { wrapped: router }).await;
    Ok(())
}
