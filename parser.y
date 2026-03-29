%{

#include <iostream>
#include <cstdio>
#include <unordered_map>
#include <vector>
#include <string>

extern int yylineno; //Hey, this variable exists somewhere else (lexer), use it here

/* Function declarations */
int yylex(); //Parser calls lexer using this function
void yyerror(const char *s);
extern FILE* yyin;

/*
 * Runtime debug switch for parser-side logs.
 * false = normal mode (clean output)
 * true  = debug mode (detailed semantic/parsing steps)
 */
bool DEBUG_MODE = false;

/*
 * Optional runtime switch:
 * true  -> print AST even in non-debug mode
 * false -> AST printing follows DEBUG_MODE only
 */
bool AST_MODE = false;

void debugLog(const std::string& msg) {
    if (DEBUG_MODE) {
        std::cout << "[DEBUG] " << msg << std::endl;
    }
}

/* Canonical type used by parser + symbol table. */
#ifndef TYPE_KIND_ENUM_DEFINED
#define TYPE_KIND_ENUM_DEFINED
enum class TypeKind {
    Int,
    Float,
    String,
    Flag,
    Error,
    Unknown
};
#endif

//This function takes a TypeKind and returns a string (text name) so in debug logs we can print "int" instead of "TypeKind::Int"
static std::string typeName(TypeKind type) {
    switch (type) {
        case TypeKind::Int: return "int";
        case TypeKind::Float: return "float";
        case TypeKind::String: return "string";
        case TypeKind::Flag: return "flag";
        case TypeKind::Error: return "error";
        default: return "unknown";
    }
}

// helper functions for type checking and semantic analysis

static bool isErrorType(TypeKind type) {
    return type == TypeKind::Error;
}

static bool isNumericType(TypeKind type) {
    return type == TypeKind::Int || type == TypeKind::Float;
}

static bool canAssignType(TypeKind leftType, TypeKind rightType) {
    if (leftType == rightType) {
        return true;
    }

    /* implicit promotion is allowed only from int to float */
    if (leftType == TypeKind::Float && rightType == TypeKind::Int) {
        return true;
    }

    return false;
}

/*
 * Numeric binary operator result:
 * int + int -> int
 * int + float / float + int / float + float -> float
 * invalid numeric combinations -> Error
 */
static TypeKind numericResultType(TypeKind leftType, TypeKind rightType) {
    if (!isNumericType(leftType) || !isNumericType(rightType)) {
        return TypeKind::Error;
    }

    if (leftType == TypeKind::Float || rightType == TypeKind::Float) {
        return TypeKind::Float;
    }

    return TypeKind::Int;
}

/*
 * Helper: check whether a numeric literal text represents zero.
 * Examples that return true: "0", "00", "0.0", "00.00"
 * We use this for built-in safety checks like division by zero.
 */
static bool isZeroNumericLiteralText(const std::string& text) {
    if (text.empty()) return false;

    bool seenDot = false;
    for (char ch : text) {
        if (ch == '.') {
            if (seenDot) return false; // invalid numeric shape
            seenDot = true;
            continue;
        }

        if (ch != '0') {
            return false;
        }
    }

    return true;
}

/* ================= SIMPLE AST =================
 * These classes are intentionally small and easy to read.
 * They let us keep semantic checking and also build a tree.
 */

/* Base class for all AST nodes. */
class ASTNode {
public:
    virtual ~ASTNode() = default;
    virtual void print(int indent = 0) const = 0;
protected:
    static void printIndent(int indent) {
        for (int i = 0; i < indent; ++i) std::cout << "  ";
    }
};

/* Base class for expression nodes. */
class ExprNode : public ASTNode {
public:
    /*
     * Emit IR for this expression and return the temporary/variable name
     * that holds the computed result.
     */
    virtual std::string generateIR(std::vector<std::string>& ir,
                                   int& tempCounter) const = 0;

    /*
     * Default behavior: most expressions are NOT guaranteed numeric zero.
     * Specific nodes (like NumberNode) can override this.
     */
    virtual bool isZeroNumericLiteral() const { return false; }
};

/* Base class for statement nodes. */
class StmtNode : public ASTNode {
public:
    /* Emit IR lines for this statement. */
    virtual void generateIR(std::vector<std::string>& ir,
                            int& tempCounter,
                            int& labelCounter) const = 0;
};

/* Literal expression like integer/float/string/true/false. */
class LiteralExpr : public ExprNode {
private:
    std::string value;
    bool isStringLiteral;
public:
    explicit LiteralExpr(const std::string& literalValue, bool isString = false)
        : value(literalValue), isStringLiteral(isString) {} //Create a literal node
    void print(int indent = 0) const override {
        printIndent(indent);
        std::cout << "Literal(" << value << ")\n";
    }

    std::string generateIR(std::vector<std::string>&,
                           int&) const override {
        // Wrap string values in quotes for correct IR representation.
        if (isStringLiteral) {
            return std::string("\"") + value + "\"";
        }
        return value;
    }
};

/*
 * Number expression keeps the original numeric lexeme from source code.
 * Example: "5", "12", "3.14"
 */
class NumberNode : public ExprNode {
private:
    TypeKind numberType;
    std::string lexeme; // original text of the numeric literal, used for IR generation and zero checks
public:
    NumberNode(TypeKind type, const std::string& text)
        : numberType(type), lexeme(text) {}

    void print(int indent = 0) const override {
        printIndent(indent);
        std::cout << "Number(" << typeName(numberType) << ": " << lexeme << ")\n";
    }

    std::string generateIR(std::vector<std::string>&,
                           int&) const override {
        return lexeme;
    }

    /*
     * This lets semantic checks detect literal zero like 0 or 0.0.
     */
    bool isZeroNumericLiteral() const override {
        return isZeroNumericLiteralText(lexeme);
    }
};

/* Variable reference expression. */
class IdentifierExpr : public ExprNode {
private:
    std::string name;
public:
    explicit IdentifierExpr(const std::string& identifierName) : name(identifierName) {}
    void print(int indent = 0) const override {
        printIndent(indent);
        std::cout << "Identifier(" << name << ")\n";
    }

    std::string generateIR(std::vector<std::string>&,
                           int&) const override {
        return name;
    }
};

/* Unary expression like NOT x or -x. */
class UnaryExpr : public ExprNode {
private:
    std::string op;
    ExprNode* operand;
public:
    UnaryExpr(const std::string& opName, ExprNode* expr) : op(opName), operand(expr) {}
    ~UnaryExpr() override { delete operand; }
    void print(int indent = 0) const override {
        printIndent(indent);
        std::cout << "Unary(" << op << ")\n";
        if (operand) operand->print(indent + 1); //Unary(NEGATE) Identifier(x)
    }

    std::string generateIR(std::vector<std::string>& ir,
                           int& tempCounter) const override {
        std::string operandName = operand ? operand->generateIR(ir, tempCounter) : "0"; //Recursively generate IR for operand
        std::string tempName = "t" + std::to_string(++tempCounter); //Create a new temporary variable for the result of this unary operation

        std::string irOp = op;
        if (op == "NEGATE") irOp = "-";
        else if (op == "NOT") irOp = "!";

        ir.push_back(tempName + " = " + irOp + " " + operandName);
        return tempName;
    }
};

/* Binary expression like a+b, a<b, a&&b, etc. */
class BinaryExpr : public ExprNode {
private:
    std::string op;
    ExprNode* left;
    ExprNode* right;
public:
    BinaryExpr(const std::string& opName, ExprNode* leftExpr, ExprNode* rightExpr)
        : op(opName), left(leftExpr), right(rightExpr) {}
    ~BinaryExpr() override {
        delete left;
        delete right;
    }
    void print(int indent = 0) const override {
        printIndent(indent);
        std::cout << "Binary(" << op << ")\n";
        if (left) left->print(indent + 1);
        if (right) right->print(indent + 1);
    }

    std::string generateIR(std::vector<std::string>& ir,
                           int& tempCounter) const override {
        std::string leftName = left ? left->generateIR(ir, tempCounter) : "0";
        std::string rightName = right ? right->generateIR(ir, tempCounter) : "0";
        std::string tempName = "t" + std::to_string(++tempCounter);

        std::string irOp = op;
        if (op == "PLUS") irOp = "+";
        else if (op == "MINUS") irOp = "-";
        else if (op == "MULTIPLY") irOp = "*";
        else if (op == "DIVIDE") irOp = "/";
        else if (op == "EQUAL") irOp = "==";
        else if (op == "NOT_EQUAL") irOp = "!=";
        else if (op == "LESS") irOp = "<";
        else if (op == "GREATER") irOp = ">";
        else if (op == "LESS_EQUAL") irOp = "<=";
        else if (op == "GREATER_EQUAL") irOp = ">=";
        else if (op == "AND") irOp = "&&";
        else if (op == "OR") irOp = "||";

        ir.push_back(tempName + " = " + leftName + " " + irOp + " " + rightName);
        return tempName;
    }
};

/* Function call expression like add(1,2). */
class CallExpr : public ExprNode {
private:
    std::string callee; //Name of the function being called
    std::vector<ExprNode*> args; //List of argument expressions passed to the function. Each argument is itself an expression node, allowing for nested calls and complex expressions as arguments.
public:
    CallExpr(const std::string& functionName, std::vector<ExprNode*>* arguments) //Create a function call node with the function name and its argument expressions
        : callee(functionName) {
        if (arguments) {
            args = *arguments;
            delete arguments;
        }
    }
    ~CallExpr() override {
        for (ExprNode* arg : args) delete arg;
    }
    void print(int indent = 0) const override {
        printIndent(indent);
        std::cout << "Call(" << callee << ")\n";
        for (ExprNode* arg : args) {
            if (arg) arg->print(indent + 1);
        }
    }

    std::string generateIR(std::vector<std::string>& ir,
                           int& tempCounter) const override {
        /*
         * Built-in IR expansion for ignite(x)
         * ignite(x) means: (x * 2) + 10
         * We expand this high-level call into simple 3-address steps.
         */
        if (callee == "ignite") {
            /* Safety check: ignite must receive exactly one argument. */
            if (args.size() != 1) {
                std::cout << "Error: ignite expects exactly 1 argument\n";
                return "error";
            }

            /* Generate IR for the argument expression first. */
            std::string argValue = args[0] ? args[0]->generateIR(ir, tempCounter) : "0";

            /* t1 stores the multiplication part: arg * 2 */
            std::string t1 = "t" + std::to_string(++tempCounter);
            ir.push_back(t1 + " = " + argValue + " * 2");

            /* t2 stores the final result: t1 + 10 */
            std::string t2 = "t" + std::to_string(++tempCounter);
            ir.push_back(t2 + " = " + t1 + " + 10");

            /* Return the final temporary holding ignite(x). */
            return t2;
        }

        /*
         * Built-in IR expansion for percent(value, total)
         * percent(a, b) means: (a / b) * 100
         * We expand it into two simple 3-address instructions.
         */
        if (callee == "percent") {
            /* percent must receive exactly two arguments. */
            if (args.size() != 2) {
                std::cout << "Error: percent expects exactly 2 arguments\n";
                return "error";
            }

            /* First generate IR values for both argument expressions. */
            std::string valueArg = args[0] ? args[0]->generateIR(ir, tempCounter) : "0";
            std::string totalArg = args[1] ? args[1]->generateIR(ir, tempCounter) : "0";

            /*
             * Safety check: if total is literal zero, report division by zero.
             * (Semantic phase already checks this for literal arguments too.)
             */
            if (isZeroNumericLiteralText(totalArg)) {
                std::cout << "Error: function 'percent' division by zero\n";
                return "error";
            }

            /* t1 stores the division part: value / total */
            std::string t1 = "t" + std::to_string(++tempCounter);
            ir.push_back(t1 + " = " + valueArg + " / " + totalArg);

            /* t2 stores the final percentage: t1 * 100 */
            std::string t2 = "t" + std::to_string(++tempCounter);
            ir.push_back(t2 + " = " + t1 + " * 100");

            /* Return the temporary that contains percent(value, total). */
            return t2;
        }

        /* Normal function-call IR path (unchanged). */
        std::vector<std::string> argNames;
        for (ExprNode* arg : args) { //For each argument:Generate its IR
            if (arg) {
                argNames.push_back(arg->generateIR(ir, tempCounter));
            }
        }

        std::string tempName = "t" + std::to_string(++tempCounter);
        std::string line = tempName + " = call " + callee + "(";
        for (std::size_t i = 0; i < argNames.size(); ++i) { 
            if (i > 0) line += ", ";
            line += argNames[i];
        }
        line += ")";
        ir.push_back(line);
        return tempName;
    }
};

/* Variable declaration statement, with optional initializer. */
class DeclarationStmt : public StmtNode {
private:
    std::string name;
    TypeKind declaredType;
    ExprNode* initializer;
public:
    DeclarationStmt(const std::string& variableName, TypeKind type, ExprNode* initExpr)
        : name(variableName), declaredType(type), initializer(initExpr) {}
    ~DeclarationStmt() override { delete initializer; }
    void print(int indent = 0) const override {
        printIndent(indent);
        std::cout << "Declaration(" << name << ": " << typeName(declaredType) << ")\n";
        if (initializer) {
            printIndent(indent + 1);
            std::cout << "Initializer:\n";
            initializer->print(indent + 2);
        }
    }

    void generateIR(std::vector<std::string>& ir,
                    int& tempCounter,
                    int&) const override {
        if (initializer) {
            std::string rhs = initializer->generateIR(ir, tempCounter);
            ir.push_back(name + " = " + rhs);
        }
    }
};

/* Assignment statement. */
class AssignmentStmt : public StmtNode {
private:
    std::string name;
    ExprNode* value;
public:
    AssignmentStmt(const std::string& variableName, ExprNode* expr)
        : name(variableName), value(expr) {}
    ~AssignmentStmt() override { delete value; }
    void print(int indent = 0) const override {
        printIndent(indent);
        std::cout << "Assignment(" << name << ")\n";
        if (value) value->print(indent + 1);
    }

    void generateIR(std::vector<std::string>& ir,
                    int& tempCounter,
                    int&) const override {
        std::string rhs = value ? value->generateIR(ir, tempCounter) : "0";
        ir.push_back(name + " = " + rhs);
    }
};

/* Print statement. */
class PrintStmt : public StmtNode {
private:
    ExprNode* value;
public:
    explicit PrintStmt(ExprNode* expr) : value(expr) {}
    ~PrintStmt() override { delete value; }
    void print(int indent = 0) const override {
        printIndent(indent);
        std::cout << "Print\n";
        if (value) value->print(indent + 1);
    }

    void generateIR(std::vector<std::string>& ir,
                    int& tempCounter,
                    int&) const override {
        std::string rhs = value ? value->generateIR(ir, tempCounter) : "";
        ir.push_back("print " + rhs);
    }
};

/* Return statement (with optional expression). */
class ReturnStmt : public StmtNode {
private:
    ExprNode* value;
public:
    explicit ReturnStmt(ExprNode* expr) : value(expr) {}
    ~ReturnStmt() override { delete value; }
    void print(int indent = 0) const override {
        printIndent(indent);
        std::cout << "Return\n";
        if (value) value->print(indent + 1);
    }

    void generateIR(std::vector<std::string>& ir,
                    int& tempCounter,
                    int&) const override {
        if (value) {
            std::string rhs = value->generateIR(ir, tempCounter);
            ir.push_back("return " + rhs);
        } else {
            ir.push_back("return");
        }
    }
};

/* If statement with optional else block. */
class IfStmt : public StmtNode {
private:
    ExprNode* condition;
    std::vector<StmtNode*> thenBranch;
    std::vector<StmtNode*> elseBranch;
public:
    IfStmt(ExprNode* cond, std::vector<StmtNode*>* thenStmts, std::vector<StmtNode*>* elseStmts)
        : condition(cond) {
        if (thenStmts) {
            thenBranch = *thenStmts;
            delete thenStmts;
        }
        if (elseStmts) {
            elseBranch = *elseStmts;
            delete elseStmts;
        }
    }
    ~IfStmt() override {
        delete condition;
        for (StmtNode* stmt : thenBranch) delete stmt;
        for (StmtNode* stmt : elseBranch) delete stmt;
    }
    void print(int indent = 0) const override {
        printIndent(indent);
        std::cout << "If\n";
        if (condition) {
            printIndent(indent + 1);
            std::cout << "Condition:\n";
            condition->print(indent + 2);
        }
        printIndent(indent + 1);
        std::cout << "Then:\n";
        for (StmtNode* stmt : thenBranch) {
            if (stmt) stmt->print(indent + 2);
        }
        if (!elseBranch.empty()) {
            printIndent(indent + 1);
            std::cout << "Else:\n";
            for (StmtNode* stmt : elseBranch) {
                if (stmt) stmt->print(indent + 2);
            }
        }
    }

    void generateIR(std::vector<std::string>& ir,
                    int& tempCounter,
                    int& labelCounter) const override {
        std::string conditionName = condition ? condition->generateIR(ir, tempCounter) : "false";

        int elseLabel = ++labelCounter;
        int endLabel = ++labelCounter;

        ir.push_back("ifFalse " + conditionName + " goto L" + std::to_string(elseLabel));
        for (StmtNode* stmt : thenBranch) {
            if (stmt) stmt->generateIR(ir, tempCounter, labelCounter);
        }
        ir.push_back("goto L" + std::to_string(endLabel));
        ir.push_back("L" + std::to_string(elseLabel) + ":");
        for (StmtNode* stmt : elseBranch) {
            if (stmt) stmt->generateIR(ir, tempCounter, labelCounter);
        }
        ir.push_back("L" + std::to_string(endLabel) + ":");
    }
};

/* Loop statement. */
class LoopStmt : public StmtNode {
private:
    ExprNode* condition;
    std::vector<StmtNode*> body;
public:
    LoopStmt(ExprNode* cond, std::vector<StmtNode*>* bodyStmts)
        : condition(cond) {
        if (bodyStmts) {
            body = *bodyStmts;
            delete bodyStmts;
        }
    }
    ~LoopStmt() override {
        delete condition;
        for (StmtNode* stmt : body) delete stmt;
    }
    void print(int indent = 0) const override {
        printIndent(indent);
        std::cout << "Loop\n";
        if (condition) {
            printIndent(indent + 1);
            std::cout << "Condition:\n";
            condition->print(indent + 2);
        }
        printIndent(indent + 1);
        std::cout << "Body:\n";
        for (StmtNode* stmt : body) {
            if (stmt) stmt->print(indent + 2);
        }
    }

    void generateIR(std::vector<std::string>& ir,
                    int& tempCounter,
                    int& labelCounter) const override {
        int startLabel = ++labelCounter;
        int endLabel = ++labelCounter;

        ir.push_back("L" + std::to_string(startLabel) + ":");
        std::string conditionName = condition ? condition->generateIR(ir, tempCounter) : "false";
        ir.push_back("ifFalse " + conditionName + " goto L" + std::to_string(endLabel));
        for (StmtNode* stmt : body) {
            if (stmt) stmt->generateIR(ir, tempCounter, labelCounter);
        }
        ir.push_back("goto L" + std::to_string(startLabel));
        ir.push_back("L" + std::to_string(endLabel) + ":");
    }
};

/* Small helper node for parser error-recovery statements. */
class ErrorStmt : public StmtNode {
public:
    void print(int indent = 0) const override {
        printIndent(indent);
        std::cout << "ErrorStmt\n";
    }

    void generateIR(std::vector<std::string>&,
                    int&,
                    int&) const override {
        /* No IR emitted for parser recovery nodes. */
    }
};

/* Expression semantic result: carry both type and AST expression node. */
struct ExprResult {
    TypeKind type;
    ExprNode* node;

    ExprResult() : type(TypeKind::Unknown), node(nullptr) {}
    ExprResult(TypeKind valueType, ExprNode* valueNode) : type(valueType), node(valueNode) {}
    ~ExprResult() { delete node; }
};

/*
 * Keeps both semantic types and AST argument nodes for a function call.
 * This makes it easy to do type checking and AST construction together.
 */
struct CallArgPack {
    std::vector<TypeKind>* argTypes;
    std::vector<ExprNode*>* argNodes;

    CallArgPack() {
        argTypes = new std::vector<TypeKind>();
        argNodes = new std::vector<ExprNode*>();
    }

    ~CallArgPack() {
        delete argTypes;
        if (argNodes) {
            for (ExprNode* node : *argNodes) delete node;
            delete argNodes;
        }
    }
};

/* Program root for printing AST after parsing. */
class ProgramAST : public ASTNode {
private:
    std::vector<StmtNode*> mainStatements;
public:
    explicit ProgramAST(std::vector<StmtNode*>* stmts) {
        if (stmts) {
            mainStatements = *stmts;
            delete stmts;
        }
    }
    ~ProgramAST() override {
        for (StmtNode* stmt : mainStatements) delete stmt;
    }
    void print(int indent = 0) const override {
        printIndent(indent);
        std::cout << "ProgramAST\n";
        for (StmtNode* stmt : mainStatements) {
            if (stmt) stmt->print(indent + 1);
        }
    }

    std::vector<std::string> generateIR() const {
        std::vector<std::string> ir;
        int tempCounter = 0;
        int labelCounter = 0;

        for (StmtNode* stmt : mainStatements) {
            if (stmt) stmt->generateIR(ir, tempCounter, labelCounter);
        }

        return ir;
    }
};

static ProgramAST* gProgramAst = nullptr; //Global pointer to the root of the AST, set by the parser after successful parsing Store final AST here so we can print it or generate IR after parsing is done

std::string currentFunctionName = "";
TypeKind currentFunctionDeclaredType = TypeKind::Unknown;
TypeKind inferredReturnType = TypeKind::Unknown;

/* ================= SYMBOL TABLE ================= */

class SymbolTable {
private:
    // Stack of scopes (each scope = hashmap)
    std::vector<std::unordered_map<std::string, TypeKind>> scopes;

    struct FunctionInfo {
        TypeKind returnType;
        std::vector<TypeKind> paramTypes;
    };

    std::unordered_map<std::string, std::vector<FunctionInfo>> functions;

public:
    // Enter new scope
    void enterScope() {
        scopes.push_back({});
    }

    // Exit current scope
    void exitScope() {
        if (!scopes.empty()) {
            scopes.pop_back();
        }
    }

    // Add variable to current scope
    void addSymbol(const std::string& name, TypeKind type) {
        if (scopes.empty()) {
            std::cout << "Internal Error: No active scope\n";
            return;
        }

        auto& current = scopes.back();

        // Check redeclaration in SAME scope only
        if (current.find(name) != current.end()) {
            std::cout << "Error: Variable '" << name
                      << "' already declared in this scope\n";
            return;
        }

        current[name] = type;
    }

    // Lookup variable (search from inner → outer scope)
    bool lookupSymbol(const std::string& name) const {
        for (auto it = scopes.rbegin(); it != scopes.rend(); ++it) {
            if (it->find(name) != it->end()) {
                return true;
            }
        }
        return false;
    }

    // (Optional) Get type of variable
    TypeKind getType(const std::string& name) const {
        for (auto it = scopes.rbegin(); it != scopes.rend(); ++it) {
            auto found = it->find(name);
            if (found != it->end()) {
                return found->second;
            }
        }
        return TypeKind::Unknown; // not found
    }

    // Debug: print all scopes
    void printTable() const {
        std::cout << "\n===== Symbol Table =====\n";

        int level = scopes.size();

        for (auto it = scopes.rbegin(); it != scopes.rend(); ++it) {
            std::cout << "Scope Level " << level-- << ":\n";

            for (const auto& entry : *it) {
                std::cout << "  " << entry.first << " : " << typeName(entry.second) << "\n";
            }

            std::cout << "\n";
        }
    }


    void addFunction(const std::string& name,
                 TypeKind returnType,
                 const std::vector<TypeKind>& params) {

        auto& list = functions[name];

        // check duplicate signature
        for (const auto& f : list) {
            if (f.paramTypes == params) {
                std::cout << "Error: Function '" << name
                        << "' already declared with same parameters\n";
                return;
            }
        }

        list.push_back({returnType, params});
    }
// Check if function name exists (ignoring parameters)
    bool hasFunction(const std::string& name) const {
        return functions.find(name) != functions.end();
    }
// Check if function with specific arity exists (ignoring parameter types) how many parameters does the function have, regardless of their types
    bool hasFunctionArity(const std::string& name, std::size_t arity) const {
        auto it = functions.find(name);
        if (it == functions.end()) return false;

        for (const auto& f : it->second) {
            if (f.paramTypes.size() == arity) {
                return true;
            }
        }

        return false;
    }
// Resolve function by name and exact parameter types. Returns Error type if not found or ambiguous.
    FunctionInfo resolveFunction(const std::string& name,
                             const std::vector<TypeKind>& args) const {

        auto it = functions.find(name);
        if (it == functions.end()) return {TypeKind::Error, {}};

        for (const auto& f : it->second) {
            if (f.paramTypes == args) {
                return f;
            }
        }

        return {TypeKind::Error, {}};
    }
};

SymbolTable symTable;




%}

%code requires {
#include <string>
#include <vector>
#ifndef TYPE_KIND_ENUM_DEFINED
#define TYPE_KIND_ENUM_DEFINED
enum class TypeKind {
    Int,
    Float,
    String,
    Flag,
    Error,
    Unknown
};
#endif

class ExprNode;
class StmtNode;
struct ExprResult;
struct CallArgPack;
}

/* Better default syntax messages from Bison. */
%define parse.error verbose
/* Enable location tracking support in parser states. */
%locations //Track line + column

/* ================= TOKENS ================= */
%union {
    std::string* str;
    TypeKind* type;
    std::vector<TypeKind>* type_list;
    ExprResult* expr_res;
    CallArgPack* call_args;
    StmtNode* stmt_node;
    std::vector<StmtNode*>* stmt_list;
}

/*
 * Safety improvement: on parser error recovery, Bison can discard symbols.
 * These destructors prevent memory leaks for our pointer-based semantic values.
 */
%destructor { delete $$; } <str>
%destructor { delete $$; } <type>
%destructor { delete $$; } <type_list>
%destructor { delete $$; } <expr_res>
%destructor { delete $$; } <call_args>
%destructor { delete $$; } <stmt_node>
%destructor { delete $$; } <stmt_list>

%token <str> IDENTIFIER
%type <type> type
%type <expr_res> expression logical relational additive multiplicative unary primary

%type <type> param
%type <type_list> param_list
%type <type_list> param_list_opt
%type <call_args> arg_list
%type <call_args> arg_list_opt
%type <stmt_node> statement declaration assignment print_stmt if_stmt loop_stmt return_stmt
%type <stmt_list> statements statements_opt block if_tail

%token MISSION MODULE CHECK OTHERWISE ORBIT TRANSMIT RETURN START END
%token INT FLOAT STRING FLAG
%token <str> INTEGER_LITERAL
%token <str> FLOAT_LITERAL
%token <str> STRING_LITERAL
%token TRUE FALSE

%token PLUS MINUS MULTIPLY DIVIDE
%token ASSIGN
%token EQUAL NOT_EQUAL LESS GREATER LESS_EQUAL GREATER_EQUAL
%token AND OR NOT

%token LPAREN RPAREN LBRACE RBRACE LBRACKET RBRACKET
%token SEMICOLON COMMA

/* ================= PRECEDENCE ================= */
%left OR
%left AND
%left EQUAL NOT_EQUAL
%left LESS GREATER LESS_EQUAL GREATER_EQUAL
%left PLUS MINUS
%left MULTIPLY DIVIDE
%right NOT

%%
/****************** GRAMMAR RULES ******************/

/* Program Structure */
program:
    functions MISSION IDENTIFIER START {
        symTable.enterScope();
        delete $3;
    }
    statements_opt END {
        delete gProgramAst;
        gProgramAst = new ProgramAST($6);
        symTable.exitScope();

        if (DEBUG_MODE) {
            std::cout << "Program parsed successfully\n";
            symTable.printTable();
        }

        /*
         * Print AST in either full debug mode or AST-only mode.
         * This helps when user wants tree output without token spam.
         */
        if (DEBUG_MODE || AST_MODE) {
            std::cout << "\n===== AST =====\n";
            gProgramAst->print();
        }

        std::cout << "\n===== IR (3-Address Code) =====\n";
        std::vector<std::string> ir = gProgramAst->generateIR();
        for (const std::string& line : ir) {
            std::cout << line << "\n";
        }
    }
;

/* Statements */
statements_opt:
            /* empty */ { $$ = new std::vector<StmtNode*>(); }
        | statements   { $$ = $1; }
;

statements:
            statement
            {
                $$ = new std::vector<StmtNode*>();
                $$->push_back($1);
            }
        | statements statement
            {
                $$ = $1;
                $$->push_back($2);
            }
;

/* Statement Types */
statement: declaration { $$ = $1; }
         | assignment  { $$ = $1; }
         | print_stmt  { $$ = $1; }
         | if_stmt     { $$ = $1; }
         | loop_stmt   { $$ = $1; }
         | return_stmt { $$ = $1; }
         | error SEMICOLON {
                yyerrok;
                $$ = new ErrorStmt();
         }
;

/* variable declaration */
declaration:
    type IDENTIFIER SEMICOLON
    {
        std::string varName = *$2;
        symTable.addSymbol(*$2, *$1);
        debugLog("Declared variable: " + *$2 + " (" + typeName(*$1) + ")");
        $$ = new DeclarationStmt(varName, *$1, nullptr);
        delete $2;
        delete $1;
    }
    | type IDENTIFIER ASSIGN expression SEMICOLON
    {
        std::string varName = *$2;
        symTable.addSymbol(*$2, *$1);
        debugLog("Declared variable with init: " + *$2 + " (" + typeName(*$1) + ")");

        TypeKind declaredType = *$1;
        TypeKind valueType = $4->type;
        if (!isErrorType(valueType) && !canAssignType(declaredType, valueType)) {
            std::cout << "Type Error: cannot initialize " << *$2
                      << " of type " << typeName(declaredType)
                      << " with " << typeName(valueType) << "\n";
        }

        $$ = new DeclarationStmt(varName, declaredType, $4->node);
        $4->node = nullptr;

        delete $2;
        delete $1;
        delete $4;
    }
;

/* assignment */
assignment:
    IDENTIFIER ASSIGN expression SEMICOLON
    {
        std::string varName = *$1;
        if(!symTable.lookupSymbol(*$1)) {
            std::cout << "Error: Variable '" << *$1 << "' not declared\n";
        } else {
            TypeKind varType = symTable.getType(*$1);
            TypeKind exprType = $3->type;

            if(!isErrorType(exprType) && !canAssignType(varType, exprType)) {
                std::cout << "Type Error: cannot assign " << typeName(exprType)
                          << " to " << typeName(varType) << "\n";
            } else if (!isErrorType(exprType)) {
                debugLog("Assignment to variable: " + *$1);
            }
        }

        $$ = new AssignmentStmt(varName, $3->node);
        $3->node = nullptr;


        delete $1;
        delete $3;
    }
;

/* print */
print_stmt:
    TRANSMIT expression SEMICOLON
    {
        debugLog("Print statement");
        $$ = new PrintStmt($2->node);
        $2->node = nullptr;
        delete $2;
    }
;

/* if-else */
if_stmt:
    CHECK LPAREN expression RPAREN block if_tail
    {
        if (!isErrorType($3->type) && $3->type != TypeKind::Flag) {
            std::cout << "Type Error: condition must be flag\n";
        }
        $$ = new IfStmt($3->node, $5, $6);
        $3->node = nullptr;
        delete $3;
    }
;

if_tail:
    OTHERWISE block
    {
        debugLog("If-Else statement");
        $$ = $2;
    }
  | /* empty */
    {
        debugLog("If statement");
        $$ = new std::vector<StmtNode*>();
    }
;

block:
    START {
        symTable.enterScope();
    }
    statements_opt END {
        symTable.exitScope();
        $$ = $3;
    }
;

/* loop */
loop_stmt:
    ORBIT LPAREN expression RPAREN block
    {
        if (!isErrorType($3->type) && $3->type != TypeKind::Flag) {
            std::cout << "Type Error: condition must be flag\n";
        }
        debugLog("Loop statement");
        $$ = new LoopStmt($3->node, $5);
        $3->node = nullptr;
        delete $3;
    }
;

/* return */
return_stmt:
    RETURN expression SEMICOLON
    {
        TypeKind returnType = $2->type;
        if (!isErrorType(returnType)) {
            if (inferredReturnType == TypeKind::Unknown) {
                inferredReturnType = returnType;   // first return sets type
            }
            else if (inferredReturnType != returnType) {
                std::cout << "Type Error: inconsistent return types in function\n";
            }
        }

        debugLog("Return statement");
        $$ = new ReturnStmt($2->node);
        $2->node = nullptr;
        delete $2;
    }
    | RETURN SEMICOLON
    {
        debugLog("Return statement");
        $$ = new ReturnStmt(nullptr);
    }
;



/* types */
type:
        INT    { $$ = new TypeKind(TypeKind::Int); }
    | FLOAT  { $$ = new TypeKind(TypeKind::Float); }
    | STRING { $$ = new TypeKind(TypeKind::String); }
    | FLAG   { $$ = new TypeKind(TypeKind::Flag); }
;


/* ================= FUNCTIONS ================= */

functions:
      functions function
    | /* empty */
;

function:
    MODULE type IDENTIFIER
    {
        debugLog("Function declared: " + *$3 + " returns " + typeName(*$2));
        currentFunctionName = *$3;
        currentFunctionDeclaredType = *$2;
        inferredReturnType = TypeKind::Unknown;   // reset inferred return type per function

        symTable.enterScope();

        delete $2;
        delete $3;
    }
    LPAREN param_list_opt RPAREN
    {
        /* Register signature before parsing body so recursive calls resolve. */
        symTable.addFunction(currentFunctionName, currentFunctionDeclaredType, *$6);
    }
    START
    statements END
    {
        if (inferredReturnType == TypeKind::Unknown) {
            std::cout << "Type Error: function '" << currentFunctionName
                      << "' has no return statement\n";
        }
        else if (inferredReturnType != currentFunctionDeclaredType) {
            std::cout << "Type Error: function return type mismatch\n";
        }

        for (StmtNode* stmt : *$10) delete stmt;
        delete $10;
        delete $6;
        symTable.exitScope();
    }
;

param_list_opt:
      /* empty */
    {
        $$ = new std::vector<TypeKind>();
    }
    | param_list
    {
        $$ = $1;
    }
;

param_list:
      param
    {
    $$ = new std::vector<TypeKind>();
        $$->push_back(*$1);
        delete $1;
    }
    | param_list COMMA param
    {
        $$ = $1;
        $$->push_back(*$3);
        delete $3;
    }
;

param:
    type IDENTIFIER
    {
        symTable.addSymbol(*$2, *$1);
        $$ = $1;   // pass type upward
        delete $2;
    }
;


arg_list:
      expression
    {
        $$ = new CallArgPack();
        $$->argTypes->push_back($1->type);
        $$->argNodes->push_back($1->node);
        $1->node = nullptr;
        delete $1;
    }
    | arg_list COMMA expression
    {
        $$ = $1;
        $$->argTypes->push_back($3->type);
        $$->argNodes->push_back($3->node);
        $3->node = nullptr;
        delete $3;
    }
;

arg_list_opt:
      /* empty */
    {
        $$ = new CallArgPack();
    }
    | arg_list
    {
        $$ = $1;
    }
;

/* ================= EXPRESSIONS ================= */

expression:
    logical { $$ = $1; }
;

/* logical: &&, || */
logical:
      logical OR relational
    {
    debugLog("Evaluating expression: OR");
        TypeKind leftType = $1->type;
        TypeKind rightType = $3->type;
        ExprNode* leftNode = $1->node;
        ExprNode* rightNode = $3->node;

        $$ = new ExprResult();
        if (isErrorType(leftType) || isErrorType(rightType)) {
            $$->type = TypeKind::Error;
        }
        else if (leftType != TypeKind::Flag || rightType != TypeKind::Flag) {
            std::cout << "Type Error: logical OR needs flag\n";
            $$->type = TypeKind::Error;
        }
        else {
            $$->type = TypeKind::Flag;
        }
        $$->node = new BinaryExpr("OR", leftNode, rightNode);
        $1->node = nullptr;
        $3->node = nullptr;
        delete $1;
        delete $3;
    }
    | logical AND relational {
    debugLog("Evaluating expression: AND");
    TypeKind leftType = $1->type;
    TypeKind rightType = $3->type;
    ExprNode* leftNode = $1->node;
    ExprNode* rightNode = $3->node;

    $$ = new ExprResult();
    if (isErrorType(leftType) || isErrorType(rightType)) {
        $$->type = TypeKind::Error;
    }
    else if (leftType != TypeKind::Flag || rightType != TypeKind::Flag) {
        std::cout << "Type Error: logical AND needs flag\n";
        $$->type = TypeKind::Error;
    }
    else {
        $$->type = TypeKind::Flag;
    }
    $$->node = new BinaryExpr("AND", leftNode, rightNode);
    $1->node = nullptr;
    $3->node = nullptr;
    delete $1;
    delete $3;
}
    | relational { $$ = $1; }
;

/* relational: > < == != */
relational:
      relational EQUAL additive
    {
    TypeKind leftType = $1->type;
    TypeKind rightType = $3->type;
    ExprNode* leftNode = $1->node;
    ExprNode* rightNode = $3->node;

    $$ = new ExprResult();
    if (isErrorType(leftType) || isErrorType(rightType)) {
        $$->type = TypeKind::Error;
    }
    else if (leftType != rightType) {
        std::cout << "Type Error: incompatible types for comparison\n";
        $$->type = TypeKind::Error;
    }
    else {
        $$->type = TypeKind::Flag;
    }
    $$->node = new BinaryExpr("EQUAL", leftNode, rightNode);
    $1->node = nullptr;
    $3->node = nullptr;
    delete $1;
    delete $3;
}
    | relational NOT_EQUAL additive
    {
    TypeKind leftType = $1->type;
    TypeKind rightType = $3->type;
    ExprNode* leftNode = $1->node;
    ExprNode* rightNode = $3->node;

    $$ = new ExprResult();
    if (isErrorType(leftType) || isErrorType(rightType)) {
        $$->type = TypeKind::Error;
    }
    else if (leftType != rightType) {
        std::cout << "Type Error: incompatible types for comparison\n";
        $$->type = TypeKind::Error;
    }
    else {
        $$->type = TypeKind::Flag;
    }
    $$->node = new BinaryExpr("NOT_EQUAL", leftNode, rightNode);
    $1->node = nullptr;
    $3->node = nullptr;
    delete $1;
    delete $3;
}
    | relational LESS additive {
    TypeKind leftType = $1->type;
    TypeKind rightType = $3->type;
    ExprNode* leftNode = $1->node;
    ExprNode* rightNode = $3->node;

    $$ = new ExprResult();
    if (isErrorType(leftType) || isErrorType(rightType)) {
        $$->type = TypeKind::Error;
    }
    else if (leftType != rightType) {
        std::cout << "Type Error: incompatible types for comparison\n";
        $$->type = TypeKind::Error;
    }
    else {
        $$->type = TypeKind::Flag;
    }
    $$->node = new BinaryExpr("LESS", leftNode, rightNode);
    $1->node = nullptr;
    $3->node = nullptr;
    delete $1;
    delete $3;
}
    | relational GREATER additive
    {
    TypeKind leftType = $1->type;
    TypeKind rightType = $3->type;
    ExprNode* leftNode = $1->node;
    ExprNode* rightNode = $3->node;

    $$ = new ExprResult();
    if (isErrorType(leftType) || isErrorType(rightType)) {
        $$->type = TypeKind::Error;
    }
    else if (leftType != rightType) {
        std::cout << "Type Error: incompatible types for comparison\n";
        $$->type = TypeKind::Error;
    }
    else {
        $$->type = TypeKind::Flag;
    }
    $$->node = new BinaryExpr("GREATER", leftNode, rightNode);
    $1->node = nullptr;
    $3->node = nullptr;
    delete $1;
    delete $3;
}
    | relational LESS_EQUAL additive
    {
    TypeKind leftType = $1->type;
    TypeKind rightType = $3->type;
    ExprNode* leftNode = $1->node;
    ExprNode* rightNode = $3->node;

    $$ = new ExprResult();
    if (isErrorType(leftType) || isErrorType(rightType)) {
        $$->type = TypeKind::Error;
    }
    else if (leftType != rightType) {
        std::cout << "Type Error: incompatible types for comparison\n";
        $$->type = TypeKind::Error;
    }
    else {
        $$->type = TypeKind::Flag;
    }
    $$->node = new BinaryExpr("LESS_EQUAL", leftNode, rightNode);
    $1->node = nullptr;
    $3->node = nullptr;
    delete $1;
    delete $3;
}
    | relational GREATER_EQUAL additive
    {
    TypeKind leftType = $1->type;
    TypeKind rightType = $3->type;
    ExprNode* leftNode = $1->node;
    ExprNode* rightNode = $3->node;

    $$ = new ExprResult();
    if (isErrorType(leftType) || isErrorType(rightType)) {
        $$->type = TypeKind::Error;
    }
    else if (leftType != rightType) {
        std::cout << "Type Error: incompatible types for comparison\n";
        $$->type = TypeKind::Error;
    }
    else {
        $$->type = TypeKind::Flag;
    }
    $$->node = new BinaryExpr("GREATER_EQUAL", leftNode, rightNode);
    $1->node = nullptr;
    $3->node = nullptr;
    delete $1;
    delete $3;
}
    | additive { $$ = $1; }
;

/* addition and subtraction */
additive:
      additive PLUS multiplicative {
        debugLog("Evaluating expression: PLUS");
    TypeKind leftType = $1->type;
    TypeKind rightType = $3->type;
    ExprNode* leftNode = $1->node;
    ExprNode* rightNode = $3->node;

    $$ = new ExprResult();
    if (isErrorType(leftType) || isErrorType(rightType)) {
        $$->type = TypeKind::Error;
    }
    else {
        TypeKind resultType = numericResultType(leftType, rightType);
        if (isErrorType(resultType)) {
        std::cout << "Type Error: incompatible types for +\n";
        $$->type = TypeKind::Error;
        }
        else {
            $$->type = resultType;
        }
    }
    $$->node = new BinaryExpr("PLUS", leftNode, rightNode);
    $1->node = nullptr;
    $3->node = nullptr;
    delete $1;
    delete $3;
}
    | additive MINUS multiplicative
    {
    debugLog("Evaluating expression: MINUS");
    TypeKind leftType = $1->type;
    TypeKind rightType = $3->type;
    ExprNode* leftNode = $1->node;
    ExprNode* rightNode = $3->node;

    $$ = new ExprResult();
    if (isErrorType(leftType) || isErrorType(rightType)) {
        $$->type = TypeKind::Error;
    }
    else {
        TypeKind resultType = numericResultType(leftType, rightType);
        if (isErrorType(resultType)) {
        std::cout << "Type Error: incompatible types for -\n";
        $$->type = TypeKind::Error;
        }
        else {
            $$->type = resultType;
        }
    }
    $$->node = new BinaryExpr("MINUS", leftNode, rightNode);
    $1->node = nullptr;
    $3->node = nullptr;
    delete $1;
    delete $3;
}
    | multiplicative { $$ = $1; }
;

/* MULTIPLICATION and DIVISION */
multiplicative:
      multiplicative MULTIPLY unary
      {
        debugLog("Evaluating expression: MULTIPLY");
    TypeKind leftType = $1->type;
    TypeKind rightType = $3->type;
    ExprNode* leftNode = $1->node;
    ExprNode* rightNode = $3->node;

    $$ = new ExprResult();
    if (isErrorType(leftType) || isErrorType(rightType)) {
        $$->type = TypeKind::Error;
    }
    else {
        TypeKind resultType = numericResultType(leftType, rightType);
        if (isErrorType(resultType)) {
        std::cout << "Type Error: incompatible types for *\n";
        $$->type = TypeKind::Error;
        }
        else {
            $$->type = resultType;
        }
    }
    $$->node = new BinaryExpr("MULTIPLY", leftNode, rightNode);
    $1->node = nullptr;
    $3->node = nullptr;
    delete $1;
    delete $3;
}
    | multiplicative DIVIDE unary
      {
        debugLog("Evaluating expression: DIVIDE");
    TypeKind leftType = $1->type;
    TypeKind rightType = $3->type;
    ExprNode* leftNode = $1->node;
    ExprNode* rightNode = $3->node;

    $$ = new ExprResult();
    if (isErrorType(leftType) || isErrorType(rightType)) {
        $$->type = TypeKind::Error;
    }
    else {
        TypeKind resultType = numericResultType(leftType, rightType);
        if (isErrorType(resultType)) {
        std::cout << "Type Error: incompatible types for /\n";
        $$->type = TypeKind::Error;
        }
        else {
            $$->type = resultType;
        }
    }
    $$->node = new BinaryExpr("DIVIDE", leftNode, rightNode);
    $1->node = nullptr;
    $3->node = nullptr;
    delete $1;
    delete $3;
}
    | unary { $$ = $1; }
;

/* unary operators */
unary:
      NOT unary
    {
        TypeKind innerType = $2->type;
        ExprNode* innerNode = $2->node;
        $$ = new ExprResult();
        if (isErrorType(innerType)) {
            $$->type = TypeKind::Error;
    }
    else if (innerType != TypeKind::Flag) {
        std::cout << "Type Error: logical NOT needs flag\n";
        $$->type = TypeKind::Error;
    }
    else {
        $$->type = TypeKind::Flag;
    }
    $$->node = new UnaryExpr("NOT", innerNode);
    $2->node = nullptr;
    delete $2;
    }
    | MINUS unary        /* supports -x */
    {
        TypeKind innerType = $2->type;
        ExprNode* innerNode = $2->node;
        $$ = new ExprResult();
        if (isErrorType(innerType)) {
            $$->type = TypeKind::Error;
    }
    else if (!isNumericType(innerType)) {
        std::cout << "Type Error: unary minus needs int or float\n";
        $$->type = TypeKind::Error;
    }
    else {
        $$->type = innerType;
    }
    $$->node = new UnaryExpr("NEGATE", innerNode);
    $2->node = nullptr;
    delete $2;
    }
    | primary { $$ = $1; }
;

/* basic values */
primary:
      LPAREN expression RPAREN
    {
        $$ = $2;
    }
    | IDENTIFIER LPAREN arg_list_opt RPAREN
    {
        $$ = new ExprResult();
        debugLog("Function call: " + *$1);
        if (*$1 == "ignite") {
            if ($3->argTypes->size() != 1) {
                std::cout << "Error: function 'ignite' called with wrong number of arguments\n";
                $$->type = TypeKind::Error;
            } else {
                TypeKind argType = $3->argTypes->at(0);
                if (!isNumericType(argType)) {
                    std::cout << "Error: function 'ignite' expects int or float argument\n";
                    $$->type = TypeKind::Error;
                } else {
                    $$->type = argType;
                }
            }
        } else if (*$1 == "percent") {
            /*
             * Built-in semantic checks for percent(value, total)
             * percent(a, b) = (a / b) * 100
             */

            /* Step 1: percent must have exactly 2 arguments. */
            if ($3->argTypes->size() != 2) {
                std::cout << "Error: function 'percent' called with wrong number of arguments\n";
                $$->type = TypeKind::Error;
            } else {
                TypeKind valueType = $3->argTypes->at(0);
                TypeKind totalType = $3->argTypes->at(1);

                /* Step 2: both arguments must be numeric (int or float). */
                if (!isNumericType(valueType) || !isNumericType(totalType)) {
                    std::cout << "Error: function 'percent' expects int or float arguments\n";
                    $$->type = TypeKind::Error;
                } else {
                    /*
                     * Step 3: detect obvious division-by-zero at compile time.
                     * We can do this when the second argument is a numeric literal
                     * like 0 or 0.0.
                     */
                    ExprNode* totalNode = nullptr;
                    if ($3->argNodes && $3->argNodes->size() >= 2) {
                        totalNode = $3->argNodes->at(1);
                    }

                    if (totalNode && totalNode->isZeroNumericLiteral()) {
                        std::cout << "Error: function 'percent' division by zero\n";
                        $$->type = TypeKind::Error;
                    } else {
                        /*
                         * Step 4: return numeric result type.
                         * int/int -> int, any float involved -> float.
                         */
                        $$->type = numericResultType(valueType, totalType);
                    }
                }
            }
        } else if (!symTable.hasFunction(*$1)) {
            std::cout << "Error: function '" << *$1 << "' is not declared\n";
            $$->type = TypeKind::Error;
        } else if (!symTable.hasFunctionArity(*$1, $3->argTypes->size())) {
            std::cout << "Error: function '" << *$1
                      << "' called with wrong number of arguments\n";
            $$->type = TypeKind::Error;
        } else {
            auto func = symTable.resolveFunction(*$1, *$3->argTypes);

            if (func.returnType == TypeKind::Error) {
                std::cout << "Error: function '" << *$1
                          << "' called with wrong argument types\n";
                $$->type = TypeKind::Error;
            } else {
                $$->type = func.returnType;
            }
        }

        $$->node = new CallExpr(*$1, $3->argNodes);
        $3->argNodes = nullptr;

        delete $1;
        delete $3;
    }
    | IDENTIFIER
    {
        $$ = new ExprResult();
        if(!symTable.lookupSymbol(*$1)) {
            std::cout << "Error: Variable '" << *$1 << "' not declared\n";
            $$->type = TypeKind::Error;
        }
        else {
            $$->type = symTable.getType(*$1);
        }
        $$->node = new IdentifierExpr(*$1);
        delete $1;
    }
    | INTEGER_LITERAL { $$ = new ExprResult{TypeKind::Int, new NumberNode(TypeKind::Int, *$1)}; delete $1; }
    | FLOAT_LITERAL   { $$ = new ExprResult{TypeKind::Float, new NumberNode(TypeKind::Float, *$1)}; delete $1; }
    | STRING_LITERAL  { $$ = new ExprResult{TypeKind::String, new LiteralExpr(*$1, true)}; delete $1; }
    | TRUE            { $$ = new ExprResult{TypeKind::Flag, new LiteralExpr("true")}; }
    | FALSE           { $$ = new ExprResult{TypeKind::Flag, new LiteralExpr("false")}; }
;





%%
/* ================= ERROR HANDLING ================= */

void yyerror(const char *s) {
    std::cout << "Syntax Error near line " << yylineno << ": " << s << "\n";
}

/* ================= MAIN ================= */
int main(int argc, char** argv) {
    const char* inputFile = nullptr;

    // If compiled with -DDEBUG, enable debug mode automatically.
#ifdef DEBUG
    DEBUG_MODE = true;
#endif

    for (int i = 1; i < argc; ++i) {
        std::string arg = argv[i];
        // Optional runtime override: disable debug even if built with -DDEBUG.
        if (arg == "nodebug") {
            DEBUG_MODE = false;
        } else if (arg == "ast") {
            AST_MODE = true;
        } else {
            inputFile = argv[i];
        }
    }

    if (inputFile != nullptr) {
        yyin = fopen(inputFile, "r");
        if (!yyin) {
            std::cout << "Error: cannot open input file '" << inputFile << "'\n";
            return 1;
        }
    }

    if (DEBUG_MODE) {
        std::cout << "Starting Parser (DEBUG MODE)...\n\n";
    } else if (AST_MODE) {
        std::cout << "Starting Parser (AST MODE)...\n\n";
    }

    symTable.enterScope();
    int parseStatus = yyparse();

    if (yyin && inputFile != nullptr) {
        fclose(yyin);
        yyin = nullptr;
    }

    return parseStatus;
}
