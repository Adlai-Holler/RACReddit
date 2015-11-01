//
//  RedditFetching.swift
//  RACReddit
//
//  Created by Adlai Holler on 10/31/15.
//  Copyright © 2015 adlai. All rights reserved.
//

import UIKit
import ReactiveCocoa
import SwiftyJSON
import Result

// MARK: - Error Info

/**
Note we use old-school error domains, codes, and user info dicts.
It's popular and tempting to use fancy Swift enums for errors but
Cocoa is built around NSError and let's not fight the system.
*/

let RedditErrorDomain = "RedditErrorDomain"

enum RedditError: Int {
	
	/// Check the NSUnderlyingErrorKey
	case NetworkingError
	
	case InvalidSubredditName
	case NonSuccessfulStatusCode
	case InternalError
}

enum RedditUserInfoKey: String {
	case StatusCode
}

extension RedditPost {
	
	/**
	Attempt to fetch the first page of posts on the given subreddit.
	If successful, sends an array of RedditPosts on an arbitrary queue.
	If failed, sends an error in the RedditErrorDomain.
	*/
	@warn_unused_result(message="Did you forget to call start?")
	static func fetchPostsForSubredditName(name: String) -> SignalProducer<[RedditPost], NSError> {
		
		// Attempt to form an NSURL using the given subreddit name.
		guard let formattedName = name.subredditName,
			url = NSURL(string: "https://reddit.com" + formattedName + ".json") else {
				
				// If the string is not a subreddit name, return a signal producer that will send that error.
				let invalidName = NSError(domain: RedditErrorDomain, code: RedditError.InvalidSubredditName.rawValue, userInfo: nil)
				return SignalProducer(error: invalidName)
		}
		
		NSLog("Requesting posts for url: \(url)")
		return NSURLSession.sharedSession()
			// ReactiveCocoa provides this method for getting URL data in a signal producer.
			.rac_dataWithRequest(NSURLRequest(URL: url))
			
			// Inject side effects for showing/hiding the network activity indicator.
			// Note that order matters – we want the network activity indicator to update
			// completely separate from our parsing process, so we add it now and not after.
			.attachToNetworkActivityIndicator()
			
			// If there was an error from NSURLSession, wrap that error into our error domain.
			.mapError { cocoaError in
				NSError(domain: RedditErrorDomain, code: RedditError.NetworkingError.rawValue, userInfo: [NSUnderlyingErrorKey: cocoaError])
			}
			
			// Attempt to convert the response into a successful HTTP response.
			.attemptMap(RedditFetching.checkReponseClassAndStatusCode)
			
			// Attempt to convert the data into an array of RedditPosts.
			.attemptMap { data, _ -> Result<[RedditPost], NSError> in
				let json = JSON(data: data)
				
				guard let posts = json["data"]["children"].array?.flatMap({ RedditPost(json: $0) }) else {
					return Result(error: NSError(domain: RedditErrorDomain, code: RedditError.InternalError.rawValue, userInfo: nil))
				}
				
				return Result(value: posts)
		}
	}
}

/// Custom signal operators used in this fetching API.
private extension SignalProducerType {
	
	/*
	Injects side effects into the signal producer.
	When the returned producer is started, the network activity count will be incremented.
	When it is terminated, the network activity count will be decremented.
	*/
	func attachToNetworkActivityIndicator() -> SignalProducer<Value, Error> {
		return on(started: {
				let oldValue = RedditFetching.networkActivityCount.modify { $0 + 1 }
				if oldValue == 0 {
					RedditFetching.handleNetworkActivityBecameZero(false)
				}
			}, terminated: {
				let oldValue = RedditFetching.networkActivityCount.modify { $0 - 1 }
				if oldValue == 1 {
					RedditFetching.handleNetworkActivityBecameZero(true)
				}
		})
	}
	
}

/// A container for our common Reddit API handling code.
private struct RedditFetching {
	
	/// How many active NSURLSession requests do we have going?
	static let networkActivityCount = Atomic(0)
	
	/// Update the network activity spinner visibility.
	static func handleNetworkActivityBecameZero(isZero: Bool) {
		NSOperationQueue.mainQueue().addOperationWithBlock {
			UIApplication.sharedApplication().networkActivityIndicatorVisible = !isZero
		}
	}
	
	/*
	* Ensure that the response is an HTTP response with a successful status code.
	* If so, returns the provided data and successful HTTP response.
	* Otherwise returns an error in the RedditErrorDomain.
	*/
	static func checkReponseClassAndStatusCode(data: NSData, response: NSURLResponse) -> Result<(NSData, NSHTTPURLResponse), NSError> {
		
		// Check that our resonse was an HTTP response (it always should be).
		guard let httpResponse = response as? NSHTTPURLResponse else {
			
			// If we got a non-HTTP response then something has gone terribly wrong.
			// Use an assertion failure to crash when debugging.
			assertionFailure("Expected URL response to be an HTTP response: \(response)")
			
			return Result(error: NSError(domain: RedditErrorDomain, code: RedditError.InternalError.rawValue, userInfo: nil))
		}
		
		// Check that the server processed our request.
		guard httpResponse.statusCode == 200 else {
			return Result(error: NSError(domain: RedditErrorDomain, code: RedditError.NonSuccessfulStatusCode.rawValue, userInfo: [RedditUserInfoKey.StatusCode.rawValue: httpResponse.statusCode]))
		}
		
		return Result(value: (data, httpResponse))
	}
	
}