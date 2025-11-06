# Drogon ORM Library Documentation

## Overview

The Drogon ORM library is a powerful Object-Relational Mapping (ORM) system that provides a high-level, type-safe interface for database operations in C++ applications. It supports multiple database backends including PostgreSQL, MySQL, and SQLite3, with both asynchronous and synchronous programming models.

## Architecture

### Core Components

#### 1. DbClient (`DbClient.h`)
The main database client interface that provides:
- **Connection Management**: Connection pooling and lifecycle management
- **Query Execution**: Multiple query execution modes (async, sync, future, coroutine)
- **Transaction Support**: ACID transaction management
- **Timeout Control**: Query timeout management

**Key Features:**
```cpp
// Factory methods for different databases
static std::shared_ptr<DbClient> newPgClient(const std::string &connInfo, size_t connNum, bool autoBatch = false);
static std::shared_ptr<DbClient> newMysqlClient(const std::string &connInfo, size_t connNum);
static std::shared_ptr<DbClient> newSqlite3Client(const std::string &connInfo, size_t connNum);

// Multiple execution modes
template <typename FUNCTION1, typename FUNCTION2, typename... Arguments>
void execSqlAsync(const std::string &sql, FUNCTION1 &&rCallback, FUNCTION2 &&exceptCallback, Arguments &&...args);

template <typename... Arguments>
std::future<Result> execSqlAsyncFuture(const std::string &sql, Arguments &&...args);

template <typename... Arguments>
Result execSqlSync(const std::string &sql, Arguments &&...args);

#ifdef __cpp_impl_coroutine
template <typename... Arguments>
internal::SqlAwaiter execSqlCoro(const std::string &sql, Arguments &&...args);
#endif
```

#### 2. Mapper (`Mapper.h`)
The ORM mapper template that provides type-safe database operations:
- **CRUD Operations**: Create, Read, Update, Delete operations
- **Query Building**: Flexible query construction with criteria
- **Pagination**: Built-in pagination support
- **Sorting**: Order by operations
- **Relationships**: Support for complex data relationships

**Core Operations:**
```cpp
// Find operations
T findByPrimaryKey(const TraitsPKType &key);
std::vector<T> findBy(const Criteria &criteria);
T findOne(const Criteria &criteria);
size_t count(const Criteria &criteria = Criteria());

// Write operations
void insert(T &obj);
size_t update(const T &obj);
size_t deleteOne(const T &obj);
size_t deleteBy(const Criteria &criteria);

// Query modifiers
Mapper<T> &limit(size_t limit);
Mapper<T> &offset(size_t offset);
Mapper<T> &orderBy(const std::string &colName, const SortOrder &order = SortOrder::ASC);
Mapper<T> &paginate(size_t page, size_t perPage);
Mapper<T> &forUpdate();
```

#### 3. CoroMapper (`CoroMapper.h`)
C++20 coroutine-based mapper for modern asynchronous programming:
- **Coroutine Support**: Native C++20 coroutine integration
- **Exception Handling**: Structured exception handling in coroutines
- **Type Safety**: Maintains the same type safety as the synchronous mapper

**Usage:**
```cpp
#ifdef __cpp_impl_coroutine
drogon::Task<> exampleTask() {
    CoroMapper<User> mapper(client);
    auto user = co_await mapper.findByPrimaryKey(1);
    auto count = co_await mapper.count();
    co_return;
}
#endif
```

#### 4. Criteria (`Criteria.h`)
Query criteria system for building complex conditions:
- **Comparison Operators**: EQ, NE, GT, GE, LT, LE, Like, NotLike, In, NotIn, IsNull, IsNotNull
- **Logical Operations**: AND, OR operations between criteria
- **Custom SQL**: Support for raw SQL conditions
- **Type Safety**: Template-based parameter binding

**Examples:**
```cpp
// Simple criteria
Criteria age_gt_18("age", CompareOperator::GT, 18);
Criteria name_like_tom("name", CompareOperator::Like, "Tom%");

// Complex criteria
Criteria complex = Criteria("age", CompareOperator::GT, 18) && 
                 Criteria("name", CompareOperator::Like, "A%");

// Custom SQL
Criteria custom("active = true AND created_at > NOW() - INTERVAL '30 days'"_sql);
```

### Database Layer Architecture

#### 1. DbClientImpl (`DbClientImpl.h`)
Implementation of the DbClient interface:
- **Connection Pooling**: Manages multiple database connections
- **Load Balancing**: Distributes queries across connections
- **Event Loop Integration**: Built on Trantor's event loop system
- **Timeout Management**: Handles query timeouts

#### 2. DbConnection (`DbConnection.h`)
Base class for database-specific connections:
- **Connection Lifecycle**: Manages connection states (None, Connecting, SettingCharacterSet, Ok, Bad)
- **Command Queue**: Buffers SQL commands for execution
- **Error Handling**: Robust error handling and recovery
- **Asynchronous I/O**: Non-blocking database operations

#### 3. Database-Specific Implementations

##### PostgreSQL (`postgresql_impl/`)
- **PgConnection**: PostgreSQL-specific connection implementation
- **Batch Mode**: Support for PostgreSQL's batch/pipelining mode
- **Prepared Statements**: Automatic statement preparation and caching
- **Advanced Features**: Support for PostgreSQL-specific features

##### MySQL (`mysql_impl/`)
- **MysqlConnection**: MySQL-specific connection implementation
- **Protocol Support**: Full MySQL protocol support
- **Binary Protocol**: Optimized binary protocol usage
- **Replication Support**: Read/write splitting support

##### SQLite3 (`sqlite3_impl/`)
- **Sqlite3Connection**: SQLite3-specific connection implementation
- **File-based**: File-based database management
- **Memory Databases**: Support for in-memory databases
- **Concurrency**: Thread-safe concurrent access

## Features

### 1. Multi-Database Support
- **PostgreSQL**: Full feature support with advanced capabilities
- **MySQL**: Complete MySQL/MariaDB support
- **SQLite3**: Lightweight embedded database support

### 2. Asynchronous Programming
- **Callback-based**: Traditional callback interface
- **Future-based**: Modern std::future interface
- **Coroutine-based**: C++20 coroutine support
- **Event-driven**: Built on event loop architecture

### 3. Type Safety
- **Template-based**: Compile-time type checking
- **Model Generation**: Automatic model generation from database schema
- **Parameter Binding**: Safe parameter binding preventing SQL injection
- **Exception Safety**: Comprehensive exception handling

### 4. Performance Optimization
- **Connection Pooling**: Efficient connection management
- **Statement Caching**: Automatic prepared statement caching
- **Batch Operations**: Support for batch operations (PostgreSQL)
- **Lazy Loading**: Efficient data loading strategies

### 5. Advanced Features
- **Transactions**: Full ACID transaction support
- **Pagination**: Built-in pagination support
- **Sorting**: Flexible sorting capabilities
- **Relationships**: Support for complex data relationships
- **Migrations**: Database migration support

## Usage Examples

### Basic Usage

```cpp
// Create database client
auto client = DbClient::newPgClient("host=localhost port=5432 dbname=test user=test", 10);

// Execute simple query
client->execSqlAsync("SELECT * FROM users WHERE age > $?", 
    [](const Result &result) {
        for (auto row : result) {
            std::cout << "User: " << row["name"].as<std::string>() << std::endl;
        }
    },
    [](const std::exception_ptr &e) {
        std::cerr << "Error: " << e.what() << std::endl;
    },
    18);
```

### ORM Usage

```cpp
// Define model (usually auto-generated)
class User {
public:
    static const std::string tableName;
    static const std::string primaryKeyName;
    using PrimaryKeyType = int32_t;
    
    int32_t user_id;
    std::string name;
    int32_t age;
    // ... getters and setters
};

// Use mapper
Mapper<User> mapper(client);

// Find user by primary key
auto user = mapper.findByPrimaryKey(1);

// Find users with criteria
auto users = mapper.findBy(Criteria("age", CompareOperator::GT, 18));

// Insert new user
User newUser;
newUser.name = "John Doe";
newUser.age = 25;
mapper.insert(newUser);

// Update user
user.age = 26;
mapper.update(user);

// Delete user
mapper.deleteOne(user);
```

### Coroutine Usage

```cpp
#ifdef __cpp_impl_coroutine
drogon::Task<> processUser() {
    CoroMapper<User> mapper(client);
    
    // Find user
    auto user = co_await mapper.findByPrimaryKey(1);
    
    // Update user
    user.age = user.age + 1;
    co_await mapper.update(user);
    
    // Find all users
    auto users = co_await mapper.findAll();
    
    std::cout << "Processed " << users.size() << " users" << std::endl;
}
#endif
```

### Transaction Usage

```cpp
// Start transaction
auto transaction = client->newTransaction();

// Use transaction with mapper
Mapper<User> mapper(transaction);

try {
    // Multiple operations in transaction
    auto user = mapper.findByPrimaryKey(1);
    user.age = user.age + 1;
    mapper.update(user);
    
    // Transaction will be committed automatically
} catch (const DrogonDbException &e) {
    // Transaction will be rolled back automatically
    std::cerr << "Transaction failed: " << e.base().what() << std::endl;
}
```

## Configuration

### Connection String Format

#### PostgreSQL
```
host=localhost port=5432 dbname=mydb user=myuser password=mypass connect_timeout=10
```

#### MySQL
```
host=localhost port=3306 dbname=mydb user=myuser password=mypass connect_timeout=10
```

#### SQLite3
```
filename=/path/to/database.db
```

### CMake Options

```cmake
# Enable ORM support
BUILD_ORM=ON

# Enable specific database support
BUILD_POSTGRESQL=ON
BUILD_MYSQL=ON
BUILD_SQLITE=ON

# Enable shared libraries
BUILD_SHARED_LIBS=ON

# Enable coroutine support
USE_COROUTINE=ON
```

## Best Practices

### 1. Connection Management
- Use connection pooling for better performance
- Set appropriate connection limits based on your database capacity
- Close connections when shutting down the application

### 2. Error Handling
- Always handle exceptions in database operations
- Use proper exception handling patterns
- Log errors for debugging purposes

### 3. Security
- Always use parameter binding to prevent SQL injection
- Never concatenate SQL strings with user input
- Use proper authentication and encryption

### 4. Performance
- Use appropriate indexing for frequently queried columns
- Consider using prepared statements for repeated queries
- Use pagination for large result sets
- Batch operations when possible

### 5. Code Organization
- Use model classes generated by drogon_ctl
- Separate database logic from business logic
- Use appropriate abstraction layers

## Migration and Schema Management

### Model Generation
Use `drogon_ctl` to generate model classes from database schema:

```bash
# Generate models for PostgreSQL
drogon_ctl create model -t postgresql -c "host=localhost dbname=test user=test" -o ./models

# Generate models for MySQL
drogon_ctl create model -t mysql -c "host=localhost dbname=test user=test" -o ./models

# Generate models for SQLite3
drogon_ctl create model -t sqlite3 -c "filename=test.db" -o ./models
```

### Schema Updates
- Use migration tools for schema changes
- Test migrations in development environment
- Backup data before applying migrations

## Troubleshooting

### Common Issues

1. **Connection Timeout**: Increase timeout values or check network connectivity
2. **Memory Usage**: Adjust connection pool size or implement proper cleanup
3. **Performance**: Add appropriate indexes and optimize queries
4. **Deadlocks**: Use proper transaction isolation levels and retry logic

### Debug Tips
- Enable debug logging for detailed operation traces
- Use database monitoring tools to identify bottlenecks
- Test with different connection pool configurations

## Conclusion

The Drogon ORM library provides a comprehensive, type-safe, and high-performance solution for database operations in C++ applications. Its support for multiple databases, asynchronous programming models, and modern C++ features makes it an excellent choice for building scalable and maintainable applications.

By following the patterns and best practices outlined in this documentation, developers can leverage the full power of the Drogon ORM to build robust database applications with minimal boilerplate code and maximum type safety.