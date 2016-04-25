//
//  HammockLocation.swift
//  Whereno
//
//  Created by Kyle Bashour on 4/24/16.
//  Copyright © 2016 Kyle Bashour. All rights reserved.
//

import Foundation
import RealmSwift
import Mapper

final class HammockLocation: Object, Mappable {

    dynamic var id = 0
    dynamic var title = ""
    dynamic var descriptionText = ""
    dynamic var imageURLString = ""
    dynamic var latitude = 0.0
    dynamic var longitude = 0.0

    let comments = List<LocationComment>()

    required convenience init(map: Mapper) throws {
        self.init()

        try id = map.from("id")
        try title = map.from("title")
        try imageURLString = map.from("image_url")
        try descriptionText = map.from("description")
        try latitude = map.from("latitude")
        try longitude = map.from("longitude")

        let comments: [LocationComment] = (try? map.from("comments")) ?? []

        self.comments.appendContentsOf(comments)
    }

    override static func primaryKey() -> String? {
        return "id"
    }

    var imageURL: NSURL {
        return NSURL(string: imageURLString)!
    }
}

extension HammockLocation: JSONEncodable {

    func toJSON() -> [String : AnyObject] {
        return [
            "id": id,
            "title": title,
            "image_url": imageURLString,
            "description": descriptionText,
            "latitude": latitude,
            "longitude": longitude,
        ]
    }
}
