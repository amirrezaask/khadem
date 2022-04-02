const std = @import("std");
const http = @import("http.zig");
const Handler = http.server.Handler;
const HandlerFn = Handler.Fn;
const middleware = @import("middlewares.zig");

const RouteHandlerTuple = struct {
    handler: Handler,
    route: []const u8,
};

pub fn RouteHandlerFn(comptime path: []const u8, comptime handler_fn: HandlerFn) RouteHandlerTuple {
    return .{
        .handler = Handler.init(handler_fn),
        .route = path,
    };
}

pub fn RouteHandler(comptime path: []const u8, comptime handler: Handler) RouteHandlerTuple {
    return .{
        .handler = handler,
        .route = path,
    };
}

pub fn Router(comptime route_handlers: []const RouteHandlerTuple) Handler {
    const dumb = struct {
        pub fn handler(req: *http.Request, resp: *http.Response) anyerror!void {
            inline for (route_handlers) |route_handler| {
                if (std.mem.eql(u8, route_handler.route, req.uri)) {
                    return route_handler.handler.handler_fn(req, resp);
                }
            }
            try resp.respond(http.Response.Status.NotFound(), null, "Not FOUND");
        }
    };

    return Handler.init(comptime dumb.handler);
}
