//
// MessageTests.swift
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

import XCTest
@testable import Pool

class MessageTests: XCTestCase {
    func testRequest() {
        let message: Message = .request("a")
        let data = message.toData()
        
        guard case .request(AnyHashable("a")) = Message(data: data)! else {
            XCTFail()
            return
        }
    }
    
    func testResponse() {
        let message: Message = .response("a", 42)
        let data = message.toData()
        
        guard case .response(AnyHashable("a"), let value) = Message(data: data)! else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(42, value as? Int)
    }
    
    func testInsert() {
        let message: Message = .insert(["a", "b", "c"])
        let data = message.toData()
        
        guard case .insert(let keys) = Message(data: data)! else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(["a", "b", "c"], keys)
    }
    
    func testDelete() {
        let message: Message = .delete(["a", "b", "c"])
        let data = message.toData()
        
        guard case .delete(let keys) = Message(data: data)! else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(["a", "b", "c"], keys)
    }
}
