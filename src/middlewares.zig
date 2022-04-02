const std = @import("std");
const http = @import("http.zig");
const HandlerFn = http.server.HandlerFn;
const Request = http.Request;
const Response = http.Response;
// m1 -> m2 -> m3 -> h -> m3 -> m2 -> m1

pub const Middleware = fn (comptime HandlerFn) type;

fn logRequest(req: *Request, _: *Response) anyerror!void {
    req.debugPrintRequest();
}

pub fn LogRequest(comptime handler: HandlerFn) type {
    return struct {
        pub fn handler(req: *Request, resp: *Response) anyerror!void {
            req.debugPrintRequest();
            try handler(req, resp);
        }
    };
}

pub fn ContentTypeOnly(comptime content_type: []const u8) Middleware {
    return struct {
        pub fn middleware(comptime handler: HandlerFn) type {
            return struct {
                pub fn handler(req: *Request, resp: *Response) anyerror!void {
                    if (req.headers.get("Content-Type")) |ct| {
                        if (std.mem.eql(u8, ct, content_type)) {
                            return handler(req, resp);
                        }
                    }
                    resp.respond(http.Response.Status.BadRequest, null, "content type is wrong");
                }
            };
        }
    };
}
