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


    // MARK: Realm properties

    dynamic var id = ""
    dynamic var title = ""
    dynamic var descriptionText = ""
    dynamic var imageURLString = ""
    dynamic var ownerID = ""
    dynamic var date = NSDate()
    dynamic var capacity = 0
    dynamic var latitude = 0.0
    dynamic var longitude = 0.0
    let comments = List<LocationComment>()


    // MARK: Computed properties

    var imageURL: NSURL {
        return NSURL(string: imageURLString)!
    }

    // Mapper initializer
    required convenience init(map: Mapper) throws {
        self.init()

        try id = map.from("id")
        try title = map.from("title")
        try imageURLString = map.from("photo")
        try descriptionText = map.from("description")
        try latitude = map.from("latitude")
        try longitude = map.from("longitude")
        try ownerID = map.from("user_id")
        try date = map.from("date_created")
        try capacity = map.from("capacity")

        let comments: [LocationComment] = (try? map.from("comments")) ?? []
        self.comments.appendContentsOf(comments)
    }

    override static func primaryKey() -> String? {
        return "id"
    }
}
