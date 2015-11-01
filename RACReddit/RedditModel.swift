
import SwiftyJSON

struct RedditPost {
	var id: String
	var title: String
	var url: NSURL
	
	/** Attempt to parse the provided JSON into a RedditPost.
	* NOTE: This is actually quite expensive due to Swift casts being slow
	* so in production, cache these by ID.
	*/
	init?(json: JSON) {
		
		let data = json["data"]
		
		guard let title = data["title"].string,
			url = data["url"].string.flatMap({ NSURL(string: $0) }),
			id = data["id"].string else {
				NSLog("Failed to parse JSON into Reddit post: \(json)")
				return nil
		}
		
		self.title = title
		self.url = url
		self.id = id
	}

}
