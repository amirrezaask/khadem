const std = @import("std");
const GeneralPurposeAllocator = std.heap.GeneralPurposeAllocator;
const print = std.debug.print;

const khadem = @import("khadem");
const Request = khadem.Request;
const Response = khadem.Response;
const Server = khadem.Server;
const Handler = khadem.server.Handler;
const RouteHandler = khadem.routes.RouteHandler;
const RouteHandlerFn = khadem.routes.RouteHandlerFn;
const Router = khadem.routes.Router;
const LogRequest = khadem.middlewares.LogRequest;
const Ok = Response.Status.Ok;

pub const io_mode = .evented;

pub fn main() anyerror!void {
    var gpa = GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const handler = comptime Router(&.{ RouteHandlerFn("/", LogRequest(indexHandler)), RouteHandler("/greet/:name", Handler.init(greetHandler)) });

    var server = Server(handler).init(
        allocator,
        .{
            .address = "127.0.0.1",
            .port = 8080,
        },
    );

    try server.listen();
}
fn greetHandler(req: *Request, resp: *Response) anyerror!void {
    try resp.respond(.{.status = Ok, .body = req.getParam("name").?});
}
fn indexHandler(_: *Request, resp: *Response) anyerror!void {
    try resp.respond(.{.status = Ok, .body = "index"});
}
