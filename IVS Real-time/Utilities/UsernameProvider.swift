//
//  UsernameProvider.swift
//  IVS Real-time
//
//  Created by Uldis Zingis on 28/03/2023.
//

import Foundation

struct UsernameProvider {
    private static func getFruitsFromJson() -> [String]? {
        if let path = Bundle.main.path(forResource: "fruits", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
                if let jsonResult = jsonResult as? Dictionary<String, AnyObject>,
                   let fruits = jsonResult["fruits"] as? [String] {
                    return fruits
                } else {
                    print("❌ Could not parse fruits.json")
                }
            } catch {
                print("❌ Could not load fruits from json: \(error)")
            }
        }

        return nil
    }

    static func getRandomUsername() -> String {
        if let fruits = getFruitsFromJson() {
            let fruit1 = fruits.randomElement() ?? ""
            let fruit2 = fruits.randomElement() ?? ""
            let number = Int.random(in: 1...9)

            return "\(fruit1.capitalized)\(fruit2.capitalized)\(number)"
        }

        return "Username1"
    }
}
