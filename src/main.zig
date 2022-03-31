const std = @import("std");
const GeneralPurposeAllocator = std.heap.GeneralPurposeAllocator;
const print = std.debug.print;
const http = @import("http.zig");
const Request = @import("Request.zig");
const Response = @import("Response.zig");

const Server = http.Server;

pub const io_mode = .evented;

/// Async Webserver : TCP Listener + HTTP protocol + handlers
/// Two ways of using it:
/// 1. Library => create a webserver with config
/// 2. Executable => gets a config file in YAML
pub fn main() anyerror!void {
    var gpa = GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var server = Server(handler).init(
        allocator,
        .{
            .address = "127.0.0.1",
            .port = 8080,
        },
    );

    try server.listen();
}

fn handler(req: *Request, resp: *Response) anyerror!void {
    if (std.mem.eql(u8, req.uri, "/sleep")) std.time.sleep(std.time.ns_per_s * 5);
    try resp.respond(http.Status.Ok(), null, "some");
}
