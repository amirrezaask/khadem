const std = @import("std");
const http = @import("http.zig");

pub const RouteHandler = struct {
    handler: http.server.Handler,
    route: []const u8,
};

pub fn makeRouter(comptime route_handlers: []RouteHandler) type {
    return struct {
        pub fn handler(req: *http.Request, resp: *http.Response) anyerror!void {
            for (route_handlers) |route_handler| {
                if (std.mem.eql(u8, route_handler.route, req.uri)) {
                    return route_handler.handler(req, resp);
                }
            }
            resp.respond(http.Response.Status.NotFound(), null, "Not FOUND");
        }
    };
}
