//
//  SubredditEntriesViewController.swift
//  RACReddit
//
//  Created by Adlai Holler on 10/31/15.
//  Copyright © 2015 adlai. All rights reserved.
//

import UIKit
import SafariServices
import ReactiveCocoa

final class SubredditEntriesViewController: UITableViewController, UITextFieldDelegate {

	var data: [RedditPost] = []
	var currentSubredditName: String?
	var currentFetchDisposable: Disposable?

	@IBOutlet weak var titleTextField: UITextField!
	
	deinit {
		currentFetchDisposable?.dispose()
	}
	
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
		// Make sure we have a current subreddit name
		guard let currentSubredditName = currentSubredditName else { return }
		
		// Dispose of our current fetch if needed.
		currentFetchDisposable?.dispose()
		
		RedditPost
			// Create a signal producer.
			.fetchPostsForSubredditName(currentSubredditName)
			
			// Switch events onto UI scheduler (main thread).
			.observeOn(UIScheduler())
			
			// Start the signal producer – produce a signal and listen to its events.
			.start {[weak self] event in
				self?.handleFetchEventForSubredditName(currentSubredditName, event: event)
		}
	}
	
	/// We will call this on the main thread for any fetch event that comes through
	private func handleFetchEventForSubredditName(name: String, event: Event<[RedditPost], NSError>) {
		switch event {
		case let .Next(posts):
			NSLog("View controller received posts: \(posts)")
			data = posts
			tableView.reloadData()
		case let .Failed(error):
			NSLog("Failed to fetch posts for subreddit: \(name) with error: \(error)")
		default: ()
		}
	}
}
