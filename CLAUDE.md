# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build System and Development Commands

### Building Drogon

#### Linux/macOS
- **Standard build**: `./build.sh` - Builds release version with default settings
- **Test build**: `./build.sh -t` - Builds with testing enabled (`-DBUILD_TESTING=on`)
- **Shared library build**: `./build.sh -tshared` - Builds shared libraries with testing
- **Manual cmake**: 
  ```bash
  mkdir build && cd build
  cmake .. -DCMAKE_BUILD_TYPE=release
  cmake --build .
  ```

#### Windows
- **Standard build**: `build.bat` - Builds release version with default settings
- **Debug build**: `build.bat -debug` - Builds debug version
- **Test build**: `build.bat -t` - Builds with testing enabled (`-DBUILD_TESTING=on`)
- **Custom install**: `build.bat -install "C:\MyPath\drogon"` - Sets custom install prefix
- **Combined options**: `build.bat -debug -t` - Debug build with testing enabled

**Windows build.bat options**:
- `-debug`: Build debug version
- `-release`: Build release version (default)
- `-t`: Enable testing
- `-install path`: Set install prefix (default: `C:\MyPath\drogon`)

### Testing
- **Full test suite**: `./test.sh` - Runs integration tests, unit tests, and drogon_ctl tests
- **Unit tests only**: `./test.sh -t` - Runs unit tests and database tests
- **Windows testing**: `./test.sh -w` - Run tests on Windows
- **Manual testing**: `ctest --output-on-failure` from build directory
- **Integration tests**: Located in `build/lib/tests/integration_test/`
- **Database tests**: Located in `build/orm_lib/tests/`
- **Redis tests**: Located in `build/nosql_lib/redis/tests/`
- **drogon_ctl tests**: Located in `build/lib/tests/drogon_test/`

### Code Quality
- **Format code**: `./format.sh` - Formats code using clang-format (requires version 17)
- **Linting**: Uses cpplint with configuration in `CPPLINT.cfg`

### Key CMake Options
- `BUILD_CTL=ON/OFF` - Build drogon_ctl command line tool
- `BUILD_EXAMPLES=ON/OFF` - Build example applications
- `BUILD_ORM=ON/OFF` - Build ORM functionality
- `BUILD_SHARED_LIBS=ON/OFF` - Build as shared library
- `BUILD_POSTGRESQL=ON/OFF` - PostgreSQL support
- `BUILD_MYSQL=ON/OFF` - MySQL/MariaDB support
- `BUILD_SQLITE=ON/OFF` - SQLite support
- `BUILD_REDIS=ON/OFF` - Redis support
- `USE_COROUTINE=ON/OFF` - C++20 coroutine support
- `BUILD_YAML_CONFIG=ON/OFF` - YAML configuration support
- `BUILD_BROTLI=ON/OFF` - Brotli compression support
- `USE_SUBMODULE=ON/OFF` - Use Trantor as submodule
- `BUILD_DOC=ON/OFF` - Build Doxygen documentation
- `COZ_PROFILING=ON/OFF` - Use coz for profiling
- `LIBPQ_BATCH_MODE=ON/OFF` - Use batch mode for libpq
- `USE_SPDLOG=ON/OFF` - Allow using spdlog logging library
- `USE_STATIC_LIBS_ONLY=ON/OFF` - Use only static libraries as dependencies

## Architecture Overview

### Core Components

**Framework Architecture**:
- **HttpAppFramework**: Main application interface (in `lib/inc/drogon/HttpAppFramework.h`)
- **HttpAppFrameworkImpl**: Implementation details (in `lib/src/HttpAppFrameworkImpl.h`)
- **Event Loop**: Based on Trantor library (submodule in `trantor/`)
- **Asynchronous Design**: All handlers use callback pattern for high concurrency

**Key Subsystems**:
1. **HTTP Server** (`lib/src/HttpServer.cc`) - Core HTTP server implementation
2. **Request/Response** (`lib/src/HttpRequestImpl.cc`, `lib/src/HttpResponseImpl.cc`) - HTTP message handling
3. **Routing** (`lib/src/HttpControllersRouter.cc`) - URL routing to controllers
4. **Controllers** - Multiple types: `HttpController`, `HttpSimpleController`, `WebSocketController`
5. **Filters** (`lib/src/HttpFilter.h`) - Request processing pipeline
6. **Plugins** (`lib/inc/drogon/plugins/`) - Extensible plugin system
7. **Session Management** (`lib/src/SessionManager.cc`) - User session handling
8. **Static Files** (`lib/src/StaticFileRouter.cc`) - Static file serving

### Database Layer (ORM)

**ORM Structure** (`orm_lib/`):
- **DbClient** (`orm_lib/inc/drogon/orm/DbClient.h`) - Database client interface
- **Mapper** (`orm_lib/inc/drogon/orm/Mapper.h`) - ORM mapping
- **CoroMapper** (`orm_lib/inc/drogon/orm/CoroMapper.h`) - Coroutine-based ORM
- **Database Implementations**:
  - PostgreSQL (`orm_lib/src/postgresql_impl/`)
  - MySQL (`orm_lib/src/mysql_impl/`)
  - SQLite (`orm_lib/src/sqlite3_impl/`)

### NoSQL Layer

**Redis Support** (`nosql_lib/redis/`):
- **RedisClient** (`nosql_lib/redis/inc/drogon/nosql/RedisClient.h`) - Redis client interface
- **RedisSubscriber** - Pub/sub support
- **Async Implementation** - Non-blocking Redis operations

### Command Line Tool

**drogon_ctl** (`drogon_ctl/`):
- Project scaffolding: `drogon_ctl create project <name>`
- Controller generation: `drogon_ctl create controller <name>`
- Filter generation: `drogon_ctl create filter <name>`
- Plugin generation: `drogon_ctl create plugin <name>`
- View generation: `drogon_ctl create view <name>`

## Development Guidelines

### Code Style
- Uses clang-format version 17 for consistent formatting (enforced by `format.sh`)
- cpplint configuration in `CPPLINT.cfg` with specific filters for Drogon
- C++17/20 features allowed based on compiler support
- Follow existing patterns in the codebase
- Line ending conversion: `format.sh` automatically converts line endings with `dos2unix`

### Project Structure
- **Public API**: `lib/inc/drogon/` - Header files for users
- **Implementation**: `lib/src/` - Private implementation files
- **ORM**: `orm_lib/` - Database abstraction layer
- **NoSQL**: `nosql_lib/` - Redis client implementation
- **Examples**: `examples/` - Usage examples
- **Tests**: `lib/tests/` - Unit and integration tests

### Configuration
- JSON configuration support (`config.example.json`)
- YAML configuration support (optional)
- Environment-based configuration through framework interface

### Key Dependencies
- **Trantor**: Network library (submodule, can use external)
- **Jsoncpp**: JSON processing
- **yaml-cpp**: YAML configuration (optional)
- **OpenSSL**: SSL/TLS support
- **zlib**: Compression support
- **Database clients**: libpq, MariaDB/MySQL, SQLite3
- **Redis**: hiredis client library

### Platform Support
- Linux, macOS, FreeBSD, OpenBSD, HaikuOS, Windows
- Cross-compilation support through CMake toolchains
- ARM architecture support

### Common Development Patterns
- Use `app()` macro to access HttpAppFramework instance
- Controllers use `asyncHandleHttpRequest` with callback pattern
- Database operations support both callback and coroutine patterns
- Plugins implement lifecycle hooks for initialization and shutdown
- Filters provide pre/post request processing capabilities
- Controllers can be registered via macros or configuration files
- Use `drogon_ctl` tool for code generation and project scaffolding
- Configuration can be loaded from JSON or YAML files
- Framework supports both static and dynamic view loading