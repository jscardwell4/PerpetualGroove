//
//  NSManagedObjectModel+MoonKitAdditions.swift
//  MoonKit
//
//  Created by Jason Cardwell on 12/20/14.
//  Copyright (c) 2014 Moondeer Studios. All rights reserved.
//

import Foundation
import CoreData

extension NSManagedObjectModel {

  public override var description: String {
    var description = ""
    apply(entities as [NSEntityDescription]) {
      entity in

      description += "\(entity.name) {\n"
      if let userInfo = entity.userInfo { description += "\tuserInfo: {\n\(formattedDescription(userInfo, indent: 2))\n\t}" }

      for property in entity {

        var propertyDescription: OrderedDictionary<String, String> = [:]
        propertyDescription["optional"]                  = "\(property.optional)"
        propertyDescription["transient"]                 = "\(property.transient)"
        propertyDescription["validation predicates"]     = "'" + ", ".join(property.validationPredicates) + "'"
        propertyDescription["stored in external record"] = "\(property.storedInExternalRecord)"
        if let userInfo = property.userInfo { propertyDescription["userInfo"] = formattedDescription(userInfo, indent: 2) }

        if let attributeDescription = property as? NSAttributeDescription {
          propertyDescription["attribute value class name"]        = NSAttributeTypeString(attributeDescription.attributeType)
          propertyDescription["default value"]                     = "\(attributeDescription.defaultValue ?? nil)"
          propertyDescription["allows extern binary data storage"] = "\(attributeDescription.allowsExternalBinaryDataStorage)"
        } else if let relationshipDescription = property as? NSRelationshipDescription {
          propertyDescription["destination"] = relationshipDescription.destinationEntity.name
          propertyDescription["inverse"]     = relationshipDescription.inverseRelationship.name
          propertyDescription["delete rule"] = NSDeleteRuleString(relationshipDescription.deleteRule)
          propertyDescription["max count"]   = "\(relationshipDescription.maxCount)"
          propertyDescription["min count"]   = "\(relationshipDescription.minCount)"
          propertyDescription["one-to-many"] = "\(relationshipDescription.isToMany)"
          propertyDescription["ordered"]     = "\(relationshipDescription.isOrdered)"
        }

        description += "\t\(property.name) {\n\(formattedDescription(propertyDescription.dictionary, indent: 2)\n\t}\n)"
      }

      description += "}\n\n"

    }

    return description

  }

}
