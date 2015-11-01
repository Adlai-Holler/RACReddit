//
//  Utilities.swift
//  RACReddit
//
//  Created by Adlai Holler on 10/31/15.
//  Copyright © 2015 adlai. All rights reserved.
//

import UIKit

extension String {
	
	/**
	Returns self, formatted as a subreddit name:
	
	r/woahdude -> /r/woahdude
	/r/woahdude -> /r/woahdude
	woahdude -> /r/woahdude
	"woah dude" -> nil
	*/
	var subredditName: String? {
		if hasPrefix("/r/") {
			return self
		} else if hasPrefix("r/") {
			return "/" + self
		} else if rangeOfCharacterFromSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()) != nil {
			return nil
		} else {
			return "/r/" + self
		}
	}
}