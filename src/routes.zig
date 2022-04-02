const std = @import("std");
const http = @import("http.zig");
const middleware = @import("middlewares.zig");

pub const RouteHandler = struct {
    handler: http.server.HandlerFn,
    route: []const u8,
    middlewares: []const middleware.Middleware,
};

pub fn Router(comptime route_handlers: []const RouteHandler) type {
    return struct {
        pub fn handler(req: *http.Request, resp: *http.Response) anyerror!void {
            inline for (route_handlers) |route_handler| {
                if (std.mem.eql(u8, route_handler.route, req.uri)) {
                    var final_handler = route_handler.handler;
                    inline for (route_handler.middlewares) |m| {
                        final_handler = m(final_handler).handler;
                    }
                    return final_handler(req, resp);
                }
            }
            try resp.respond(http.Response.Status.NotFound(), null, "Not FOUND");
        }
    };
}
