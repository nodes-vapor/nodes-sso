import Leaf
import Vapor

public final class NodesSSOProvider<U: NodesSSOAuthenticatable>: Provider {
    private let config: NodesSSOConfig<U>

    public init(config: NodesSSOConfig<U>) {
        self.config = config
    }

    public func register(_ services: inout Services) throws {
        services.register(config)
        services.register(NodesSSOConfigTagData(loginPath: config.loginPath))
    }

    public func didBoot(_ container: Container) throws -> Future<Void> {
        return .done(on: container)
    }
}

public extension Router {
    public func useNodesSSORoutes<U: NodesSSOAuthenticatable>(
        _ type: U.Type,
        on container: Container
    ) throws {
        let config: NodesSSOConfig<U> = try container.make()
        let controller = config.controller

        group(config.middlewares) { group in
            group.get(config.loginPath, use: controller.auth)
            group.post(config.callbackPath, use: controller.callback)
        }
    }
}

public extension LeafTagConfig {
    public mutating func useNodesSSOLeafTags() {
        use(NodesSSOConfigTag(), as: "nodessso:config")
    }
}
