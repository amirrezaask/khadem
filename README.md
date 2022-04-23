# Khadem
Khadem is a web server library I implemented in both Rust and Zig to compare them in terms of complexity of the code base for the same project.

# Rust Implementation
In Rust implementation we use `tokio` for Async IO and networking and based on that we create a simple HTTP/1.1 parser and a simple trait `HttPHandler` to be impelmented by users or 3rd party libs to handle incoming traffic. We also have build upon `HttpHandler` trait a radix based router to match uri against pre defined routes to call appropriate handler.

# Zig Implementation
In Zig implementation we used zig's own std lib `StreamServer` for TCP server and we did create a simple HTTP/1.1 parser and radix tree data structure to do the routing in and also a contract for middlewares.
