use super::HttpHandler;
use super::Error;
use super::Connection;
use async_trait::async_trait;
use radix_tree::{Node, Radix};

#[derive(Clone)]
pub struct Router {
   pub root:  Node<char, &'static (dyn HttpHandler + Send + Sync)>
}

impl Router {
   pub fn new(root_handler: &'static (impl HttpHandler + Sync + Send + Clone) ) -> Router {
        Router {root: Node::new("/", Some(root_handler))}
   }
}

#[async_trait]
impl HttpHandler for Router {
    async fn handle_connection(&self, conn: &mut Connection) -> Result<(), Error> {
       if let handler = self.root.find(conn.request.uri.clone()).unwrap()  {
            handler.data.unwrap().handle_connection(conn).await;
            Ok(())
       } else {
            Err(Error::NotFoundError)
       }
    }
}
