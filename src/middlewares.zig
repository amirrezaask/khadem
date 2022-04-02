const std = @import("std");
const http = @import("http.zig");
const Handler = http.server.Handler;
const Request = http.Request;
const Response = http.Response;
// m1 -> m2 -> m3 -> h -> m3 -> m2 -> m1

pub fn LogRequest(comptime h: Handler.Fn) Handler.Fn {
    const dumb = struct {
        pub fn handler_fn(req: *Request, resp: *Response) anyerror!void {
            req.debugPrintRequest();
            try h(req, resp);
        }
    };
    return dumb.handler_fn;
}
