//  SwiftyJSON.swift
//
//  Copyright (c) 2014年 Ruoyu Fu, Denis Lebedev.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import Foundation


public enum JSONValue {

    
    case jNumber(NSNumber)
    case jString(String)
    case jBool(Bool)
    case jNull
    case jArray(Array<JSONValue>)
    case jObject(Dictionary<String,JSONValue>)
    case jInvalid(NSError)

    var string: String? {
        switch self {
        case .jString(let value):
            return value
        default:
            return nil
        }
    }
  
    var url: URL? {
        switch self {
        case .jString(let value):
            return URL(string: value)
        default:
            return nil
        }
    }
    var number: NSNumber? {
        switch self {
        case .jNumber(let value):
            return value
        default:
            return nil
        }
    }
    
    var double: Double? {
        switch self {
        case .jNumber(let value):
            return value.doubleValue
        case .jString(let value):
            return (value as NSString).doubleValue
        default:
            return nil
        }
    }
    
    var integer: Int? {
        switch self {
        case .jBool(let value):
            return value ? 1 : 0
        case .jNumber(let value):
            return value.intValue
        case .jString(let value):
            return (value as NSString).integerValue
        default:
            return nil
        }
    }
    
    var bool: Bool? {
        switch self {
        case .jBool(let value):
            return value
        case .jNumber(let value):
            return value.boolValue
        case .jString(let value):
            return (value as NSString).boolValue
        default:
            return nil
        }
    }
    
    var array: Array<JSONValue>? {
        switch self {
        case .jArray(let value):
            return value
        default:
            return nil
        }
    }
    
    var object: Dictionary<String, JSONValue>? {
        switch self {
        case .jObject(let value):
            return value
        default:
            return nil
        }
    }
    
    var first: JSONValue? {
        switch self {
        case .jArray(let jsonArray) where jsonArray.count > 0:
            return jsonArray[0]
        case .jObject(let jsonDictionary) where jsonDictionary.count > 0 :
            let (_, value) = jsonDictionary[jsonDictionary.startIndex]
            return value
        default:
            return nil
        }
    }
    
    var last: JSONValue? {
        switch self {
        case .jArray(let jsonArray) where jsonArray.count > 0:
            return jsonArray[jsonArray.count-1]
        case .jObject(let jsonDictionary) where jsonDictionary.count > 0 :
            let (_, value) = jsonDictionary[jsonDictionary.endIndex]
            return value
        default:
            return nil
        }
    }
    
    init (_ data: Data!){
        if let _ = data{
            do {
                let jsonObject : Any = try JSONSerialization.jsonObject(with: data, options: [])
                self = JSONValue(jsonObject as AnyObject)
            } catch {
                self = JSONValue.jInvalid(NSError(domain: "JSONErrorDomain", code: 1001, userInfo: [NSLocalizedDescriptionKey:"JSON Parser Error: Invalid Raw JSON Data"]))
            }
        }else{
            self = JSONValue.jInvalid(NSError(domain: "JSONErrorDomain", code: 1000, userInfo: [NSLocalizedDescriptionKey:"JSON Init Error: Invalid Value Passed In init()"]))
        }

    }
    
    init (_ rawObject: AnyObject) {
        switch rawObject {
        case let value as NSNumber:
            if String(cString: value.objCType) == "c" {
                self = .jBool(value.boolValue)
                return
            }
            self = .jNumber(value)
        case let value as NSString:
            self = JSONValue.jString(value as String)
        case _ as NSNull:
            self = .jNull
        case let value as NSArray:
            var jsonValues = [JSONValue]()
            for possibleJsonValue in value {
                let jsonValue = JSONValue(possibleJsonValue as AnyObject)
                if  jsonValue.boolValue {
                    jsonValues.append(jsonValue)
                }
            }
            self = .jArray(jsonValues)
        case let value as NSDictionary:
            var jsonObject = Dictionary<String, JSONValue>()
            for (possibleJsonKey, possibleJsonValue): (Any, Any) in value {
                if let key = possibleJsonKey as? NSString {
                    let jsonValue = JSONValue(possibleJsonValue as AnyObject)
                    if jsonValue.boolValue {
                        jsonObject[key as String] = jsonValue
                    }
                }
            }
            self = .jObject(jsonObject)
        default:
            self = .jInvalid(NSError(domain: "JSONErrorDomain", code: 1000, userInfo: [NSLocalizedDescriptionKey:"JSON Init Error: Invalid Value Passed In init()"]))
        }
    }

    subscript(index: Int) -> JSONValue {
        get {
            switch self {
            case .jArray(let jsonArray) where jsonArray.count > index:
                return jsonArray[index]
            case .jInvalid(let error):
                if let breadcrumb = error.userInfo["JSONErrorBreadCrumbKey"] as? NSString{
                    let newBreadCrumb = (breadcrumb as String) + "/\(index)"
                    let newUserInfo = [NSLocalizedDescriptionKey: "JSON Keypath Error: Incorrect Keypath \"\(newBreadCrumb)\"",
                                       "JSONErrorBreadCrumbKey": newBreadCrumb]
                    return JSONValue.jInvalid(NSError(domain: "JSONErrorDomain", code: 1002, userInfo: newUserInfo))
                }
                
                return self
            default:
                let breadcrumb = "\(index)"
                let newUserInfo = [NSLocalizedDescriptionKey: "JSON Keypath Error: Incorrect Keypath \"\(breadcrumb)\"",
                                    "JSONErrorBreadCrumbKey": breadcrumb]
                return JSONValue.jInvalid(NSError(domain: "JSONErrorDomain", code: 1002, userInfo: newUserInfo))
            }
        }
    }
    
    subscript(key: String) -> JSONValue {
        get {
            switch self {
            case .jObject(let jsonDictionary):
                if let value = jsonDictionary[key] {
                    return value
                }else {
                    let breadcrumb = "\(key)"
                    let newUserInfo = [NSLocalizedDescriptionKey: "JSON Keypath Error: Incorrect Keypath \"\(breadcrumb)\"",
                                        "JSONErrorBreadCrumbKey": breadcrumb]
                    return JSONValue.jInvalid(NSError(domain: "JSONErrorDomain", code: 1002, userInfo: newUserInfo))
                }
            case .jInvalid(let error):
                if let breadcrumb = error.userInfo["JSONErrorBreadCrumbKey"] as? NSString{
                    let newBreadCrumb = (breadcrumb as String) + "/\(key)"
                    let newUserInfo = [NSLocalizedDescriptionKey: "JSON Keypath Error: Incorrect Keypath \"\(newBreadCrumb)\"",
                        "JSONErrorBreadCrumbKey": newBreadCrumb]
                    return JSONValue.jInvalid(NSError(domain: "JSONErrorDomain", code: 1002, userInfo: newUserInfo))
                }
                return self
            default:
                let breadcrumb = "/\(key)"
                let newUserInfo = [NSLocalizedDescriptionKey: "JSON Keypath Error: Incorrect Keypath \"\(breadcrumb)\"",
                    "JSONErrorBreadCrumbKey": breadcrumb]
                return JSONValue.jInvalid(NSError(domain: "JSONErrorDomain", code: 1002, userInfo: newUserInfo))
            }
        }
    }
}

extension JSONValue: CustomStringConvertible {
    public var description: String {
        switch self {
        case .jInvalid(let error):
            return error.localizedDescription
        default:
            return _printableString("")
        }
    }
    
    var rawJSONString: String {
        switch self {
        case .jNumber(let value):
            return "\(value)"
        case .jBool(let value):
            return "\(value)"
        case .jString(let value):
            let jsonAbleString = value.replacingOccurrences(of: "\"", with: "\\\"", options: NSString.CompareOptions.caseInsensitive, range: nil)
            return "\"\(jsonAbleString)\""
        case .jNull:
            return "null"
        case .jArray(let array):
            var arrayString = ""
            for (index, value) in array.enumerated() {
                if index != array.count - 1 {
                    arrayString += "\(value.rawJSONString),"
                }else{
                    arrayString += "\(value.rawJSONString)"
                }
            }
            return "[\(arrayString)]"
        case .jObject(let object):
            var objectString = ""
            var (index, count) = (0, object.count)
            for (key, value) in object {
                if index != count - 1 {
                    objectString += "\"\(key)\":\(value.rawJSONString),"
                } else {
                    objectString += "\"\(key)\":\(value.rawJSONString)"
                }
                index += 1
            }
            return "{\(objectString)}"
        case .jInvalid:
            return "INVALID_JSON_VALUE"
            }
  }
    
    func _printableString(_ indent: String) -> String {
        switch self {
        case .jObject(let object):
            var objectString = "{\n"
            var index = 0
            for (key, value) in object {
                let valueString = value._printableString(indent + "  ")
                if index != object.count - 1 {
                    objectString += "\(indent)  \"\(key)\":\(valueString),\n"
                } else {
                    objectString += "\(indent)  \"\(key)\":\(valueString)\n"
                }
                index += 1
            }
            objectString += "\(indent)}"
            return objectString
        case .jArray(let array):
            var arrayString = "[\n"
            for (index, value) in array.enumerated() {
                let valueString = value._printableString(indent + "  ")
                if index != array.count - 1 {
                    arrayString += "\(indent)  \(valueString),\n"
                }else{
                    arrayString += "\(indent)  \(valueString)\n"
                }
            }
            arrayString += "\(indent)]"
            return arrayString
        default:
            return rawJSONString
        }
    }
}

extension JSONValue {
    public var boolValue: Bool {
        switch self {
        case .jInvalid:
            return false
        default:
            return true
        }
    }
}

extension JSONValue : Equatable {
    
}

public func ==(lhs: JSONValue, rhs: JSONValue) -> Bool {
    switch lhs {
    case .jNumber(let lvalue):
        switch rhs {
        case .jNumber(let rvalue):
            return rvalue == lvalue
        default:
            return false
        }
    case .jString(let lvalue):
        switch rhs {
        case .jString(let rvalue):
            return rvalue == lvalue
        default:
            return false
        }
    case .jBool(let lvalue):
        switch rhs {
        case .jBool(let rvalue):
            return rvalue == lvalue
        default:
            return false
        }
    case .jNull:
        switch rhs {
        case .jNull:
            return true
        default:
            return false
        }
    case .jArray(let lvalue):
        switch rhs {
        case .jArray(let rvalue):
            return rvalue == lvalue
        default:
            return false
        }
    case .jObject(let lvalue):
        switch rhs {
        case .jObject(let rvalue):
            return rvalue == lvalue
        default:
            return false
        }
    default:
        return false
    }
}
