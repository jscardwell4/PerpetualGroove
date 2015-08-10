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

      if let entityName = entity.name {
        description += entityName
        if let superentity = entity.superentity, superentityName = superentity.name  {
          description += " (\(superentityName))"
        }
        description += " {\n"
        if let userInfo = entity.userInfo where !userInfo.isEmpty {
          description += "\tuserInfo: {\n\(formattedDescription(userInfo, indent: 2))\n\t}"
        }

        var properties = entity.properties as [NSPropertyDescription]
        if let superEntityProperties = (entity.superentity?.properties)?.map({$0.name}) {
          properties = properties.filter({superEntityProperties ∌ $0.name})
        }

        for property in properties {

          var propertyNametagAttributes: [String] = []

          var propertyDescription: OrderedDictionary<String, String> = [:]
          if !property.optional { propertyNametagAttributes.append("required") }
          if property.transient { propertyNametagAttributes.append("transient") }
          if !property.validationPredicates.isEmpty {
            propertyDescription["validation"] = "'" + ", ".join(property.validationPredicates) + "'"
          }
          if property.storedInExternalRecord { propertyNametagAttributes.append("external") }

          if let userInfo = property.userInfo where !userInfo.isEmpty {
            propertyDescription["userInfo"] = formattedDescription(userInfo, indent: 2)
          }

          if let attributeDescription = property as? NSAttributeDescription {
            let attributeTypeString = NSStringFromNSAttributeType(attributeDescription.attributeType)
            var typeDescription = attributeTypeString[2..<attributeTypeString.length - 13].lowercaseString
            if let attributeClassName = attributeDescription.attributeValueClassName { typeDescription += ",\(attributeClassName)" }
            if let defaultValue: AnyObject = attributeDescription.defaultValue { typeDescription += " (\(defaultValue))" }
            propertyNametagAttributes.append(typeDescription)
            if attributeDescription.allowsExternalBinaryDataStorage { propertyNametagAttributes.append("externalBinary") }
          } else if let relationshipDescription = property as? NSRelationshipDescription {
            propertyDescription["destination"] = relationshipDescription.destinationEntity?.name
            propertyDescription["inverse"]     = relationshipDescription.inverseRelationship?.name
            let deleteRuleString = NSStringFromNSDeleteRule(relationshipDescription.deleteRule)
            propertyDescription["delete rule"] = deleteRuleString[2..<deleteRuleString.length - 10].lowercaseString
            propertyDescription["min/max"]   = "\(relationshipDescription.minCount)/\(relationshipDescription.maxCount)"
            if relationshipDescription.toMany { propertyNametagAttributes.append("toMany") }
            if relationshipDescription.ordered { propertyNametagAttributes.append("ordered") }
          }

          description += "\t\(property.name)"
          if !propertyNametagAttributes.isEmpty { description += " (" + ",".join(propertyNametagAttributes) + ")" }
          if !propertyDescription.isEmpty {
            description += " {\n\(formattedDescription(propertyDescription.dictionary, indent: 2))\n\t}"
          }
          description += "\n"
        }

        description += "}\n\n"
      }
    }

    return description

  }

}
