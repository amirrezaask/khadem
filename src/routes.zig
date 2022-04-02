const std = @import("std");
const http = @import("http.zig");
const Handler = http.server.Handler;
const HandlerFn = Handler.Fn;
const middleware = @import("middlewares.zig");

pub const RouteHandler = struct {
    handler: HandlerFn,
    route: []const u8,
    // middlewares: []const middleware.Middleware,
};

pub fn Router(comptime route_handlers: []const RouteHandler) Handler {
    const dumb = struct {
        pub fn handler(req: *http.Request, resp: *http.Response) anyerror!void {
            inline for (route_handlers) |route_handler| {
                if (std.mem.eql(u8, route_handler.route, req.uri)) {
                    // var final_handler = route_handler.handler;
                    // inline for (route_handler.middlewares) |m| {
                    //     final_handler = m(final_handler).handler;
                    // }
                    return route_handler.handler(req, resp);
                }
            }
            try resp.respond(http.Response.Status.NotFound(), null, "Not FOUND");
        }
    };

    return Handler.init(comptime dumb.handler);
}
