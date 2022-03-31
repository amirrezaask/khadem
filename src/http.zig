const std = @import("std");
const net = std.net;
const StreamServer = net.StreamServer;
const Address = net.Address;
const GeneralPurposeAllocator = std.heap.GeneralPurposeAllocator;
const print = std.debug.print;
const Allocator = std.mem.Allocator;
const Request = @import("Request.zig");
const Response = @import("Response.zig");

pub const ParsingError = error{
    MethodNotValid,
    VersionNotValid,
};

pub const Method = enum {
    GET,
    POST,
    PUT,
    PATCH,
    OPTION,
    DELETE,
    pub fn fromString(s: []const u8) !Method {
        if (std.mem.eql(u8, "GET", s)) return .GET;
        if (std.mem.eql(u8, "POST", s)) return .POST;
        if (std.mem.eql(u8, "PUT", s)) return .PUT;
        if (std.mem.eql(u8, "PATCH", s)) return .PATCH;
        if (std.mem.eql(u8, "OPTION", s)) return .OPTION;
        if (std.mem.eql(u8, "DELETE", s)) return .DELETE;
        return ParsingError.MethodNotValid;
    }
};

pub const Version = enum {
    @"1.1",
    @"2",

    pub fn fromString(s: []const u8) !Version {
        if (std.mem.eql(u8, "HTTP/1.1", s)) return .@"1.1";
        if (std.mem.eql(u8, "HTTP/2", s)) return .@"2";
        return ParsingError.VersionNotValid;
    }

    pub fn asString(self: Version) []const u8 {
        if (self == Version.@"1.1") return "HTTP/1.1";
        if (self == Version.@"2") return "HTTP/2";
        unreachable;
    }
};

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

pub const Handler = fn (*Request, *Response) anyerror!void;

pub const Config = struct {
    address: []const u8 = "127.0.0.1",
    port: u16 = 8080,
};

pub fn Server(comptime handler: Handler) type {
    return struct {
        allocator: std.mem.Allocator,
        clients: std.ArrayList(*Client),
        config: Config,
        const Self = @This();
        const Client = struct {
            frame: @Frame(handle),
        };
        pub fn deinit(self: *Server) void {
            self.stream_server.close();
            self.stream_server.deinit();
        }
        pub fn init(allocator: std.mem.Allocator, config: Config) Self {
            return .{ .allocator = allocator, .clients = std.ArrayList(*Client).init(allocator), .config = config };
        }
        fn handle(self: *Self, stream: net.Stream) !void {
            defer stream.close();
            var request = try Request.init(self.allocator, stream.reader());
            request.debugPrintRequest();
            var response = Response{ .version = request.version, .writer = stream.writer() };
            try handler(&request, &response);
        }

        pub fn listen(self: *Self) !void {
            var stream_server = StreamServer.init(.{});
            const address = try net.Address.resolveIp(self.config.address, self.config.port);
            try stream_server.listen(address);
            print("Listening on: {}\n", .{address});
            while (true) {
                const connection = try stream_server.accept();
                var client = try self.allocator.create(Client);
                client.* = .{
                    .frame = async self.handle(connection.stream),
                };
                try self.clients.append(client);
            }
        }
    };
}
