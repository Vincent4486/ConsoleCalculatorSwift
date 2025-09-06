//
//  main.swift
//  ScientificCalculator
//
//  Enhanced version with trigonometric, logarithmic, and square root functions
//

import Foundation

enum ExpressionError: Error, CustomStringConvertible {
    case invalidToken(String)
    case unmatchedParenthesis
    case divisionByZero
    case insufficientOperands
    case invalidExpression
    case emptyExpression
    case missingOperand(String)
    case invalidFunction(String)
    
    var description: String {
        switch self {
        case .invalidToken(let token):
            return "Invalid token: '\(token)'"
        case .unmatchedParenthesis:
            return "Unmatched parenthesis"
        case .divisionByZero:
            return "Division by zero"
        case .insufficientOperands:
            return "Insufficient operands for operation"
        case .invalidExpression:
            return "Invalid expression structure"
        case .emptyExpression:
            return "Empty expression"
        case .missingOperand(let op):
            return "Missing operand for operator '\(op)'"
        case .invalidFunction(let fn):
            return "Invalid function: '\(fn)'"
        }
    }
}

enum Token: CustomStringConvertible, Equatable {
    case number(Double)
    case op(String)
    case paren(String)
    case function(String)
    
    var description: String {
        switch self {
        case .number(let value): return "\(value)"
        case .op(let symbol): return symbol
        case .paren(let symbol): return symbol
        case .function(let name): return name
        }
    }
}

struct OperatorInfo {
    let precedence: Int
    let isRightAssociative: Bool
    let operandCount: Int
}

class ScientificCalculator {
    private let operators: [String: OperatorInfo] = [
        "^": OperatorInfo(precedence: 4, isRightAssociative: true, operandCount: 2),
        "*": OperatorInfo(precedence: 3, isRightAssociative: false, operandCount: 2),
        "/": OperatorInfo(precedence: 3, isRightAssociative: false, operandCount: 2),
        "+": OperatorInfo(precedence: 2, isRightAssociative: false, operandCount: 2),
        "-": OperatorInfo(precedence: 2, isRightAssociative: false, operandCount: 2)
    ]
    
    private let functions: [String: Int] = [
        "sin": 1,
        "cos": 1,
        "tan": 1,
        "sqrt": 1,
        "log": 1
    ]
    
    func run() {
        print("Scientific Calculator")
        print("Supported functions: sin, cos, tan, sqrt, log")
        print("Type 'quit' or 'exit' to end the program")
        print("----------------------------")
        
        while true {
            print("Expression>> ", terminator: "")
            
            guard let input = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines) else {
                continue
            }
            
            if input.lowercased() == "quit" || input.lowercased() == "exit" {
                break
            }
            
            if input.isEmpty {
                continue
            }
            
            do {
                let tokens = try tokenize(input)
                let result = try evaluate(tokens: tokens)
                print("Result>> \(formatResult(result))")
            } catch let error as ExpressionError {
                print("Error: \(error.description)")
            } catch {
                print("Unknown error: \(error)")
            }
            
            print("----------------------------")
        }
    }
    
    private func tokenize(_ input: String) throws -> [Token] {
        var tokens = [Token]()
        var currentNumber = ""
        var currentFunction = ""
        var i = input.startIndex
        
        while i < input.endIndex {
            let char = input[i]
            
            if char.isWhitespace {
                i = input.index(after: i)
                continue
            }
            
            if char.isLetter {
                currentFunction.append(char)
                i = input.index(after: i)
                
                // Check if we've completed a function name
                if i < input.endIndex && !input[i].isLetter {
                    if functions.keys.contains(currentFunction) {
                        tokens.append(.function(currentFunction))
                        currentFunction = ""
                    } else {
                        throw ExpressionError.invalidFunction(currentFunction)
                    }
                }
                continue
            }
            
            if !currentFunction.isEmpty {
                if functions.keys.contains(currentFunction) {
                    tokens.append(.function(currentFunction))
                    currentFunction = ""
                } else {
                    throw ExpressionError.invalidFunction(currentFunction)
                }
            }
            
            if char.isNumber || char == "." {
                currentNumber.append(char)
            } else if char == "-" && (i == input.startIndex ||
                     String(input[input.index(before: i)]) == "(" ||
                     tokens.last?.isOperator == true) {
                // Handle negative numbers (unary minus)
                currentNumber.append(char)
            } else if operators.keys.contains(String(char)) || char == "(" || char == ")" {
                if !currentNumber.isEmpty {
                    guard let num = Double(currentNumber) else {
                        throw ExpressionError.invalidToken(currentNumber)
                    }
                    tokens.append(.number(num))
                    currentNumber = ""
                }
                
                if char == "(" || char == ")" {
                    tokens.append(.paren(String(char)))
                } else {
                    tokens.append(.op(String(char)))
                }
            } else {
                throw ExpressionError.invalidToken(String(char))
            }
            
            i = input.index(after: i)
        }
        
        // Add the last number if exists
        if !currentNumber.isEmpty {
            guard let num = Double(currentNumber) else {
                throw ExpressionError.invalidToken(currentNumber)
            }
            tokens.append(.number(num))
        }
        
        // Check if there's any remaining function name
        if !currentFunction.isEmpty {
            if functions.keys.contains(currentFunction) {
                tokens.append(.function(currentFunction))
            } else {
                throw ExpressionError.invalidFunction(currentFunction)
            }
        }
        
        return tokens
    }
    
    private func evaluate(tokens: [Token]) throws -> Double {
        guard !tokens.isEmpty else {
            throw ExpressionError.emptyExpression
        }
        
        let outputQueue = try shuntingYard(tokens: tokens)
        return try evaluateRPN(tokens: outputQueue)
    }
    
    private func shuntingYard(tokens: [Token]) throws -> [Token] {
        var outputQueue = [Token]()
        var operatorStack = [Token]()
        
        for token in tokens {
            switch token {
            case .number:
                outputQueue.append(token)
            case .function:
                operatorStack.append(token)
            case .paren("("):
                operatorStack.append(token)
            case .paren(")"):
                while let top = operatorStack.last, top != .paren("(") {
                    outputQueue.append(operatorStack.removeLast())
                }
                
                guard operatorStack.last == .paren("(") else {
                    throw ExpressionError.unmatchedParenthesis
                }
                operatorStack.removeLast() // Remove the "("
                
                // Check if there's a function before the parenthesis
                if let top = operatorStack.last, case .function = top {
                    outputQueue.append(operatorStack.removeLast())
                }
            case .op(let op):
                let currentOpInfo = operators[op]!
                
                while let top = operatorStack.last {
                    if case .op(let topOp) = top {
                        let topOpInfo = operators[topOp]!
                        
                        if (currentOpInfo.isRightAssociative && currentOpInfo.precedence < topOpInfo.precedence) ||
                           (!currentOpInfo.isRightAssociative && currentOpInfo.precedence <= topOpInfo.precedence) {
                            outputQueue.append(operatorStack.removeLast())
                        } else {
                            break
                        }
                    } else if case .function = top {
                        outputQueue.append(operatorStack.removeLast())
                    } else if top == .paren("(") {
                        break
                    } else {
                        break
                    }
                }
                
                operatorStack.append(token)
            default:
                break
            }
        }
        
        // Pop remaining operators
        while let op = operatorStack.popLast() {
            if op == .paren("(") {
                throw ExpressionError.unmatchedParenthesis
            }
            outputQueue.append(op)
        }
        
        return outputQueue
    }
    
    private func evaluateRPN(tokens: [Token]) throws -> Double {
        var stack = [Double]()
        
        for token in tokens {
            switch token {
            case .number(let value):
                stack.append(value)
            case .op(let op):
                guard stack.count >= 2 else {
                    throw ExpressionError.insufficientOperands
                }
                
                let b = stack.removeLast()
                let a = stack.removeLast()
                let result: Double
                
                switch op {
                case "+":
                    result = a + b
                case "-":
                    result = a - b
                case "*":
                    result = a * b
                case "/":
                    guard b != 0 else {
                        throw ExpressionError.divisionByZero
                    }
                    result = a / b
                case "^":
                    result = pow(a, b)
                default:
                    throw ExpressionError.invalidToken(op)
                }
                
                stack.append(result)
            case .function(let fn):
                guard !stack.isEmpty else {
                    throw ExpressionError.insufficientOperands
                }
                
                let value = stack.removeLast()
                let result: Double
                
                switch fn {
                case "sin":
                    result = sin(value)
                case "cos":
                    result = cos(value)
                case "tan":
                    result = tan(value)
                case "sqrt":
                    guard value >= 0 else {
                        throw ExpressionError.invalidToken("sqrt of negative number")
                    }
                    result = sqrt(value)
                case "log":
                    guard value > 0 else {
                        throw ExpressionError.invalidToken("log of non-positive number")
                    }
                    result = log10(value)
                default:
                    throw ExpressionError.invalidFunction(fn)
                }
                
                stack.append(result)
            default:
                throw ExpressionError.invalidExpression
            }
        }
        
        guard stack.count == 1 else {
            throw ExpressionError.invalidExpression
        }
        
        // Round to 10 decimal places to handle floating-point precision issues
        let roundedResult = (stack[0] * 1e10).rounded() / 1e10
        return roundedResult
    }
    
    private func formatResult(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 10
        formatter.minimumFractionDigits = 0
        formatter.usesGroupingSeparator = false
        
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}

extension Token {
    var isOperator: Bool {
        if case .op = self {
            return true
        }
        return false
    }
}

// Run the calculator
let calculator = ScientificCalculator()
calculator.run()
