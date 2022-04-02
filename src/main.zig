const std = @import("std");
const GeneralPurposeAllocator = std.heap.GeneralPurposeAllocator;
const print = std.debug.print;

// const regex = @import("regex");
const http = @import("http.zig");
const Request = http.Request;
const Response = http.Response;
const Server = http.Server;
const routes = @import("routes.zig");
const RouteHandler = routes.RouteHandler;
const Router = routes.Router;
const middlewares = @import("middlewares.zig");
const LogRequest = middlewares.LogRequest;

pub const io_mode = .evented;

/// Async Webserver : TCP Listener + HTTP protocol + handlers
/// Two ways of using it:
/// 1. Library => create a webserver with config
/// 2. Executable => gets a config file in YAML
pub fn main() anyerror!void {
    var gpa = GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    const handler = Router(&.{RouteHandler{ .handler = LogRequest(indexHandler).handler, .route = "/" }}).handler;

    var server = Server(handler).init(
        allocator,
        .{
            .address = "127.0.0.1",
            .port = 8080,
        },
    );

    try server.listen();
}
fn aboutHandler(_: *Request, resp: *Response) anyerror!void {
    try resp.respond(Response.Status.Ok(), null, "about");
}
fn indexHandler(_: *Request, resp: *Response) anyerror!void {
    try resp.respond(Response.Status.Ok(), null, "index");
}

// test "regex test" {
//     _ = @import("cli");
//     const input = "/amirreza";
//     const re = regex.compile("\\/(?<name>.*)\\/?");
//     const captures = regex.captures(re, input);
//     std.testing.expect(captures == null);
// }
