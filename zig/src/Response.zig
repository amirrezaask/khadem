const Response = @This();
const std = @import("std");
const net = std.net;
const http = @import("http.zig");
const Request = http.Request;

writer: net.Stream.Writer,
version: Request.Version,

pub fn respond(self: *Response, status: Status, maybe_headers: ?std.StringHashMap([]const u8), body: []const u8) !void {
    try self.writer.print("{s} {} {s}\r\n", .{ self.version.asString(), status.code, status.message });
    if (maybe_headers) |headers| {
        var headers_iter = headers.iterator();
        while (headers_iter.next()) |entry| {
            try self.writer.print("{s}: {s}\n", .{ entry.key_ptr.*, entry.value_ptr.* });
        }
    }
    try self.writer.print("\r\n", .{});

    _ = try self.writer.write(body);
}
pub const Status = struct {
    message: []const u8,
    code: usize,

    pub fn Ok() Status {
        return Status{ .message = "OK", .code = 200 };
    }

    pub fn Created() Status {
        return Status{ .message = "Created", .code = 201 };
    }

    pub fn Accepted() Status {
        return Status{ .message = "Accepted", .code = 202 };
    }

    pub fn NoContent() Status {
        return Status{ .message = "NoContent", .code = 204 };
    }

    pub fn NotFound() Status {
        return Status{ .message = "Not Found", .code = 404 };
    }

    pub fn BadRequest() Status {
        return Status{ .message = "Bad Request", .code = 400 };
    }
    pub fn Forbidden() Status {
        return Status{ .message = "Forbidden", .code = 403 };
    }
    pub fn UnAuthorized() Status {
        return Status{ .message = "UnAuthorized", .code = 401 };
    }
};
