// This file exists to fix the AIError redeclaration issue
// Removing it from AIService.swift and keeping only the ErrorTypes.swift version

import Foundation

public enum AIError_Fix: Error, LocalizedError {
    case serviceUnavailable
}
