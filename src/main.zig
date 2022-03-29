const std = @import("std");
const GeneralPurposeAllocator = std.heap.GeneralPurposeAllocator;
const print = std.debug.print;
const http = @import("http.zig");
const Handler = http.Handler;
const Server = http.Server;

pub const io_mode = .evented;

fn predicate(ctx: *http.Context) anyerror!bool {
    _ = ctx;
    return true;
}

pub fn func_sleep(ctx: *http.Context) anyerror!void {
    _ = async ctx.respond(http.Status.OK, null, "Hello handler sleep");
}

/// Async Webserver : TCP Listener + HTTP protocol + handlers
/// Two ways of using it:
/// 1. Library => create a webserver with config
/// 2. Executable => gets a config file in YAML
pub fn main() anyerror!void {
    var gpa = GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var handlers = std.ArrayList(Handler).init(allocator);
    try handlers.append(http.Handler.init(predicate, func_sleep));

    var server = try Server.init(allocator, .{
        .address = "127.0.0.1",
        .port = 8080,
        .handlers = handlers.items,
    });
    try server.listen();
}
