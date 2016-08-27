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
    public var values: [Any] {
        switch self {
        case let .request(key):   return [key]
        case let .response(k, v): return [k, v].flatMap{$0}
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
        guard let
            dictionary = KeyArchiver.unarchive(data) as? [String: Any],
            let type = dictionary["type"] as? String,
            let values = dictionary["values"] as? [Any]
        else {
            return nil
        }
        
        // ["type": "request", "values": ["key"]]
        if type == "request", let key = values[safe: 0] as? Key {
            self = .request(key)
        }
        
        // ["type": "response", "values": ["key", "value"]]
        else if type == "response", let key = values[safe: 0] as? Key {
            self = .response(key, values[safe: 1])
        }
        
        // ["type": "insert", "values": [["key1", "key2"]]]
        else if type == "insert", let keys = values[safe: 0] as? [Key] {
            self = .insert(keys)
        }
        
        // ["type": "delete", "values": [["key1", "key2"]]]
        else if type == "delete", let keys = values[safe: 0] as? [Key] {
            self = .delete(keys)
        }
        
        else {
            return nil
        }
    }
    
    /**
     Returns an `NSData` object containing the encoded form of the message.
     
     - returns: The `NSData` representation of the message.
     */
    internal func toData() -> Data {
        return KeyArchiver.archive([
            "type": type,
            "values": values
        ])
    }
}
