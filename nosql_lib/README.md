# Drogon Redis NoSQL Library Documentation

## Overview

The Drogon Redis NoSQL library provides a comprehensive C++ interface for Redis operations, offering high-performance asynchronous communication with Redis servers. Built on top of the hiredis library and integrated with Drogon's event loop system, it provides both high-level and low-level Redis functionality with excellent performance characteristics.

## Architecture

### Core Components

#### 1. RedisClient (`RedisClient.h`)
The main Redis client interface that provides:
- **Connection Management**: Connection pooling and lifecycle management
- **Command Execution**: Multiple execution modes (async, sync, future, coroutine)
- **Transaction Support**: Redis transaction management
- **Subscriber Management**: Pub/Sub functionality

**Key Features:**
```cpp
// Factory method for creating Redis clients
static std::shared_ptr<RedisClient> newRedisClient(
    const trantor::InetAddress &serverAddress,
    size_t numberOfConnections = 1,
    const std::string &password = "",
    unsigned int db = 0,
    const std::string &username = "");

// Multiple execution modes
virtual void execCommandAsync(RedisResultCallback &&resultCallback,
                              RedisExceptionCallback &&exceptionCallback,
                              std::string_view command,
                              ...) noexcept = 0;

template <typename F, typename... Args>
std::invoke_result_t<F, const RedisResult &> execCommandSync(
    F &&processFunc,
    std::string_view command,
    Args &&...args);

// Transaction support
virtual std::shared_ptr<RedisTransaction> newTransaction() noexcept(false) = 0;
virtual void newTransactionAsync(
    const std::function<void(const std::shared_ptr<RedisTransaction> &)> &callback) = 0;

// Pub/Sub support
virtual std::shared_ptr<RedisSubscriber> newSubscriber() noexcept = 0;
```

#### 2. RedisResult (`RedisResult.h`)
Represents Redis responses with type-safe access:
- **Result Types**: Integer, String, Array, Status, Nil, Error
- **Type Safety**: Compile-time type checking
- **Memory Efficient**: Lightweight wrapper around hiredis replies

**Core Operations:**
```cpp
// Result type checking
RedisResultType type() const noexcept;

// Type-safe value extraction
std::string asString() const noexcept(false);
std::vector<RedisResult> asArray() const noexcept(false);
long long asInteger() const noexcept(false);

// Utility methods
std::string getStringForDisplaying() const noexcept;
bool isNil() const noexcept;
explicit operator bool() const;
```

#### 3. RedisSubscriber (`RedisSubscriber.h`)
Provides publish/subscribe functionality:
- **Channel Subscription**: Subscribe to specific channels
- **Pattern Subscription**: Subscribe to channel patterns
- **Message Handling**: Callback-based message processing
- **Connection Management**: Dedicated connection for subscriptions

**Usage:**
```cpp
// Channel subscription
virtual void subscribe(const std::string &channel,
                       RedisMessageCallback &&messageCallback) noexcept = 0;

// Pattern subscription
virtual void psubscribe(const std::string &pattern,
                        RedisMessageCallback &&messageCallback) noexcept = 0;

// Unsubscription
virtual void unsubscribe(const std::string &channel) noexcept = 0;
virtual void punsubscribe(const std::string &pattern) noexcept = 0;
```

#### 4. RedisTransaction (`RedisTransaction.h`)
Provides Redis transaction support:
- **Multi-Exec**: Atomic command execution
- **Command Queuing**: Queue commands for transaction execution
- **Async Support**: Both sync and async transaction execution

**Usage:**
```cpp
// Execute transaction
virtual void execute(RedisResultCallback &&resultCallback,
                     RedisExceptionCallback &&exceptionCallback) = 0;

// Inherits all RedisClient methods for command queuing
```

### Implementation Architecture

#### 1. RedisClientImpl (`RedisClientImpl.h`)
Implementation of the RedisClient interface:
- **Connection Pooling**: Manages multiple Redis connections
- **Load Balancing**: Distributes commands across connections
- **Event Loop Integration**: Built on Trantor's event loop system
- **Timeout Management**: Handles command timeouts

#### 2. RedisConnection (`RedisConnection.h`)
Low-level Redis connection implementation:
- **Connection Lifecycle**: Manages connection states
- **Command Queue**: Buffers Redis commands for execution
- **Error Handling**: Robust error handling and recovery
- **Asynchronous I/O**: Non-blocking Redis operations

**Key Features:**
```cpp
// Command formatting and execution
static std::string getFormattedCommand(const std::string_view &command,
                                       va_list ap) noexcept(false);

// Async command sending
void sendFormattedCommand(std::string &&command,
                          RedisResultCallback &&resultCallback,
                          RedisExceptionCallback &&exceptionCallback);

// Subscribe/Unsubscribe operations
void sendSubscribe(const std::shared_ptr<SubscribeContext> &subCtx);
void sendUnsubscribe(const std::shared_ptr<SubscribeContext> &subCtx);
```

#### 3. RedisSubscriberImpl (`RedisSubscriberImpl.h`)
Implementation of the RedisSubscriber interface:
- **Context Management**: Manages subscription contexts
- **Task Queue**: Queues subscription operations
- **Connection Handling**: Dedicated connection for pub/sub
- **Message Routing**: Routes messages to appropriate callbacks

#### 4. RedisException (`RedisException.h`)
Comprehensive error handling:
- **Error Codes**: Specific error types for different failure scenarios
- **Exception Safety**: Structured exception handling
- **Error Context**: Detailed error messages

**Error Types:**
```cpp
enum class RedisErrorCode
{
    kNone = 0,
    kUnknown,
    kConnectionBroken,
    kNoConnectionAvailable,
    kRedisError,
    kInternalError,
    kTransactionCancelled,
    kBadType,
    kTimeout
};
```

## Features

### 1. High-Performance Architecture
- **Connection Pooling**: Efficient connection management
- **Event-Driven**: Built on event loop architecture
- **Asynchronous I/O**: Non-blocking operations
- **Memory Efficiency**: Minimal memory overhead

### 2. Multiple Programming Models
- **Callback-based**: Traditional callback interface
- **Future-based**: Modern std::future interface
- **Coroutine-based**: C++20 coroutine support
- **Synchronous**: Blocking operations when needed

### 3. Comprehensive Redis Support
- **All Redis Commands**: Support for all Redis commands
- **Data Types**: Strings, Lists, Sets, Sorted Sets, Hashes, Streams
- **Transactions**: Multi-Exec transaction support
- **Pub/Sub**: Publish/subscribe functionality
- **Pipelining**: Command pipelining support

### 4. Advanced Features
- **Connection Management**: Automatic connection pooling and recovery
- **Timeout Control**: Configurable operation timeouts
- **Error Handling**: Comprehensive error handling and recovery
- **Logging**: Integrated logging support
- **Security**: Password and username authentication

### 5. C++20 Coroutine Support
```cpp
#ifdef __cpp_impl_coroutine
// Coroutine-based command execution
template <typename... Arguments>
internal::RedisAwaiter execCommandCoro(std::string_view command,
                                       Arguments... args);

// Coroutine-based transaction creation
internal::RedisTransactionAwaiter newTransactionCoro();

// Example usage
drogon::Task<> exampleTask() {
    auto client = RedisClient::newRedisClient(addr, 3);
    auto result = co_await client->execCommandCoro("GET %s", "key");
    auto trans = co_await client->newTransactionCoro();
    co_await trans->executeCoro();
}
#endif
```

## Usage Examples

### Basic Usage

```cpp
// Create Redis client
auto client = RedisClient::newRedisClient(
    trantor::InetAddress("127.0.0.1", 6379), 
    3,  // number of connections
    "password", 
    0    // database number
);

// Execute command asynchronously
client->execCommandAsync(
    [](const RedisResult &result) {
        std::cout << "Value: " << result.asString() << std::endl;
    },
    [](const RedisException &e) {
        std::cerr << "Error: " << e.what() << std::endl;
    },
    "GET %s", 
    "mykey"
);

// Execute command synchronously
try {
    std::string value = client->execCommandSync<std::string>(
        [](const RedisResult &result) {
            return result.asString();
        },
        "GET %s",
        "mykey"
    );
    std::cout << "Value: " << value << std::endl;
} catch (const RedisException &e) {
    std::cerr << "Error: " << e.what() << std::endl;
}
```

### Transaction Usage

```cpp
// Create transaction
auto transaction = client->newTransaction();

// Queue commands in transaction
transaction->execCommandAsync(
    [](const RedisResult &result) {
        std::cout << "SET result: " << result.asString() << std::endl;
    },
    [](const RedisException &e) {
        std::cerr << "SET error: " << e.what() << std::endl;
    },
    "SET %s %s",
    "key1", 
    "value1"
);

transaction->execCommandAsync(
    [](const RedisResult &result) {
        std::cout << "INCR result: " << result.asInteger() << std::endl;
    },
    [](const RedisException &e) {
        std::cerr << "INCR error: " << e.what() << std::endl;
    },
    "INCR %s",
    "counter"
);

// Execute transaction
transaction->execute(
    [](const RedisResult &result) {
        std::cout << "Transaction executed successfully" << std::endl;
    },
    [](const RedisException &e) {
        std::cerr << "Transaction failed: " << e.what() << std::endl;
    }
);
```

### Pub/Sub Usage

```cpp
// Create subscriber
auto subscriber = client->newSubscriber();

// Subscribe to channel
subscriber->subscribe("mychannel",
    [](const std::string &channel, const std::string &message) {
        std::cout << "Received message on " << channel << ": " << message << std::endl;
    }
);

// Subscribe to pattern
subscriber->psubscribe("news.*",
    [](const std::string &pattern, const std::string &message) {
        std::cout << "Received pattern message: " << message << std::endl;
    }
);

// Unsubscribe (when needed)
subscriber->unsubscribe("mychannel");
subscriber->punsubscribe("news.*");
```

### Complex Data Operations

```cpp
// Hash operations
client->execCommandAsync(
    [](const RedisResult &result) {
        std::cout << "Hash fields: " << result.asString() << std::endl;
    },
    [](const RedisException &e) {
        std::cerr << "Hash error: " << e.what() << std::endl;
    },
    "HGETALL %s",
    "user:1001"
);

// List operations
client->execCommandAsync(
    [](const RedisResult &result) {
        auto elements = result.asArray();
        std::cout << "List elements: ";
        for (const auto &elem : elements) {
            std::cout << elem.asString() << " ";
        }
        std::cout << std::endl;
    },
    [](const RedisException &e) {
        std::cerr << "List error: " << e.what() << std::endl;
    },
    "LRANGE %s %d %d",
    "mylist",
    0,
    -1
);

// Set operations
client->execCommandAsync(
    [](const RedisResult &result) {
        std::cout << "Set members: " << result.asString() << std::endl;
    },
    [](const RedisException &e) {
        std::cerr << "Set error: " << e.what() << std::endl;
    },
    "SMEMBERS %s",
    "myset"
);
```

## Configuration

### Connection Configuration

```cpp
// Basic connection setup
trantor::InetAddress serverAddress("127.0.0.1", 6379);
size_t numberOfConnections = 3;  // Connection pool size
std::string password = "your_password";
unsigned int db = 0;            // Database number
std::string username = "";     // Redis username (for Redis 6+)

// Create client with configuration
auto client = RedisClient::newRedisClient(
    serverAddress,
    numberOfConnections,
    password,
    db,
    username
);
```

### Timeout Configuration

```cpp
// Set command timeout (in seconds)
client->setTimeout(5.0);  // 5 seconds timeout

// Disable timeout
client->setTimeout(-1.0);
```

### CMake Options

```cmake
# Enable Redis support
BUILD_REDIS=ON

# Enable shared libraries
BUILD_SHARED_LIBS=ON

# Enable coroutine support
USE_COROUTINE=ON
```

## Best Practices

### 1. Connection Management
- Use appropriate connection pool size based on your application needs
- Monitor connection health and handle reconnections gracefully
- Close connections when shutting down the application
- Use connection pooling for better performance

### 2. Error Handling
- Always handle exceptions in Redis operations
- Use proper exception handling patterns
- Implement retry logic for transient failures
- Log errors for debugging purposes

### 3. Performance Optimization
- Use connection pooling to reduce connection overhead
- Batch related operations in transactions
- Use appropriate data structures for your use case
- Monitor memory usage and optimize data access patterns

### 4. Security
- Use strong passwords and consider enabling Redis authentication
- Use TLS/SSL for network encryption when available
- Implement proper access control at the application level
- Regularly update Redis server and client libraries

### 5. Resource Management
- Clean up resources properly when done
- Use RAII patterns for resource management
- Avoid holding RedisResult objects outside callback scope
- Implement proper cleanup for subscribers and transactions

## Troubleshooting

### Common Issues

1. **Connection Timeout**: Check Redis server availability and network connectivity
2. **Memory Usage**: Monitor connection pool size and memory usage patterns
3. **Performance**: Optimize connection pool size and command batching
4. **Authentication**: Verify username/password and Redis server configuration

### Debug Tips

- Enable debug logging for detailed operation traces
- Use Redis monitoring tools (MONITOR command) for debugging
- Test with different connection pool configurations
- Monitor network latency and Redis server performance

### Error Codes

- `kConnectionBroken`: Network connection lost
- `kNoConnectionAvailable`: Connection pool exhausted
- `kRedisError`: Redis server returned an error
- `kTimeout`: Operation timed out
- `kTransactionCancelled`: Transaction was cancelled

## Integration with Drogon Framework

### Plugin Integration

```cpp
// In your Drogon application configuration
app().registerPlugin(
    [](const Json::Value &config) {
        auto redisClient = RedisClient::newRedisClient(
            trantor::InetAddress(config["host"].asString(), config["port"].asInt()),
            config["connections"].asUInt(),
            config["password"].asString(),
            config["db"].asUInt()
        );
        return redisClient;
    },
    "redis"
);
```

### Controller Usage

```cpp
class MyController : public drogon::HttpController<MyController> {
public:
    METHOD_LIST_BEGIN
    METHOD_ADD(MyController::getCache, "/cache/{key}", Get);
    METHOD_ADD(MyController::setCache, "/cache/{key}", Post);
    METHOD_LIST_END

    void getCache(const HttpRequestPtr &req,
                  std::function<void(const HttpResponsePtr &)> &&callback,
                  const std::string &key) {
        auto redisClient = app().getPlugin<RedisClient>("redis");
        
        redisClient->execCommandAsync(
            [callback](const RedisResult &result) {
                auto resp = HttpResponse::newHttpResponse();
                resp->setBody(result.asString());
                callback(resp);
            },
            [callback](const RedisException &e) {
                auto resp = HttpResponse::newHttpResponse();
                resp->setStatusCode(k500InternalServerError);
                resp->setBody(e.what());
                callback(resp);
            },
            "GET %s", 
            key
        );
    }
};
```

## Conclusion

The Drogon Redis NoSQL library provides a comprehensive, high-performance, and easy-to-use interface for Redis operations in C++ applications. Its support for multiple programming models, comprehensive Redis feature coverage, and excellent integration with the Drogon framework makes it an excellent choice for building scalable and maintainable applications.

By following the patterns and best practices outlined in this documentation, developers can leverage the full power of Redis for caching, session management, real-time messaging, and other use cases while maintaining excellent performance and reliability.