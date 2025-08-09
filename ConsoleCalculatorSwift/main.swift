//
//  main.swift
//  ConsoleCalculator
//
//  Created by vincent on 2025/8/5.
//

import Foundation

enum ExpressionError: Error, CustomStringConvertible {
    case invalidToken(String)
    case unmatchedParenthesis
    case divisionByZero
    case insufficientOperands
    case invalidExpression
    case emptyExpression
    
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
        }
    }
}

enum Token: CustomStringConvertible {
    case number(Double)
    case `op`(String)  // Using 'op' instead of 'operator' to avoid keyword issues
    
    var description: String {
        switch self {
        case .number(let value): return "\(value)"
        case .op(let symbol): return symbol
        }
    }
}

func tokenize(_ input: String) -> [Token] {
    let operators = ["+", "-", "*", "/", "^"]
    var tokens = [Token]()
    var currentNumber = ""
    
    for char in input {
        let charString = String(char)
        
        if char.isNumber || char == "." {
            currentNumber += charString
        } else if operators.contains(charString) {
            if !currentNumber.isEmpty {
                if let num = Double(currentNumber) {
                    tokens.append(.number(num))
                }
                currentNumber = ""
            }
            tokens.append(.op(charString))  // Using .op here
        }
    }
    
    // Handle the last number
    if !currentNumber.isEmpty {
        if let num = Double(currentNumber) {
            tokens.append(.number(num))
        }
    }
    
    return tokens
}

func evaluateExpression(tokens: [Token]) throws -> Double {
    // Operator precedence dictionary
    let precedence: [String: Int] = ["^": 4, "*": 3, "/": 3, "+": 2, "-": 2]
    
    guard !tokens.isEmpty else {
        throw ExpressionError.emptyExpression
    }
    
    var output = [Token]()
    var operatorStack = [Token]()
    var i = 0
    
    while i < tokens.count {
        let token = tokens[i]
        
        switch token {
        case .number:
            output.append(token)
        case .op("("):
            // Handle parentheses by finding matching closing parenthesis
            operatorStack.append(token)
            var parenTokens = [Token]()
            var parenLevel = 1
            i += 1
            
            // Find the matching closing parenthesis
            var foundMatching = false
            while i < tokens.count {
                switch tokens[i] {
                case .op("("):
                    parenLevel += 1
                    parenTokens.append(tokens[i])
                case .op(")"):
                    parenLevel -= 1
                    if parenLevel == 0 {
                        foundMatching = true
                        i += 1
                        break
                    }
                    parenTokens.append(tokens[i])
                default:
                    parenTokens.append(tokens[i])
                }
                
                if foundMatching {
                    break
                }
                i += 1
            }
            
            guard foundMatching else {
                throw ExpressionError.unmatchedParenthesis
            }
            
            // Recursively evaluate the expression inside parentheses
            do {
                let parenResult = try evaluateExpression(tokens: parenTokens)
                output.append(.number(parenResult))
            } catch {
                throw error
            }
            continue
            
        case .op(")"):
            throw ExpressionError.unmatchedParenthesis
            
        case .op(let op):
            // Handle operator precedence
            while let top = operatorStack.last,
                  case .op(let topOp) = top,
                  topOp != "(",
                  precedence[op]! <= precedence[topOp]! {
                output.append(operatorStack.removeLast())
            }
            operatorStack.append(token)
        }
        i += 1
    }
    
    // Check for unmatched opening parentheses in the stack
    if operatorStack.contains(where: {
        if case .op("(") = $0 { return true }
        return false
    }) {
        throw ExpressionError.unmatchedParenthesis
    }
    
    // Append remaining operators
    output.append(contentsOf: operatorStack.reversed())
    
    // Evaluate the postfix expression
    var stack = [Double]()
    for token in output {
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
            case "+": result = a + b
            case "-": result = a - b
            case "*": result = a * b
            case "/":
                if b == 0 {
                    throw ExpressionError.divisionByZero
                }
                result = a / b
            case "^": result = pow(a, b)
            default:
                throw ExpressionError.invalidToken(op)
            }
            stack.append(result)
        }
    }
    
    guard stack.count == 1 else {
        throw ExpressionError.invalidExpression
    }
    
    return stack.first!
}

while true {
    
    print("----------------------------")
    
    print("Expression>> ", terminator: "")
    
    if let expression = readLine() {
        
        // Trim whitespace and check for exit command
        let trimmed = expression.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.lowercased() == "quit" {
            
            break
            
        }
        
        // Tokenize the expression
        let tokens = tokenize(trimmed)
        
        // Pass the tokens directly (no array wrapping needed)
        do {
            
            let result = try evaluateExpression(tokens: tokens)
            print("Result>> \(result)")
            
        } catch let error as ExpressionError {
            
            print("Error: \(error.description)")
            
        } catch {
            
            print("Unknown error: \(error)")
            
        }
        
    }
    
}

