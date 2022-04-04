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

pub const KV = struct {
    name: []const u8,
    value: []const u8,
};
const Radix = struct {
    const max_parameters_allowd = 10;
    const Node = struct {
        children: []*Node,
        path: []const u8,
        route_idx: ?usize,
        match_strategy: enum { parameter, exact },
    };

    root: Node = .{
        .children = &.{},
        .path = "/",
        .route_idx = 0,
        .match_strategy = .exact,
    },

    // this function should be completely comptime evaluable;
    pub fn insert(self: *Radix, comptime path: []const u8, route_idx: usize) !void {
        if (path.len == 1 and path[0] == '/') {
            self.root.route_idx = route_idx;
        }

        comptime var path_iter = std.mem.split(u8, path[1..], "/");
        comptime var current = &self.root;

        comptime {
            // loop until we reach a point that we need a new node.
            outer: while (path_iter.next()) |segment| {
                for (current.children) |child| {
                    if (std.mem.eql(u8, child.path, segment)) {
                        current = child;
                        continue :outer;
                    }
                }

                var new_node: Node = Node{
                    .children = &[_]*Node{},
                    .path = segment,
                    .route_idx = null,
                    .match_strategy = .exact,
                };
                // check if the path segment is a parameter or not
                if (segment.len > 0) {
                    switch (segment[0]) {
                        ':' => new_node.match_strategy = .parameter,
                        else => new_node.match_strategy = .exact,
                    }
                }

                // adding new node to children of current node
                var new_childs: [current.children.len + 1]*Node = undefined;
                std.mem.copy(*Node, &new_childs, current.children ++ [_]*Node{&new_node});
                current.children = &new_childs;
                current = &new_node;
            }
            current.route_idx = route_idx;
        }
    }
    const Result = struct {
        parameters: ?[max_parameters_allowd]KV,
        route_idx: ?usize,
    };
    pub fn lookup(self: *Radix, path: []const u8) !Result {
        var path_iter = std.mem.split(u8, path[1..], "/");
        var current = &self.root;
        var parameters_count: usize = 0;
        var parameters: [max_parameters_allowd]KV = undefined;

        loop: while (path_iter.next()) |segment| {
            for (current.children) |child| {
                if (std.mem.eql(u8, segment, child.path) or child.match_strategy == .parameter) {
                    if (child.match_strategy == .parameter) {
                        parameters[parameters_count] = KV{
                            .name = child.path[1..],
                            .value = segment,
                        };
                        parameters_count += 1;
                    }
                    current = child;
                    continue :loop;
                }
            }
        }

        return Result{
            .parameters = parameters,
            .route_idx = current.route_idx,
        };
    }
};

const print = std.debug.print;

// Testcases are taken from apple_pie
test "Insert and retrieve" {
    comptime var trie = Radix{};
    comptime try trie.insert("/posts/:id", 1);
    comptime try trie.insert("/topics/:id/messages/:msg", 2);
    comptime try trie.insert("/bar", 3);

    const res = try trie.lookup("/posts/5");
    const res2 = try trie.lookup("/topics/25/messages/20");
    const res3 = try trie.lookup("/bar");

    try std.testing.expectEqual(@as(usize, 1), res.route_idx.?);
    try std.testing.expectEqual(@as(usize, 2), res2.route_idx.?);
    try std.testing.expectEqual(@as(usize, 3), res3.route_idx.?);

    try std.testing.expectEqualStrings("5", res.parameters.?[0].value);
    try std.testing.expectEqualStrings("25", res2.parameters.?[0].value);
    try std.testing.expectEqualStrings("20", res2.parameters.?[1].value);
}

// test "Insert and retrieve paths with same prefix" {
//     comptime var trie = Radix{};
//     comptime try trie.insert("/api", 1);
//     comptime try trie.insert("/api/users", 2);
//     comptime try trie.insert("/api/events", 3);
//     comptime try trie.insert("/api/events/:id", 4);

//     const res = try trie.lookup("/api");
//     const res2 = try trie.lookup("/api/users");
//     const res3 = try trie.lookup("/api/events");
//     const res4 = try trie.lookup("/api/events/1337");
//     const res5 = try trie.lookup("/foo");
//     const res6 = try trie.lookup("/api/api/events");

//     try std.testing.expectEqual(@as(usize, 1), res.route_idx.?);
//     try std.testing.expectEqual(@as(usize, 2), res2.route_idx.?);
//     try std.testing.expectEqual(@as(usize, 3), res3.route_idx.?);
//     try std.testing.expectEqual(@as(usize, 4), res4.route_idx.?);
//     try std.testing.expect(res5.route_idx == null);
//     try std.testing.expect(res6.route_idx == null);

//     try std.testing.expectEqualStrings("1337", res4.parameters.?[0].value);
// }

// test "lookup root" {
//     comptime var trie = Radix{};
//     comptime try trie.insert("/api", 1);

//     const res = try trie.lookup("/");
//     try std.testing.expect(res.route_idx == null);
// }
