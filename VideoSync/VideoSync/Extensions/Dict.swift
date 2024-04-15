//
//  Dict.swift
//  VideoSync
//
//  Created by ton252 on 15.04.2024.
//

import Foundation

func decodedData<T: Decodable>(type: T.Type, data: [String: Any]?) -> T? {
    guard let data = data else { return nil }
    guard let jsonData = try? JSONSerialization.data(withJSONObject: data, options: []) else { return nil }
    return try? JSONDecoder().decode(type, from: jsonData)
}

func encodedData<T: Encodable>(data: T?) -> [String: Any]? {
    guard let data = data else { return nil }
    guard let jsonData = try? JSONEncoder().encode(data) else { return nil }
    return try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any]
}
