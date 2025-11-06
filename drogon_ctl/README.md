# Drogon Command Line Tool (drogon_ctl) Documentation

## Overview

The `drogon_ctl` command line tool is a powerful utility for generating and managing Drogon framework components. It provides a comprehensive set of commands for creating projects, controllers, models, filters, plugins, and views, significantly reducing development time and ensuring consistency across Drogon applications.

## Architecture

### Core Components

#### 1. Command System (`cmd.h`, `cmd.cc`)
The command system provides a flexible architecture for handling different commands:
- **Dynamic Command Loading**: Uses Drogon's reflection system to load command handlers
- **Parameter Parsing**: Handles command-line arguments and parameters
- **Error Handling**: Provides meaningful error messages for invalid commands

**Command Processing:**
```cpp
void exeCommand(std::vector<std::string> &parameters)
{
    std::string command = parameters[0];
    std::string handlerName = std::string("drogon_ctl::").append(command);
    
    // Dynamic command loading via reflection
    auto obj = std::shared_ptr<DrObjectBase>(
        drogon::DrClassMap::newObject(handlerName));
    
    if (obj) {
        auto ctl = std::dynamic_pointer_cast<CommandHandler>(obj);
        if (ctl) {
            ctl->handleCommand(parameters);
        }
    }
}
```

#### 2. CommandHandler Interface (`CommandHandler.h`)
Base interface for all command implementations:
- **Command Execution**: `handleCommand()` method for command processing
- **Command Metadata**: `script()` and `detail()` for help information
- **Top-Level Commands**: `isTopCommand()` for command hierarchy

**Interface Definition:**
```cpp
class CommandHandler : public virtual drogon::DrObjectBase
{
  public:
    virtual void handleCommand(std::vector<std::string> &parameters) = 0;
    virtual bool isTopCommand() { return false; }
    virtual std::string script() { return ""; }
    virtual std::string detail() { return ""; }
};
```

#### 3. Template System (`templates/`)
Comprehensive template system for code generation:
- **CSP Templates**: Custom template language with variable substitution
- **Code Generation**: Generates consistent, well-structured code
- **Multiple Targets**: Supports different types of components

## Commands

### 1. Create Command (`create.h`, `create.cc`)
The main create command that orchestrates all creation operations:
- **Command Routing**: Routes to specific create subcommands
- **Help System**: Provides help for all create operations
- **Error Handling**: Validates parameters and provides meaningful errors

**Usage:**
```bash
drogon_ctl create <subcommand> [options]
```

### 2. Create Project (`create_project.h`)
Creates complete Drogon project structures:
- **Project Scaffolding**: Generates complete project directory structure
- **Build Configuration**: Creates CMakeLists.txt and build configuration
- **Configuration Files**: Generates JSON/YAML configuration templates
- **Main File**: Creates main.cc with basic setup

**Generated Structure:**
```
project_name/
├── CMakeLists.txt
├── config.json
├── main.cc
├── controllers/
├── models/
├── filters/
├── plugins/
└── views/
```

**Usage:**
```bash
drogon_ctl create project <project_name>
```

### 3. Create Controller (`create_controller.h`)
Creates controller classes with various types:
- **Simple Controllers**: Basic HTTP controllers
- **HTTP Controllers**: Full-featured HTTP controllers with routing
- **WebSocket Controllers**: WebSocket-based controllers
- **RESTful Controllers**: REST API controllers with CRUD operations

**Controller Types:**
```cpp
enum ControllerType
{
    Simple = 0,    // Simple HTTP controller
    Http,          // Full HTTP controller
    WebSocket,     // WebSocket controller
    Restful        // RESTful controller
};
```

**Usage:**
```bash
# Create simple controller
drogon_ctl create controller <controller_name>

# Create HTTP controller
drogon_ctl create controller -h <controller_name>

# Create WebSocket controller
drogon_ctl create controller -w <controller_name>

# Create RESTful controller
drogon_ctl create controller -r <resource_name> <controller_name>
```

### 4. Create Model (`create_model.h`)
Creates ORM model classes from database schemas:
- **Database Analysis**: Analyzes database schema and table structures
- **Model Generation**: Generates type-safe model classes
- **Relationship Support**: Handles table relationships (hasOne, hasMany, manyToMany)
- **Data Type Mapping**: Maps database types to C++ types
- **Validation**: Generates validation logic for model data

**Advanced Features:**
```cpp
struct ColumnInfo {
    std::string colName_;
    std::string colValName_;
    std::string colTypeName_;
    std::string colType_;
    std::string colDatabaseType_;
    ssize_t colLength_{0};
    bool isAutoVal_{false};
    bool isPrimaryKey_{false};
    bool notNull_{false};
    bool hasDefaultVal_{false};
};

class Relationship {
    enum class Type { HasOne, HasMany, ManyToMany };
    // Relationship configuration and methods
};
```

**Usage:**
```bash
# Create model from PostgreSQL
drogon_ctl create model -t postgresql -c "host=localhost dbname=test user=test" -o ./models

# Create model from MySQL
drogon_ctl create model -t mysql -c "host=localhost dbname=test user=test" -o ./models

# Create model from SQLite3
drogon_ctl create model -t sqlite3 -c "filename=test.db" -o ./models

# Create model with relationships
drogon_ctl create model -t postgresql -c "conn_string" -o ./models --relationships relationships.json
```

### 5. Create Filter (`create_filter.h`)
Creates filter classes for request processing:
- **Filter Generation**: Generates filter classes with lifecycle methods
- **Request Processing**: Implements pre/post request processing hooks
- **Chain Support**: Supports filter chaining for complex processing

**Usage:**
```bash
drogon_ctl create filter <filter_name>
```

### 6. Create Plugin (`create_plugin.h`)
Creates plugin classes for framework extension:
- **Plugin Generation**: Generates plugin classes with lifecycle methods
- **Configuration Support**: Implements configuration loading and management
- **Framework Integration**: Provides proper framework integration points

**Usage:**
```bash
drogon_ctl create plugin <plugin_name>
```

### 7. Create View (`create_view.h`)
Creates view classes with template support:
- **View Generation**: Generates view classes with template processing
- **Namespace Support**: Handles namespace generation from paths
- **Template Integration**: Integrates with Drogon's template system

**Usage:**
```bash
drogon_ctl create view <view_name>
```

### 8. Help Command (`help.h`)
Provides comprehensive help information:
- **Command Documentation**: Lists all available commands
- **Usage Information**: Provides detailed usage instructions
- **Examples**: Shows practical usage examples

**Usage:**
```bash
drogon_ctl help [command]
```

## Template System

### Template Language Features
The template system uses a custom CSP (C++ Server Pages) language with the following features:

#### 1. Variable Substitution
```csp
[[variable_name]]    // Simple variable substitution
{@variable_name@}    // Escaped substitution
```

#### 2. Control Structures
```csp
<%c++ if (condition) { %>
    // Template content
<%c++ } else { %>
    // Alternative content
<%c++ } %>

<%c++ for (auto &item : items) { %>
    // Loop content
<%c++ } %>
```

#### 3. Code Injection
```csp
<%c++
    // C++ code executed during template processing
    std::string result = "processed";
%>
```

### Template Files

#### 1. Main Template (`demoMain.csp`)
Generates main application file:
```cpp
#include <drogon/drogon.h>
int main() {
    //Set HTTP listener address and port
    drogon::app().addListener("0.0.0.0", 5555);
    //Load config file
    //drogon::app().loadConfigFile("../config.json");
    //drogon::app().loadConfigFile("../config.yaml");
    //Run HTTP framework,the method will block in the internal event loop
    drogon::app().run();
    return 0;
}
```

#### 2. RESTful Controller Template (`restful_controller_cc.csp`)
Generates RESTful controller implementation:
```cpp
void [[className]]::getOne(const HttpRequestPtr &req,
     std::function<void(const HttpResponsePtr &)> &&callback,
     std::string &&id)
{
}

void [[className]]::get(const HttpRequestPtr &req,
     std::function<void(const HttpResponsePtr &)> &&callback)
{
}

void [[className]]::create(const HttpRequestPtr &req,
     std::function<void(const HttpResponsePtr &)> &&callback)
{
}

void [[className]]::updateOne(const HttpRequestPtr &req,
     std::function<void(const HttpResponsePtr &)> &&callback,
     std::string &&id)
{
}

void [[className]]::deleteOne(const HttpRequestPtr &req,
     std::function<void(const HttpResponsePtr &)> &&callback,
     std::string &&id)
{
}
```

#### 3. Model Template (`model_cc.csp`)
Generates comprehensive model class with:
- **Data Mapping**: Database to C++ type mapping
- **Validation**: JSON validation logic
- **Relationships**: Relationship management methods
- **CRUD Operations**: Create, Read, Update, Delete operations
- **Serialization**: JSON serialization and deserialization

**Key Generated Features:**
```cpp
// Type-safe getters and setters
const std::string &getValueOfName() const noexcept;
void setName(const std::string &pName) noexcept;

// JSON support
Json::Value toJson() const;
bool validateJsonForCreation(const Json::Value &pJson, std::string &err);

// Relationship methods
std::vector<RelatedModel> getRelated(const DbClientPtr &clientPtr) const;

// Database operations
static Mapper<Model> mapper(const DbClientPtr &clientPtr);
```

## Configuration Files

### 1. CMake Configuration (`cmake.csp`)
Generated CMakeLists.txt with:
- **Project Configuration**: Project name and version
- **Dependencies**: Drogon and other dependencies
- **Build Targets**: Executable and library targets
- **Installation Rules**: Installation paths and targets

### 2. Configuration Templates (`config_json.csp`, `config_yaml.csp`)
Framework configuration files with:
- **Database Configuration**: Database connection settings
- **Logging Configuration**: Log levels and outputs
- **Application Settings**: Application-specific settings
- **SSL Configuration**: SSL/TLS settings

## Best Practices

### 1. Project Organization
- Use consistent naming conventions
- Organize files in appropriate directories
- Follow the generated project structure
- Keep configuration files in the root directory

### 2. Model Generation
- Generate models from actual database schemas
- Use meaningful table and column names
- Configure relationships properly
- Review generated validation logic

### 3. Controller Design
- Choose the appropriate controller type for your use case
- Use RESTful controllers for APIs
- Implement proper error handling
- Follow REST conventions for RESTful controllers

### 4. Template Customization
- Backup original templates before customization
- Test custom templates thoroughly
- Keep templates maintainable and readable
- Document custom template features

### 5. Version Control
- Exclude generated files from version control
- Use `.gitignore` files appropriately
- Commit templates and configuration files
- Document generation commands in project documentation

## Advanced Usage

### 1. Custom Templates
Create custom templates for project-specific requirements:
```bash
# Create custom template directory
mkdir ~/.drogon_ctl/templates
# Copy and modify templates
cp /path/to/drogon/templates/custom_template.csp ~/.drogon_ctl/templates/
```

### 2. Batch Operations
Generate multiple components at once:
```bash
# Generate multiple controllers
for controller in users products orders; do
    drogon_ctl create controller -r $controller ${controller}Controller
done

# Generate models for all tables
drogon_ctl create model -t postgresql -c "conn_string" -o ./models --all-tables
```

### 3. Integration with Build Systems
Integrate drogon_ctl with build automation:
```cmake
# CMake example
find_program(DROGON_CTL drogon_ctl)
if(DROGON_CTL)
    add_custom_command(
        OUTPUT ${CMAKE_CURRENT_SOURCE_DIR}/models/User.h
        COMMAND ${DROGON_CTL} create model -t postgresql -c "conn_string" User
        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/schema.sql
    )
endif()
```

## Troubleshooting

### Common Issues

1. **Command Not Found**: Ensure drogon_ctl is in PATH
2. **Template Errors**: Check template syntax and variable names
3. **Database Connection**: Verify database connection strings and credentials
4. **Generation Failures**: Check file permissions and disk space

### Debug Tips

- Use `drogon_ctl help` for command documentation
- Enable verbose logging with environment variables
- Check generated files for compilation errors
- Verify database connectivity before model generation

### Error Messages

- **"args error!"**: Invalid command syntax or missing parameters
- **"command not found!"**: Unknown command or typo in command name
- **"Template processing failed"**: Template syntax error or missing variables
- **"Database connection failed"**: Invalid connection string or credentials

## Integration Examples

### 1. New Project Setup
```bash
# Create new project
drogon_ctl create project myapp
cd myapp

# Create controllers
drogon_ctl create controller -r users UserController
drogon_ctl create controller -r products ProductController

# Create models
drogon_ctl create model -t postgresql -c "host=localhost dbname=myapp user=postgres" User
drogon_ctl create model -t postgresql -c "host=localhost dbname=myapp user=postgres" Product

# Create filters
drogon_ctl create filter AuthFilter
drogon_ctl create filter LoggingFilter
```

### 2. Existing Project Enhancement
```bash
# Add new controller to existing project
drogon_ctl create controller -h ApiHeaderController

# Generate models from existing database
drogon_ctl create model -t mysql -c "host=localhost dbname=existing user=user" -o ./models

# Create plugin for new functionality
drogon_ctl create plugin CachePlugin
```

## Conclusion

The `drogon_ctl` command line tool is an essential utility for Drogon framework development, providing comprehensive code generation capabilities that significantly accelerate development while maintaining consistency and best practices. By leveraging its powerful template system and extensible architecture, developers can quickly scaffold projects, generate models, create controllers, and manage various framework components with minimal effort.

The tool's integration with Drogon's reflection system, combined with its comprehensive template library, makes it an invaluable asset for both new and experienced Drogon developers, enabling rapid application development while maintaining high code quality and consistency.