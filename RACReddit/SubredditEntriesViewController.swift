//
//  SubredditEntriesViewController.swift
//  RACReddit
//
//  Created by Adlai Holler on 10/31/15.
//  Copyright © 2015 adlai. All rights reserved.
//

import UIKit
import SafariServices

final class SubredditEntriesViewController: UITableViewController, UITextFieldDelegate {

	var data: [RedditPost] = []
	var currentSubredditName: String?

	@IBOutlet weak var titleTextField: UITextField!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		titleTextField.becomeFirstResponder()
	}
	
    // MARK: - Table view data source

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cellID", forIndexPath: indexPath)
		cell.textLabel?.text = data[indexPath.item].title
        return cell
    }

    // MARK: - Navigation

	/// When they select a post, create a Safari view controller and push it.
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		let url = data[indexPath.row].url
		let vc = SFSafariViewController(URL: url)
		showViewController(vc, sender: self)
	}

	// MARK: - Handling the Text Field
	
	/// If they tap the return key, dismiss the field.
	func textFieldShouldReturn(textField: UITextField) -> Bool {
		textField.endEditing(false)
		return true
	}
	
	/// When they finish editing, if our subreddit name has changed, do a load.
	func textFieldDidEndEditing(textField: UITextField) {
		if textField.text != currentSubredditName {
			currentSubredditName = textField.text
			loadNewData()
		}
	}
	
	/// Cancel any existing load and load the data for the current subreddit name.
	private func loadNewData() {
		// Can't load data if we don't have a subreddit name.
		guard let currentSubredditName = currentSubredditName
			where !currentSubredditName.isEmpty else { return }
		
		let alert = UIAlertController(title: "Can't load data", message: "No data loading implementation", preferredStyle: .Alert)
		alert.addAction(UIAlertAction(title: "OK", style: .Cancel, handler: nil))
		presentViewController(alert, animated: true, completion: nil)
	}
	
}
