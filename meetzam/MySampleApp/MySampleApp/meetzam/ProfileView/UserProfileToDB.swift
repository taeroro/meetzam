//
//  UserProfileToDB.swift
//  MySampleApp
//
//  Created by Rainy on 2017/2/26.
//
//
import AWSDynamoDB
//
//  UserProfile.swift
//  MySampleApp
//
//
// Copyright 2017 Amazon.com, Inc. or its affiliates (Amazon). All Rights Reserved.
//
// Code generated by AWS Mobile Hub. Amazon gives unlimited permission to
// copy, distribute and modify it.
//
// Source code generated from template: aws-my-sample-app-ios-swift v0.10
//
import Foundation
import UIKit
import AWSDynamoDB
class UserProfileToDB: AWSDynamoDBObjectModel, AWSDynamoDBModeling {
    
    var userId: String?
    var displayName: String?
    var bio: String?
    var age: String?
    var gender: String?
    var region: String?
    var email: String?
    
    class func dynamoDBTableName() -> String {
        
        return "meetzam-mobilehub-1569925313-UserProfile"
    }
    
    class func hashKeyAttribute() -> String {
        
        return "userId"
    }
    
    /*class func rangeKeyAttribute() -> String {
     
     return "email"
     }*/
    
    /*override class func jsonKeyPathsByPropertyKey() -> [AnyHashable: Any] {
     return [
     "_userId" : "userId",
     "_phone" : "phone",
     "_name" : "name",
     "_pushTargetArn" : "pushTargetArn",
     ]
     }*/
    
    // function to add/update user info into database
    // argument: dbName...
    func insertProfile(_userId: String, _displayName: String, _bio: String, _age: String, _gender: String, _region: String, _email: String) {
        print("insertSomeItems()")
        let mapper = AWSDynamoDBObjectMapper.default()
        
        var userProfile = UserProfileToDB()
        userProfile?.userId  = _userId
        userProfile?.displayName = _displayName
        userProfile?.bio = _bio
        userProfile?.age = _age
        userProfile?.gender = _gender
        userProfile?.region = _region
        userProfile?.email = _email
        let profile = mapper.save(userProfile!)
        
        /*mapper.save(userProfile!).continueWith(block: { (task:AWSTask<AnyObject>!) -> Any? in
         if let error = task.error as? NSError {
         print("The request failed. Error: \(error)")
         } else {
         // Do something with task.result or perform other operations.
         }
         })*/
        
        
        //return BFTask(forCompletionOfAllTasks: [task1, task2, task3])
    }
    
    func getProfileForEdit(key: String, user_profile: UserProfileToDB?, displayname: UITextField!, bio: UITextField!, age: UITextField!, gender: UITextField!, region: UITextField!, email: UITextField!){
        /*let mapper = AWSDynamoDBObjectMapper.default()
         return mapper.load(UserProfileToDB.self, hashKey: key, rangeKey: email)*/
        let mapper = AWSDynamoDBObjectMapper.default()
        
        //tableRow?.UserId --> (tableRow?.UserId)!
        mapper.load(UserProfileToDB.self, hashKey: key, rangeKey: nil) .continueWith(executor: AWSExecutor.mainThread(), block: { (task:AWSTask!) -> AnyObject! in
            if let error = task.error as? NSError {
                print("Error: \(error)")
            } else if let user_profile = task.result as? UserProfileToDB {
                displayname.text = user_profile.displayName
                print(displayname.text)
                bio.text = user_profile.bio
                print(bio.text)
                age.text = user_profile.age
                print(age.text)
                gender.text = user_profile.gender
                print(gender.text)
                region.text = user_profile.region
                print(region.text)
                email.text = user_profile.email
                print(email.text)
            }
            
            return nil
        })
        
    }
    
    func getProfileForDisplay(key: String, user_profile: UserProfileToDB?, displayname: UILabel!, bio: UILabel!){
        print("     enter func getProfileForDisplay")
        /*let mapper = AWSDynamoDBObjectMapper.default()
         return mapper.load(UserProfileToDB.self, hashKey: key, rangeKey: email)*/
        let mapper = AWSDynamoDBObjectMapper.default()
        
        print("userId is ", user_profile?.userId, separator: " ")
        //tableRow?.UserId --> (tableRow?.UserId)!
        mapper.load(UserProfileToDB.self, hashKey: key, rangeKey: nil) .continueWith(executor: AWSExecutor.mainThread(), block: { (task:AWSTask!) -> AnyObject! in
            if let error = task.error as? NSError {
                print("Error: \(error)")
            } else if let user_profile = task.result as? UserProfileToDB {
                print("     Getting fields in user_profile")
                displayname.text = user_profile.displayName
                print(displayname.text)
                bio.text = user_profile.bio
                print(bio.text)
            }
            
            return nil
        })
        
    }
    
}