const std = @import("std");
const http = @import("http.zig");
const Handler = http.server.Handler;
const Request = http.Request;
const Response = http.Response;
// m1 -> m2 -> m3 -> h -> m3 -> m2 -> m1

pub const Middleware = fn (comptime Handler) Handler;

fn logRequest(req: *Request, _: *Response) anyerror!void {
    req.debugPrintRequest();
}

pub fn LogRequest(comptime handler: Handler) Handler {
    const dumb = struct {
        pub fn handler(req: *Request, resp: *Response) anyerror!void {
            req.debugPrintRequest();
            try handler.handler_fn(req, resp);
        }
    };

    return Handler.init(dumb.handler);
}

pub fn ContentTypeOnly(comptime content_type: []const u8) Middleware {
    const dumb = struct {
        pub fn middleware(comptime input_handler: Handler) Handler {
            return struct {
                pub fn handler(req: *Request, resp: *Response) anyerror!void {
                    if (req.headers.get("Content-Type")) |ct| {
                        if (std.mem.eql(u8, ct, content_type)) {
                            return input_handler.handler_fn(req, resp);
                        }
                    }
                    resp.respond(http.Response.Status.BadRequest, null, "content type is wrong");
                }
            };
        }
    };
    return dumb.middleware;
}
