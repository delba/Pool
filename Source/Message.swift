//
// Message.swift
//
// Copyright (c) 2016 Damien (http://delba.io)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

// MARK: Message

internal enum Message {
    /// A request message for the given key.
    case request(Key)
    
    /// A response message with the given key and value.
    case response(Key, Value?)
    
    /// An insert message for the given keys.
    case insert([Key])
    
    /// A delete message for the given keys.
    case delete([Key])
    
    /// The message type.
    fileprivate var type: String {
        switch self {
        case .request:  return "request"
        case .response: return "response"
        case .insert:   return "insert"
        case .delete:   return "delete"
        }
    }
    
    /// The message associated values.
    fileprivate var args: [Any] {
        switch self {
        case let .request(key):   return [key]
        case let .response(k, v): return [k, v].flatMap({ $0 })
        case let .insert(keys):   return [keys]
        case let .delete(keys):   return [keys]
        }
    }
    
    /**
     Creates and return a new message or nil if not convertible.
     
     - parameter data: The `NSData` representation of the message.
    
     - returns: A new message or nil if not convertible.
     */
    internal init?(data: Data) {
        guard let dictionary = KeyArchiver.unarchive(data) as? [String: Any],
            let type = dictionary["type"] as? String,
            let args = dictionary["args"] as? [Any]
            else { return nil }
        
        switch type {
        case "request":  self.init(request:  args)
        case "response": self.init(response: args)
        case "insert":   self.init(insert:   args)
        case "delete":   self.init(delete:   args)
        default: return nil
        }
    }
    
    /**
     Returns an `NSData` object containing the encoded form of the message.
     
     - returns: The `NSData` representation of the message.
     */
    internal func toData() -> Data {
        return KeyArchiver.archive([
            "type": type,
            "args": args,
        ])
    }
}

// MARK: Request

fileprivate extension Message {
    init?(request args: [Any]) {
        guard let key = args[safe: 0] as? Key else { return nil }
        
        self = .request(key)
    }
}

// MARK: Response

fileprivate extension Message {
    init?(response args: [Any]) {
        guard let key = args[safe: 0] as? Key else { return nil }
        
        let value = args[safe: 1]
        
        self = .response(key, value)
    }
}

// MARK: Insert

fileprivate extension Message {
    init?(insert args: [Any]) {
        guard let keys = args[safe: 0] as? [Key] else { return nil }
        
        self = .insert(keys)
    }
}

// MARK: Delete

fileprivate extension Message {
    init?(delete args: [Any]) {
        guard let keys = args[safe: 0] as? [Key] else { return nil }
        
        self = .delete(keys)
    }
}
