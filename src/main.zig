const std = @import("std");
const GeneralPurposeAllocator = std.heap.GeneralPurposeAllocator;
const print = std.debug.print;

const http = @import("http.zig");
const Request = http.Request;
const Response = http.Response;
const Server = http.Server;
const routes = @import("routes.zig");
const RouteHandler = routes.RouteHandler;
const makeRouter = routes.makeRouter;

pub const io_mode = .evented;

/// Async Webserver : TCP Listener + HTTP protocol + handlers
/// Two ways of using it:
/// 1. Library => create a webserver with config
/// 2. Executable => gets a config file in YAML
pub fn main() anyerror!void {
    var gpa = GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    const routes_handlers = [_]RouteHandler{
        RouteHandler{ .handler = indexHandler, .route = "/" },
        RouteHandler{ .handler = aboutHandler, .route = "/about" },
    };
    var handler = makeRouter(&routes_handlers).handler;

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
