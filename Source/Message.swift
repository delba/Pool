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
    case Request(Key)
    
    /// A response message with the given key and value.
    case Response(Key, Value?)
    
    /// An insert message for the given keys.
    case Insert([Key])
    
    /// A delete message for the given keys.
    case Delete([Key])
    
    /// The message type.
    private var type: String {
        switch self {
        case Request:  return "request"
        case Response: return "response"
        case Insert:   return "insert"
        case Delete:   return "delete"
        }
    }
    
    /// The message associated values.
    private var args: [AnyObject] {
        switch self {
        case let Request(key):   return [key]
        case let Response(k, v): return [k, v].flatMap{$0}
        case let Insert(keys):   return [keys]
        case let Delete(keys):   return [keys]
        }
    }
    
    /**
     Creates and return a new message or nil if not convertible.
     
     - parameter data: The `NSData` representation of the message.
    
     - returns: A new message or nil if not convertible.
     */
    internal init?(data: NSData) {
        guard let
            dictionary = KeyArchiver.unarchive(data) as? [String: AnyObject],
            type = dictionary["type"] as? String,
            args = dictionary["args"] as? [AnyObject]
        else {
            return nil
        }
        
        // ["type": "request", "values": ["key"]]
        if type == "request", let key = args[safe: 0] as? Key {
            self = Request(key)
        }
        
        // ["type": "response", "values": ["key", "value"]]
        else if type == "response", let key = args[safe: 0] as? Key {
            self = Response(key, args[safe: 1])
        }
        
        // ["type": "insert", "values": [["key1", "key2"]]]
        else if type == "insert", let keys = args[safe: 0] as? [Key] {
            self = Insert(keys)
        }
        
        // ["type": "delete", "values": [["key1", "key2"]]]
        else if type == "delete", let keys = args[safe: 0] as? [Key] {
            self = Delete(keys)
        }
        
        else {
            return nil
        }
    }
    
    /**
     Returns an `NSData` object containing the encoded form of the message.
     
     - returns: The `NSData` representation of the message.
     */
    internal func toData() -> NSData {
        return KeyArchiver.archive([
            "type": type,
            "args": args
        ])
    }
}