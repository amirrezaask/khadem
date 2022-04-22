use super::Connection;
use super::Error;
use super::HttpHandler;
use async_trait::async_trait;
use path_tree::PathTree;
use std::collections::HashMap;

#[derive(Clone)]
pub struct Router {
    pub root: PathTree<&'static (dyn HttpHandler + Send + Sync)>,
}

impl Router {
    pub fn new(root_handler: &'static (impl HttpHandler + Sync + Send + Clone)) -> Router {
        let mut root: PathTree<&'static (dyn HttpHandler + Sync + Send)> = PathTree::new();
        root.insert("/", root_handler);
        Router { root }
    }
}

#[async_trait]
impl HttpHandler for Router {
    async fn handle_connection(&self, conn: &mut Connection) -> Result<(), Error> {
        if let handler = self.root.find(&conn.request.uri).unwrap() {
            let mut params = HashMap::<String, String>::new();
            for kv in handler.1.iter() {
                params.insert(kv.0.to_string(), kv.1.to_string());
            }
            conn.request.path_params = params;
            handler.0.handle_connection(conn).await;
            Ok(())
        } else {
            Err(Error::NotFoundError)
        }
    }
}
